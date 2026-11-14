# Windows helper: install Docker over SSM, then start data compose.
# Skip this if you already use Ansible.
$ErrorActionPreference = "Continue"
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "ap-south-1" }
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$ComposeData = Join-Path $Root "web\docker-compose.data.yml"
$Inventory = Join-Path $Root "ansible\inventory\hosts.yml"

function Get-HostIds([string]$group) {
  $ids = @()
  $inGroup = $false
  Get-Content $Inventory | ForEach-Object {
    if ($_ -match "^\s{4}$group`:") { $inGroup = $true; return }
    if ($inGroup -and $_ -match "^\s{4}\w+:") { $inGroup = $false }
    if ($inGroup -and $_ -match "ansible_host:\s*(\S+)") { $ids += $Matches[1] }
  }
  return $ids
}

function Wait-Ssm([string]$CmdId, [string[]]$InstanceIds) {
  foreach ($id in $InstanceIds) {
    Write-Host "Waiting on $id ..."
    $null = aws ssm wait command-executed --command-id $CmdId --instance-id $id --region $Region 2>&1
    $status = aws ssm get-command-invocation --command-id $CmdId --instance-id $id --region $Region --query Status --output text
    Write-Host "  $id => $status"
    if ($status -ne "Success") {
      aws ssm get-command-invocation --command-id $CmdId --instance-id $id --region $Region --query StandardErrorContent --output text
      throw "SSM failed on $id"
    }
  }
}

$dockerScript = @'
set -euo pipefail
if command -v docker >/dev/null 2>&1; then docker --version; exit 0; fi
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg unzip
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker
cd /tmp
curl -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -qo awscliv2.zip
./aws/install --update
usermod -aG docker ubuntu || true
docker --version
'@

$dataIds = @(Get-HostIds "data")
$appIds = @(Get-HostIds "app")
$allIds = @($dataIds + $appIds) | Where-Object { $_ }
if (-not $allIds -or $allIds.Count -eq 0) {
  throw "No hosts in ansible/inventory/hosts.yml"
}

Write-Host "Installing Docker on: $($allIds -join ', ')"
$dockerB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($dockerScript))
$paramFile = Join-Path $env:TEMP "ssm-docker.json"
@{ commands = @("echo $dockerB64 | base64 -d | bash") } | ConvertTo-Json | Set-Content $paramFile -Encoding ascii

$cmdId = aws ssm send-command `
  --document-name "AWS-RunShellScript" `
  --instance-ids $allIds `
  --parameters "file://$paramFile" `
  --region $Region `
  --query Command.CommandId `
  --output text

Wait-Ssm $cmdId $allIds

$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ComposeData))
$dataScript = @"
set -euo pipefail
mkdir -p /opt/uncooked
cd /opt/uncooked
printf '%s' '$b64' | base64 -d > docker-compose.data.yml
docker compose -f docker-compose.data.yml up -d
docker compose -f docker-compose.data.yml ps
"@
$dataB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($dataScript))
$paramFile2 = Join-Path $env:TEMP "ssm-data.json"
@{ commands = @("echo $dataB64 | base64 -d | bash") } | ConvertTo-Json | Set-Content $paramFile2 -Encoding ascii

Write-Host "Starting data stack on $($dataIds -join ', ')"
$cmdId2 = aws ssm send-command `
  --document-name "AWS-RunShellScript" `
  --instance-ids $dataIds `
  --parameters "file://$paramFile2" `
  --region $Region `
  --query Command.CommandId `
  --output text

Wait-Ssm $cmdId2 $dataIds
Write-Host "Done. Paste values from docs/github-cd-vars.txt into GitHub, then run the CD workflow."
