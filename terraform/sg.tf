resource "aws_security_group" "instance_security" {
  name        = "${var.env}-${var.service_name}-${var.service_component}"
  description = "Allow traffic on the all ports"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "all_traffic_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.instance_security.id}"
  cidr_blocks       = ["${var.vpc_cidr}"]
}

resource "aws_security_group_rule" "all_traffic_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.instance_security.id}"
}
