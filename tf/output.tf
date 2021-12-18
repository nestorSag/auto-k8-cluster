output "controller-public-ips" {
  value = {
    for instance in aws_instance.controller-nodes :
    instance.id => instance.public_ip
  }
}

output "controller-private-ips" {
  value = {
    for instance in aws_instance.controller-nodes :
    instance.id => instance.private_ip
  }
}

output "worker-public-ips" {
  value = {
    for instance in aws_instance.worker-nodes :
    instance.id => instance.public_ip
  }
}

output "worker-private-ips" {
  value = {
    for instance in aws_instance.worker-nodes :
    instance.id => instance.private_ip
  }
}

output "lb-dns" {
  value = aws_lb.k8-load-balancer.dns_name
}
