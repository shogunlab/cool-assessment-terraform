# Private DNS A record for Commando instances
resource "aws_route53_record" "commando_A" {
  count    = lookup(var.operations_instance_counts, "commando", 0)
  provider = aws.provisionassessment

  zone_id = aws_route53_zone.assessment_private.zone_id
  name    = "commando${count.index}.${aws_route53_zone.assessment_private.name}"
  type    = "A"
  ttl     = var.dns_ttl
  records = [aws_instance.commando[count.index].private_ip]
}
