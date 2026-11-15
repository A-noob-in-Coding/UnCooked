# Phase 02 - HA + CD

One ALB in front of an app ASG (2 boxes). Separate data EC2 for Mongo, Redis, RabbitMQ.

| Tool | What it does |
|------|----------------|
| Terraform | VPC, ALB, ASG, data node, ECR, OIDC role, CloudWatch, remote state |
| Ansible | Install Docker / bring up data compose (or use the SSM PowerShell helper on Windows) |
| `cd.yml` | Push images to ECR, deploy over SSM, smoke test, rollback if smoke fails |

## Setup order

**1. State bucket (once)**

```bash
cd terraform/bootstrap
terraform init
terraform apply
cd ..
terraform init -migrate-state
```

**2. Main stack**

```bash
cd terraform
terraform plan
terraform apply
```

**3. GitHub Actions**

Put outputs into repo secrets/vars (`AWS_ROLE_ARN` is a secret; the rest are variables).  
See `docs/github-cd-vars.example.txt`. Confirm the SNS alarm email if you set one.

JWT for the backend lives in SSM (`/uncooked/app/jwt_private_key` + `jwt_public_key`), not in GitHub.

**4. Docker on the boxes + data services**

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File web\scripts\cd\ssm-bootstrap-hosts.ps1
```

Or with Ansible (WSL/Linux), after filling `ansible/inventory/hosts.yml` from the example:

```bash
cd ansible
ansible-playbook playbooks/bootstrap.yml
ansible-playbook playbooks/data.yml
```

**5. Deploy**

Push/merge to `main`, or run the `cd` workflow manually (`deploy` / `rollback`).

Screenshots checklist: `images/P1/README.md`.

## Network (brief)

- Public subnets (2 AZ): ALB + NAT  
- Private subnets (2 AZ): app ASG + data EC2  
- CIDRs and SGs: `docs/architecture.md`

## Cost note

Three `m7i-flex.large` instances + **NAT Gateway** add up fast. Set `budget_email` in `terraform.tfvars`. Tear down when you are not demoing:

```bash
cd terraform && terraform destroy
```

Leave `terraform/bootstrap` alone if you still want remote state.
