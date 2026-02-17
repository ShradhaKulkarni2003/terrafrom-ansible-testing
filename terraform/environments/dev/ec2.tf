# resource "aws_key_pair" "devops" {
#   key_name   = "devops-key"
# #   public_key = file("~/.ssh/devops-key.pub")
#    public_key = file("/home/shradha/.ssh/devops-key.pub")
# }


resource "aws_key_pair" "devops" {
  key_name   = "devops-key"
  public_key = file("${path.module}/../../keys/devops-key.pub")
}

resource "aws_instance" "dev" {
  ami           = "ami-0c02fb55956c7d316" # Ubuntu
  instance_type = "t3.micro"
  key_name      = aws_key_pair.devops.key_name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    echo "ec2-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ec2-user
    chmod 440 /etc/sudoers.d/ec2-user
  EOF

  tags = {
    Name = "dev-ec2"
  }
}

