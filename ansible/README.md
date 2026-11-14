# Ansible

Run from **WSL** (not Windows PowerShell). Terraform creates the VMs; these playbooks install Docker and start compose.

| Playbook | Does |
|----------|------|
| `playbooks/bootstrap.yml` | Docker on data + app |
| `playbooks/data.yml` | Mongo / Redis / Rabbit |
| `playbooks/app.yml` | Pull from ECR and run app compose |

## One-time WSL setup

```bash
sudo apt-get update
sudo apt-get install -y python3-pip unzip
pip3 install --user ansible boto3 botocore
# AWS CLI v2 + Session Manager plugin (for aws_ssm)
curl -fsSLo /tmp/awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install --update
curl -fsSLo /tmp/ssm.deb https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb
sudo dpkg -i /tmp/ssm.deb
```

Copy Windows AWS creds if needed: `cp -r /mnt/c/Users/$USER/.aws ~/.aws`

## Inventory

```bash
# from repo root (WSL path)
bash web/scripts/cd/gen-ansible-inventory.sh
# or: cp ansible/inventory/hosts.example.yml ansible/inventory/hosts.yml
# then put live instance IDs in hosts.yml
```

`hosts.yml` is gitignored.

## Run

```bash
cd ansible
ansible-playbook playbooks/bootstrap.yml
ansible-playbook playbooks/data.yml
ansible-playbook playbooks/app.yml \
  -e data_host=10.20.0.107 \
  -e ecr_registry=062301636277.dkr.ecr.ap-south-1.amazonaws.com \
  -e image_tag=manual-202611142157
```

Helper: `bash ansible/run.sh playbooks/bootstrap.yml`
