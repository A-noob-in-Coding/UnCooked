# Remote state in the bootstrap bucket (see terraform/bootstrap).
terraform {
  backend "s3" {
    bucket         = "uncooked-tfstate-062301636277"
    key            = "phase02/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "uncooked-tf-locks"
  }
}
