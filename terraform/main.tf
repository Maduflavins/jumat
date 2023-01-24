resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate a Private Key and encode it as PEM.
resource "aws_key_pair" "microservice_key" {
  key_name   = "microservice_key"
  public_key = tls_private_key.key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.key.private_key_pem}' > ./microservice_key.pem"
  }
}


# resource "tls_private_key" "key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# Generate a Private Key and encode it as PEM.
resource "aws_key_pair" "database_key" {
  key_name   = "database_key"
  public_key = tls_private_key.key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.key.private_key_pem}' > ./database_key.pem"
  }
}

resource "aws_instance" "microservice" {
  count         = length(local.nodes_app)
  ami           = "ami-0a89a7563fc68be84"
  instance_type = var.instance_type
  # name          = var.node_name[count.index]
  subnet_id     = module.vpc.subnet_1_id
  key_name      = aws_key_pair.microservice_key.id
  #subnet_id              = var.subnet_id
  vpc_security_group_ids = [module.vpc.security_group_id_app]
  #associate_public_ip_address = true
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 40
    volume_type           = "gp2"
  }

  tags = {
    Name = "Microservice"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo sed -i 's/Port 1337/Port 22/g' /etc/ssh/sshd_config
              sudo service ssh restart
              EOF
#   network_interface {
#     network_interface_id = aws_network_interface.microservice_netint.id
#   }

}


resource "aws_instance" "database" {
  count         = length(local.nodes_db)
  ami           = "ami-0a89a7563fc68be84"
  instance_type = var.instance_type
  #name          = var.node_name[count.index]
  subnet_id     = module.vpc.subnet_1_id
  key_name      = aws_key_pair.database_key.id
  vpc_security_group_ids = [module.vpc.security_group_id_db]
  #associate_public_ip_address = true
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 40
    volume_type           = "gp2"
  }

  tags = {
    Name = "Database"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo sed -i 's/Port 1337/Port 22/g' /etc/ssh/sshd_config
              sudo service ssh restart
              EOF
   
}

module "vpc" {
  source = "./module/vpc"

  vpc_cidr          = "10.0.0.0/16"
#   availability_zone = "${var.region}"
  environment       = var.environment
  subnet_cidr       = "10.0.0.0/24"
}

# Tick stack
# module "microservice" {
#   source = "./module/microservice"
#   node_count         = length(local.nodes_app)
#   subnet_id          = module.vpc.subnet_1_id
#   node_name          = local.nodes_app
#   instance_type      = var.instance_type
#   security_group_ids = [module.vpc.security_group_id_app]
# }

# module "database" {
#     source = "./module/databases"
#     node_count         = length(local.nodes_db)
#     subnet_id          = module.vpc.subnet_1_id
#     node_name          = local.nodes_db
#     instance_type      = var.instance_type
#     security_group_ids = [module.vpc.security_group_id_db]
#     # security_group_rule_ids = [module.vpcsecurity_group_rules_id_db]
  
# }

# resource "aws_lb" "jumia_validator_lb" {
#   name               = "jumia_validator_elb"
#   security_groups    = [module.vpc.security_group_id_app]
#   subnets            = [module.vpc.vpc_subnet_id]
#   instance =          [module.microservice.id]
# }

# resource "aws_lb_target_group" "jumia_validator_tg" {
#   name     = "jumia_validator_tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = module.vpc.vpc_id
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.jumia_validator_lb.arn
#   protocol          = "HTTP"
#   port              = "80"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.jumia_validator_tg.arn
#   }
# }

# resource "aws_lb_listener" "ssh" {
#   load_balancer_arn = aws_lb.jumia_validator_lb.arn
#   protocol          = "TCP"
#   port              = "1337"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.jumia_validator_tg.arn
#   }
# }





resource "aws_alb" "jumia_validator_alb" {
  name            = "jumia-validator-alb"
  internal        = false
  security_groups = [module.vpc.jumia_validator_lb_sg_id]
  subnets         = [module.vpc.subnet_1_id, module.vpc.subnet_2_id]
}

resource "aws_alb_listener" "jumia_validator_listener" {
  load_balancer_arn = aws_alb.jumia_validator_alb.arn
  port             = "80"
  protocol         = "HTTP"

  default_action {
    target_group_arn = module.vpc.jumia_validator_tg_arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "jumia_valid_listener" {
  listener_arn = aws_alb_listener.jumia_validator_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.vpc.jumia_validator_tg_arn
  }

  condition {
    path_pattern{
    values = ["/"]
    }
  }
}



resource "aws_alb_target_group_attachment" "jumia_valid_attach" {
  target_group_arn = module.vpc.jumia_validator_tg_arn
  target_id        = one(aws_instance.microservice[*].id)
  port             = 80
}


# resource "aws_network_interface" "microservice_netint" {
#   subnet_id = module.vpc.subnet_1_id
# #   private_ips = [var.private_ip]
# #   associate_with_private_ip = var.private_ip
#   associate_public_ip_address = true

#   tags = {
#     Name = "Microservice"
#   }
# }

# resource "aws_instance" "example" {
#   ami           = var.ami_id
#   instance_type = var.instance_type



#   tags = {
#     Name = "example"
#   }
# }