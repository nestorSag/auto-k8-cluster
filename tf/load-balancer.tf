resource "aws_lb" "k8-load-balancer" {
  provider           = aws.default-region
  name               = "k8-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer-sg.id]
  subnets            = [for elem in aws_subnet.mlops-subnets : elem.id]

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
  protocol    = "TCP"
  health_check {
    enabled  = false
    interval = 10
    path     = "/"
    port     = 6443
    protocol = "HTTP"
    matcher  = "200-299"
  }

  tags = {
    Name = "controllers-target-group"
  }

}

resource "aws_lb_listener" "k8-api-listener" {
  provider          = aws.default-region
  load_balancer_arn = aws_lb.k8-load-balancer.arn
  port              = 6443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.control-plane-tg.id
  }
}

resource "aws_lb_target_group_attachment" "control-plane-tga" {
  count            = length(aws_instance.controller-nodes)
  provider         = aws.default-region
  target_group_arn = aws_lb_target_group.control-plane-tg.arn
  target_id        = aws_instance.controller-nodes[count.index].id
}