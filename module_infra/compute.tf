resource "aws_security_group" "web_server_sg" {
  name        = "allow_http_and_SSH"
  description = "Allow http to our hosts and SSH from local only"
  vpc_id      = aws_vpc.infra_vpc.id

  tags = {
    Name = "${var.environment_name}-dev-sg"
  }
}

resource "aws_security_group_rule" "allow_http_rule_ws" {
  type              = "ingress"
  security_group_id = aws_security_group.web_server_sg.id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ssh_rule_ws" {
  type              = "ingress"
  security_group_id = aws_security_group.web_server_sg.id
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound_traffic_ws" {
  type              = "egress"
  security_group_id = aws_security_group.web_server_sg.id
  protocol          = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "bastion_host_sg" {
  name        = "allow_SSH"
  description = "Allow http to our hosts and SSH from local only"
  vpc_id      = aws_vpc.infra_vpc.id

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group_rule" "bastion_ssh_rule" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_host_sg.id
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["${chomp(data.http.my_public_ip.response_body)}/32"]
}

resource "aws_security_group_rule" "bastion_all_outbound_traffic" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_host_sg.id
  protocol          = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "load_balancer_sg" {
  name        = "allow_http"
  description = "Allow http to our hosts"
  vpc_id      = aws_vpc.infra_vpc.id

  tags = {
    Name = "${var.environment_name}-load-balancer-sg"
  }
}

resource "aws_security_group_rule" "allow_inbound_traffic_lb" {
  type              = "ingress"
  security_group_id = aws_security_group.load_balancer_sg.id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound_traffic_lb" {
  type              = "egress"
  security_group_id = aws_security_group.load_balancer_sg.id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_key_pair" "infra_auth" {
  key_name   = "instance_id_ed25519"
  public_key = file("~/.ssh/instance_id_ed25519.pub")
}

resource "aws_key_pair" "bastion_auth" {
  key_name   = "jump_box"
  public_key = file("~/.ssh/jump_box_ed25519.pub")
}

# set up launch template 
resource "aws_launch_template" "instance_launch_template" {
  name                   = "instance-launch-template"
  description            = "Launch Instance template"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.environment_name == "production" ? var.instance_type : "t3.micro"
  ebs_optimized          = true
  key_name               = aws_key_pair.infra_auth.id
  user_data              = filebase64("./web_script.sh")

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 20
      volume_type           = "gp2"
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  cpu_options {
    core_count       = 1
    threads_per_core = 1
  }

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.environment_name}-Instance"
    }
  }
}

resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet_1.id
  availability_zone           = data.aws_availability_zones.available.names[0]
  key_name                    = aws_key_pair.bastion_auth.id
  security_groups             = [aws_security_group.bastion_host_sg.id]
}

# Autoscaling group for instance
resource "aws_autoscaling_group" "dev_autoscaling_group" {
  name_prefix               = "mydevasg-"
  desired_capacity          = 2
  max_size                  = 6
  min_size                  = 2
  vpc_zone_identifier       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true

  launch_template {
    id      = aws_launch_template.instance_launch_template.id
    version = "$Latest"
  }
  # Instance Refresh
  instance_refresh {
    strategy = "Rolling"

    preferences {
      instance_warmup        = 300
      min_healthy_percentage = 50
      max_healthy_percentage = 100
    }

    triggers = ["desired_capacity"]
  }

}

resource "aws_lb" "load_balancer" {
  name               = "dev-application-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.load_balancer_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_instances.arn
  }
}

resource "aws_lb_target_group" "target_instances" {
  name     = "dev-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.infra_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.dev_autoscaling_group.id
  lb_target_group_arn    = aws_lb_target_group.target_instances.arn
}

resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_instances.arn
  }
}                      