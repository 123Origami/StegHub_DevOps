/* # This assumes you have a domain - replace with your actual domain
resource "aws_acm_certificate" "cert" {
  domain_name       = "*.yourdomain.com"
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name = "wildcard-cert"
  })
}

# Get your hosted zone
data "aws_route53_zone" "zone" {
  name         = "yourdomain.com"
  private_zone = false
}

# DNS validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
} */