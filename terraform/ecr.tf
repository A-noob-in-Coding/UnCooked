resource "aws_ecr_repository" "app" {
  for_each = toset(local.ecr_repos)

  name                 = "${local.name_prefix}-${each.key}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${local.name_prefix}-${each.key}" }
}
