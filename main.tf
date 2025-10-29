resource "aws_security_group" "main" {
  name        = "${var.name}-${env}"
  description = "${var.name}-${env}"
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = var.port_no
    to_port          = var.port_no
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_instance" "node" {
  ami           = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = "${var.name}-${env}"
  }
}
# Create DNS Record in Route53
resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.name}-${env}.khaleel221.shop"
  type    = "A"
  ttl     = 30
  records = [aws_instance.node.private_ip]

  depends_on = [aws_instance.node] # ensures EC2 is created first
}
resource "null_resource" "provisioner" {
  depends_on = [aws_route53_record.record]

  connection {
    host     = aws_instance.node.private_ip
    user     = "ec2-user"
    password = "DevOps321"
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "ansible-pull -i localhost, -U https://github.com/Khaleel221/Expense-Ansible expense.yml -e role_name=${var.name} -e env=${var.env}"
    ]
  }
}
