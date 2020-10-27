# Allow ingress from Guacamole instance via ssh
# For: DevOps ssh access from Guacamole instance to Operations instance
resource "aws_security_group_rule" "operations_ingress_from_guacamole_via_ssh" {
  provider = aws.provisionassessment

  security_group_id = aws_security_group.operations.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.guacamole.private_ip}/32"]
  from_port         = 22
  to_port           = 22
}

# Allow ingress from Guacamole instance via VNC
# For: Assessment team VNC access from Guacamole instance to Operations instance
resource "aws_security_group_rule" "operations_ingress_from_guacamole_via_vnc" {
  provider = aws.provisionassessment

  security_group_id = aws_security_group.operations.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.guacamole.private_ip}/32"]
  from_port         = 5901
  to_port           = 5901
}

# Allow ingress from Kali instances to teamservers via port 993 (IMAP
# over TLS/SSL)
# For: Assessment team IMAP access on Teamservers from Kali instances
resource "aws_security_group_rule" "operations_ingress_from_kali_via_imaps" {
  count    = lookup(var.operations_instance_counts, "teamserver", 0) > 0 ? 1 : 0
  provider = aws.provisionassessment

  security_group_id = aws_security_group.operations.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = formatlist("%s/32", aws_instance.kali[*].private_ip)
  from_port         = 993
  to_port           = 993
}

# Allow ingress from Kali and Debian desktop instances via Nessus web GUI
# For: Assessment team Nessus web access from Kali and Debian desktop instances
resource "aws_security_group_rule" "operations_ingress_from_allowed_instances_for_nessus" {
  count    = lookup(var.operations_instance_counts, "nessus", 0) > 0 ? 1 : 0
  provider = aws.provisionassessment

  security_group_id = aws_security_group.operations.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = [for instance in concat(aws_instance.kali, aws_instance.debiandesktop) : format("%s/32", instance.private_ip)]
  from_port         = 8834
  to_port           = 8834
}

# Allow ingress from Kali instances to teamservers via port 50050
# (Cobalt Strike)
# For: Assessment team to access Cobalt Strike on Teamservers from
# Kali instances
resource "aws_security_group_rule" "operations_ingress_from_kali_via_cs" {
  count    = lookup(var.operations_instance_counts, "teamserver", 0) > 0 ? 1 : 0
  provider = aws.provisionassessment

  security_group_id = aws_security_group.operations.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = formatlist("%s/32", aws_instance.kali[*].private_ip)
  from_port         = 50050
  to_port           = 50050
}

# Allow ingress from anywhere via the TCP ports specified in
# var.operations_subnet_inbound_tcp_ports_allowed
# For: Assessment team operational use
resource "aws_security_group_rule" "operations_ingress_from_anywhere_via_allowed_tcp_ports" {
  provider = aws.provisionassessment
  for_each = local.operations_subnet_inbound_tcp_ports_allowed

  security_group_id = aws_security_group.operations.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = each.value["from"]
  to_port           = each.value["to"]
}

# Allow ingress from anywhere via the UDP ports specified in
# var.operations_subnet_inbound_udp_ports_allowed
# For: Assessment team operational use
resource "aws_security_group_rule" "operations_ingress_from_anywhere_via_allowed_udp_ports" {
  provider = aws.provisionassessment
  for_each = local.operations_subnet_inbound_udp_ports_allowed

  security_group_id = aws_security_group.operations.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = each.value["from"]
  to_port           = each.value["to"]
}

# Allow ingress from anywhere via ICMP
# For: Assessment team operational use (e.g. ping responses)
resource "aws_security_group_rule" "operations_ingress_from_anywhere_via_icmp" {
  provider = aws.provisionassessment

  security_group_id = aws_security_group.operations.id
  type              = "ingress"
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = -1
  to_port           = -1
}

# Allow egress to anywhere via any protocol and port
# For: Assessment team operational use
resource "aws_security_group_rule" "operations_egress_to_anywhere_via_any_port" {
  provider = aws.provisionassessment

  security_group_id = aws_security_group.operations.id
  type              = "egress"
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = -1
  to_port           = -1
}
