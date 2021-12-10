resource "aws_lb" "k8-load-balancer" {
  provider           = aws.default-region
  name               = "k8-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer-sg.id]
  subnets            = [aws_subnet.mlops-subnet.id]

  tags = {
    Name = "k8-load-balancer"
  }
}

resource "aws_lb_target_group" "control-plane-tg" {
  provider    = aws.default-region
  name        = "controllers-tg"
  port        = 6443
  target_type = "instance"
  vpc_id      = aws_vpc.mlops-vpc.id
  protocol    = "https"
  health_check {
    enabled  = true
    interval = 10
    path     = "/healthz"
    port     = 6443
    protocol = "HTTPS"
    matcher  = "200-299"
  }

  tags = {
    Name = "jenkins-target-group"
  }

}

resource "aws_lb_listener" "k8-api-listener" {
  provider          = aws.default-region
  load_balancer_arn = aws_lb.k8-load-balancer.arn
  port              = 443
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.control-plane-tg.id
  }
}

resource "aws_lb_target_group_attachment" "control-plane-tga" {
  count = length(aws_instance.controller-nodes)
  provider         = aws.default-region
  target_group_arn = aws_lb_target_group.control-plane-tg.arn
  target_id        = aws_instance.controller-nodes[count.index].id
  port             = 6443
}