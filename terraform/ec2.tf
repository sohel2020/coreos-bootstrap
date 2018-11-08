resource "aws_launch_configuration" "telenorhealth_workload" {
  iam_instance_profile        = "${var.iam_profile}"
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.ec2_key_name}"
  user_data                   = "${file("${path.module}/cloud-init.yaml")}"
  security_groups             = ["${aws_security_group.instance_security.id}"]
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.ebs_size}"
    delete_on_termination = true
  }
}

resource "aws_autoscaling_group" "telenorhealth_workload" {
  desired_capacity     = "1"
  max_size             = "5"
  min_size             = "1"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.telenorhealth_workload.name}"
  name                 = "${var.env}-${var.service_component}"
  vpc_zone_identifier  = ["${var.subnets}"]

  tag = {
    key                 = "Name"
    value               = "${var.env}-${var.service_component}"
    propagate_at_launch = true
  }

  tag = {
    key                 = "sla"
    value               = "${var.env}"
    propagate_at_launch = true
  }
}
