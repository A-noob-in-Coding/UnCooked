# UnCooked

Exam-slot web app for FAST NUCES DevOps. Phase 01 is CI scanners; Phase 02 is AWS HA + CD.

## Live demo (Phase 02)

http://uncooked-alb-1680261338.ap-south-1.elb.amazonaws.com

## Phase 01 - CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml): Gitleaks, ESLint, Prettier, Hadolint, tests, SonarCloud, Snyk, Docker build, Trivy.

## Phase 02 - HA + CD

Details in [`docs/PHASE02.md`](docs/PHASE02.md).

- Terraform: VPC, ALB, ASG (2 app nodes), data EC2, ECR, GitHub OIDC, CloudWatch  
- Ansible (WSL): Docker + compose on the boxes  
- [`cd.yml`](.github/workflows/cd.yml): push images, deploy, smoke, rollback  

```text
Internet → ALB → App ASG (frontend / backend / agent)
                      ↓
                Data EC2 (Mongo, Redis, RabbitMQ)
```

## Local app

```bash
cd web
docker compose up
```

| Part | Folder |
|------|--------|
| Frontend | `web/frontend` |
| Backend | `web/backend` |
| Agent | `web/agent` |

## Group

| Name | Roll |
|------|------|
| Muhammad Ahmad Butt | 23L-3059 |
| Ali Ahmed | 23L-3067 |
| Muhammad Zain Tahir | 23L-3078 |
