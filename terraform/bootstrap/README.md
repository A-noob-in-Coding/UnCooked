# State bucket

Creates the S3 bucket + DynamoDB lock table once. Run this before the main stack.

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

Then:

```bash
cd ..
terraform init -migrate-state
terraform plan
```

If the bucket name in the output differs from `backend.tf`, edit `backend.tf` to match.

Don't destroy this while the main stack still points at it.
