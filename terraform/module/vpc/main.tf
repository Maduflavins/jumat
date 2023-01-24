
data "aws_availability_zones" "azs" {
  # region = "eu-west-3"
  state    = "available"
}
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    "Name" = "Jumia-Phone-Validator"
  }
}

resource "aws_subnet" "subnet_1" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_2" {
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rt.id
}

# resource "aws_subnet" "subnet" {
#   vpc_id                  = aws_vpc.vpc.id
#   cidr_block              = var.subnet_cidr
#   map_public_ip_on_launch = true
#   availability_zone       = var.availability_zone

#   tags = {
#     environment = var.environment
#   }
# }

resource "aws_security_group" "app_nodes" {
  name        = "app_nodes"
  description = "Allow incoming Traffics"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow HTTP Trafic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow  Trafic on 8081"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "Allow  Trafic on 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow  Trafic on 1337"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS Trafic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "Allow temp ingress on 22"
    #this ingress will be deleted after configuring with ansible
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}



resource "aws_security_group" "db_nodes" {
  name        = "db-nodes"
  description = "Allow incoming Traffics"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow ssh Trafic"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "Allow Traffic on 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow incoming for db port"
    from_port                = 5432
    to_port                  = 5432
    protocol                 = "tcp"
  }

  ingress {
    description = "Allow temp ingress on 22"
    #this ingress will be deleted after configuring with ansible
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}






resource "aws_security_group" "jumia_validator_lb" {
  name        = "jumia-validator-lb"
  description = "Allow incoming Traffics"
  vpc_id      =  aws_vpc.vpc.id

  ingress {
    description = "Allow HTTP Trafic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   description = "Allow HTTPS Trafic"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  ingress{
    description = "allow ssh on 1337"
    from_port = 1337
    to_port = 1337
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}


resource "aws_alb_target_group" "jumia_validator_tg" {
  name     = "jumia-validator-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}






# resource "aws_security_group_rule" "db_connection" {
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.app_nodes.id

#   security_group_id = aws_security_group.db_nodes.id
#   depends_on = [aws_security_group.db_nodes]
# }
