# Short findings report

## What we learned

Building UnCooked forced the DevOps loop end-to-end: protected `main`, a 12-stage DevSecOps pipeline, OIDC to AWS (no long-lived keys), immutable ECR tags, rolling SSM deploys with smoke + rollback, and HA behind an ALB across two AZs. Security scanners only help when they are required checks and findings are fixed or recorded in `SECURITY.md`.

## Main problems and fixes

| Problem | Fix |
|---------|-----|
| Sonar / Snyk / Trivy blocked merges | Fix real issues; document accepted mediums in `SECURITY.md`; never disable scanners |
| OIDC `sub` mismatch | Align IAM trust with GitHub repo owner/id form |
| ALB 502 after ASG replace | Self-heal `user_data` (Docker + ECR + compose from SSM tag) |
| Windows + Ansible friction | SSM scripts for bootstrap/deploy; Ansible kept as documented option |
| Public-only boxes vs brief | Moved app + data to private subnets with NAT; ALB stays public |

See also [`post-incident.md`](post-incident.md).

## Impact on understanding

Automation only sticks when recovery is automatic too. HA is not “two instances”; it is replace + bootstrap + health checks. Least-privilege IAM and SSM-only access remove SSH as a habit. Observability (CloudWatch alarms + ASG activity) turns demos into diagnosable incidents.

## Contribution table

| Name | Roll | Contributions |
|------|------|----------------|
| Muhammad Ahmad Butt | 23L-3059 | CI/CD workflows, Sonar/Snyk, Terraform HA, CD deploy/smoke/rollback, evidence |
| Ali Ahmed | 23L-3067 | AWS console ops, ECR/OIDC verification, load test & HA demos, screenshots |
| Muhammad Zain Tahir | 23L-3078 | App services (frontend/backend/agent), Compose, local run docs, reviews |
