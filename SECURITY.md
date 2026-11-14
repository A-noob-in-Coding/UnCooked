# Security

## Scanners

| Stage | Tool | Fails when |
|-------|------|------------|
| 02 | Gitleaks | Secret in history |
| 07 | SonarCloud | Quality gate fails |
| 08 | Snyk | High/critical dep |
| 10 | Trivy | High/critical image (fixed only) |
| 11-12 | CD | Smoke fails (then rollback) |

Don't turn scanners off. If something stays, list it under accepted findings.

## Accepted

| Item | Severity | Why | Owner | Review |
|------|----------|-----|-------|--------|
| xlsx (removed) | High | Switched to exceljs | Group | 2026-12 |
| exceljs → uuid | Moderate | No clean fix yet; under Snyk high bar | Group | 2026-12 |
| Ansible `mode` / Dockerfile.dev | Sonar MEDIUM | Infra/dev-only; excluded from Sonar sources (not runtime images) | Group | 2026-11 |

## Secrets

CI: `SONAR_TOKEN`, `SNYK_TOKEN`

CD: no long-lived AWS keys. Use OIDC.

- Secret: `AWS_ROLE_ARN`
- Vars: `AWS_REGION`, `ALB_URL`, `ASG_NAME`, `DATA_HOST`, `ECR_REGISTRY`
- JWT PEM keys: SSM `/uncooked/app/jwt_private_key` + `jwt_public_key` (not GitHub)

## Branch protection

Protect `main`: require PR + the CI job names **02-10** (match the names Actions actually reports).
