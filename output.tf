output "jenkins-main-node-public-ip" {
  value = aws_instance.jenkins-master.public_ip
}

output "jenkins-worker-public-ips" {
  value = {
    for instance in aws_instance.jenkins-worker :
    instance.id => instance.public_ip
  }
}
/*
output "lb-dns-name" {
  value = aws_lb.application-lb.dns_name
}*/