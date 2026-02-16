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

  tags = {
    Name = "dev-ec2"
  }
}

