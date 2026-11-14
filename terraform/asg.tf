resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_app}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 40
      volume_type = "gp3"
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/app-userdata.sh.tpl", {
    aws_region   = var.aws_region
    ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    data_host    = aws_instance.data.private_ip
    compose_b64  = filebase64("${path.module}/../web/docker-compose.app.yml")
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = local.name_app
      Role = "app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = local.name_asg
  min_size                  = var.asg_min
  desired_capacity          = var.asg_desired
  max_size                  = var.asg_max
  vpc_zone_identifier       = aws_subnet.private[*].id
  health_check_type         = "ELB"
  health_check_grace_period = 900
  target_group_arns         = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = local.name_app
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "app"
    propagate_at_launch = true
  }
}

# Target tracking on ALB request count (scale-out under load, scale-in after).
resource "aws_autoscaling_policy" "app_request_count" {
  name                   = "${local.name_asg}-req-count"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.app.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }
    target_value = 100.0
  }
}
