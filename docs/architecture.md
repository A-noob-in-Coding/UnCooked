# Architecture

```text
                    Internet
                       |
                       v
              ALB (public subnets
              ap-south-1a + 1b)
                       |
          +------------+------------+
          |                         |
          v                         v
   App ASG (private)         App ASG (private)
   ap-south-1a               ap-south-1b
   frontend:8080             frontend:8080
   backend + agent           backend + agent
          |                         |
          +------------+------------+
                       |
                       v
              Data EC2 (private 1a)
              Mongo / Redis / RabbitMQ
                       |
                       v
              NAT (public 1a) -> IGW -> Internet
              (ECR pull, SSM, apt)

GitHub Actions
  CI (push/PR): stages 02-10
  CD (main):   11 ECR push -> 12 deploy/smoke
               smoke fail -> auto rollback
  OIDC -> IAM role uncooked-github-actions
  Secrets: GitHub Secrets + SSM /uncooked/app/*

CloudWatch: ALB 5xx + unhealthy hosts -> SNS (optional email)
```

## Network

| Item | Value |
|------|--------|
| VPC | `10.20.0.0/16` |
| Public 1a / 1b | `10.20.0.0/24`, `10.20.1.0/24` |
| Private 1a / 1b | `10.20.10.0/24`, `10.20.11.0/24` |
| ALB SG | :80 from `0.0.0.0/0` |
| App SG | :8080 from ALB SG only; SSH closed |
| Data SG | :27017/:6379/:5672 from App SG only |

## Service discovery

Compose on each app box: `backend` talks to `agent` on the Docker network.  
`DATA_HOST` = data EC2 private IP (Terraform + SSM deploy).  
Users only hit ALB → frontend `:8080`.
