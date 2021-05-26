# The GoPhish AMI
data "aws_ami" "gophish" {
  provider = aws.provisionassessment

  filter {
    name = "name"
    values = [
      "pca-gophish-hvm-*-x86_64-ebs"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners      = [local.images_account_id]
  most_recent = true
}

# The GoPhish EC2 instances
resource "aws_instance" "gophish" {
  count = lookup(var.operations_instance_counts, "gophish", 0)
  # These instances require the EBS Docker volume and EFS mount target to be
  # present so that both volumes can be mounted at boot time.
  depends_on = [
    aws_ebs_volume.gophish_docker,
    aws_efs_mount_target.target
  ]
  provider = aws.provisionassessment

  ami                         = data.aws_ami.gophish.id
  associate_public_ip_address = true
  availability_zone           = "${var.aws_region}${var.aws_availability_zone}"
  iam_instance_profile        = aws_iam_instance_profile.gophish.name
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.operations.id
  # AWS Instance Meta-Data Service (IMDS) options
  metadata_options {
    # Enable IMDS (this is the default value)
    http_endpoint = "enabled"
    # Restrict put responses from IMDS to a single hop (this is the
    # default value).  This effectively disallows the retrieval of an
    # IMDSv2 token via this machine from anywhere else.
    http_put_response_hop_limit = 1
    # Require IMDS tokens AKA require the use of IMDSv2
    http_tokens = "required"
  }
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 128
    delete_on_termination = true
  }
  user_data_base64 = data.cloudinit_config.gophish_cloud_init_tasks[count.index].rendered
  vpc_security_group_ids = [
    aws_security_group.cloudwatch_and_ssm_agent.id,
    aws_security_group.efs_client.id,
    aws_security_group.gophish.id,
    aws_security_group.guacamole_accessible.id,
    aws_security_group.scanner.id,
  ]
  tags        = merge(var.tags, map("Name", format("GoPhish%d", count.index)))
  volume_tags = merge(var.tags, map("Name", format("GoPhish%d", count.index)))
}

# The Elastic IP for each GoPhish instance
resource "aws_eip" "gophish" {
  count    = lookup(var.operations_instance_counts, "gophish", 0)
  provider = aws.provisionassessment

  vpc = true
  tags = merge(
    var.tags,
    {
      "Name"           = format("GoPhish%d EIP", count.index)
      "Publish Egress" = "True"
    },
  )
}

# The EIP association for each GoPhish instance
resource "aws_eip_association" "gophish" {
  count    = lookup(var.operations_instance_counts, "gophish", 0)
  provider = aws.provisionassessment

  instance_id   = aws_instance.gophish[count.index].id
  allocation_id = aws_eip.gophish[count.index].id
}

# The EBS volume for each GoPhish instance; it is used to persist Docker volume
# data across instance restarts and redeployments.  Note that Docker data
# cannot be stored on the existing EFS volume because EFS is not supported
# as a backing file system for Docker:
# https://docs.docker.com/storage/storagedriver/select-storage-driver/#supported-backing-filesystems
resource "aws_ebs_volume" "gophish_docker" {
  count    = lookup(var.operations_instance_counts, "gophish", 0)
  provider = aws.provisionassessment

  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  encrypted         = true
  size              = 16
  type              = "gp2"

  tags = merge(var.tags, map("Name", format("GoPhish%d Docker", count.index)))
}

# Attach EBS volume to GoPhish instance
resource "aws_volume_attachment" "gophish_docker" {
  count    = lookup(var.operations_instance_counts, "gophish", 0)
  provider = aws.provisionassessment

  device_name = local.docker_ebs_device_name
  instance_id = aws_instance.gophish[count.index].id
  volume_id   = aws_ebs_volume.gophish_docker[count.index].id
}
