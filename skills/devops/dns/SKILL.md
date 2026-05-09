# skill: devops/dns
# triggers: dns, route53, cloudflare, domain, ssl, tls, certificate, https, subdomain, records

## DNS Record Types
```
A     → IPv4 address          example.com → 1.2.3.4
AAAA  → IPv6 address          example.com → 2001:db8::1
CNAME → alias to another name app.example.com → myapp.vercel.app
MX    → mail server           example.com → mail.google.com (priority 10)
TXT   → text data             SPF, DKIM, domain verification
NS    → nameservers           who controls the zone
CAA   → cert authority auth   allow only Let's Encrypt to issue certs
```

## Route53 (Terraform)
```hcl
resource "aws_route53_zone" "main" {
  name = "example.com"
}

# A record → ALB
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Wildcard for subdomains (SaaS multi-tenant)
resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "*.example.com"
  type    = "CNAME"
  ttl     = 300
  records = ["app.example.com"]
}
```

## ACM Certificate (AWS — auto-renews)
```hcl
resource "aws_acm_certificate" "cert" {
  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com", "www.example.com"]
  validation_method         = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
```

## Cloudflare (via CLI / Terraform)
```bash
# Common record management
export CF_TOKEN="your-api-token"
CF_ZONE=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=example.com" \
  -H "Authorization: Bearer $CF_TOKEN" | jq -r '.result[0].id')

# Add A record
curl -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"app","content":"1.2.3.4","ttl":1,"proxied":true}'
```

## SSL/TLS — Let's Encrypt (self-managed)
```bash
# Certbot with Route53 plugin
pip install certbot certbot-dns-route53

certbot certonly \
  --dns-route53 \
  --domain example.com \
  --domain "*.example.com" \
  --non-interactive \
  --agree-tos \
  --email admin@example.com

# Auto-renew (cron)
echo "0 12 * * * certbot renew --quiet" >> /etc/crontab
```

## Email DNS Records
```
SPF:   v=spf1 include:amazonses.com include:sendgrid.net ~all
DKIM:  Add TXT record from email provider (per selector)
DMARC: v=DMARC1; p=reject; rua=mailto:dmarc@example.com; adkim=s; aspf=s
CAA:   0 issue "amazon.com"   (restrict to ACM)
       0 issue "letsencrypt.org"
```

## TTL Strategy
```
Development / frequent changes: TTL = 60s (1 min)
Stable production records:      TTL = 3600s (1 hr)
Rarely changed (NS, SOA):       TTL = 86400s (1 day)

Before migration: lower TTL to 60s, wait 24h (old TTL), then switch
After migration:  raise TTL back to 3600s
```
