resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate a Private Key and encode it as PEM.
resource "aws_key_pair" "database_key" {
  key_name   = "database_key"
  public_key = tls_private_key.key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.key.private_key_pem}' > ./database_key.pem"
  }
}

# resource "aws_instance" "microservice" {
#   count         = var.node_count
#   ami           = "ami-0a89a7563fc68be84"
#   instance_type = var.instance_type
#   key_name      = aws_key_pair.microservice_key.id

#   subnet_id              = var.subnet_id
#   vpc_security_group_ids = var.security_group_ids

#   root_block_device {
#     delete_on_termination = true
#     encrypted             = false
#     volume_size           = 40
#     volume_type           = "gp2"
#   }

#   tags = {
#     Name = element(var.node_name, count.index)
#   }
# }


resource "aws_instance" "database" {
  count         = var.node_count
  ami           = "ami-0a89a7563fc68be84"
  instance_type = var.instance_type
  #name          = var.node_name[count.index]
  subnet_id     = var.subnet_id
  key_name      = aws_key_pair.database_key.id
  vpc_security_group_ids = var.security_group_ids
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 40
    volume_type           = "gp2"
  }

  tags = {
    Name = element(var.node_name, count.index)
  }
}






