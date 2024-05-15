resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
variable "availability_zones" {
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}




resource "aws_subnet" "public" {
  count                  = 3  # Adjust the count based on your requirements
  vpc_id                 = aws_vpc.main.id
  availability_zone = var.availability_zones[count.index]
  cidr_block             = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
}




resource "aws_subnet" "private" {
  count                  = 3
  vpc_id                 = aws_vpc.main.id
  cidr_block             = "10.0.${count.index + 3}.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "nat" {
  count             = 3
  subnet_id         = aws_subnet.public[count.index].id
  allocation_id     = aws_eip.nat[count.index].id
}

resource "aws_eip" "nat" {
  count = 3
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

}



resource "aws_route_table" "private" {
  count = 3
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }

}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}" 
  route_table_id = aws_route_table.private[count.index].id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "web_sg" {
  name        = "wordpress"
  description = "wordpress"
  vpc_id      = aws_vpc.main.id  

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ssh"
  } 

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-wordpress"
  }
}

output "web_sg_id" {
  value       = aws_security_group.web_sg.id
  description = "The ID of the web security group"
}

# // ASG 
# resource "aws_launch_template" "wordpress" {  
  
#   name_prefix   = "wordpress-template-"
#   instance_type = "t2.micro"
#   image_id = "ami-066a65da56486f60a" // used the ami from terraform-test

  
#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "db_instance"
#     }
#   }

 
  
#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size = 20
#       volume_type = "gp2"
#     }
#   }
# }

resource "aws_launch_configuration" "wordpress" {
  name          = "wordpress"
  image_id      = "ami-0ddda618e961f2270"  
  instance_type = "t2.micro"
  key_name      = "rahat200"
  security_groups = [aws_security_group.web_sg.id]
  user_data     = base64encode(<<-EOF
                  #!/bin/bash
                  yum update -y
                  yum install -y httpd php php-mysqlnd
                  systemctl start httpd
                  systemctl enable httpd
                  wget -c https://wordpress.org/latest.tar.gz
                  tar -xvzf latest.tar.gz -C /var/www/html
                  cp -r /var/www/html/wordpress/* /var/www/html/
                  chown -R apache:apache /var/www/html/
                  mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
                  sed -i "s/database_name_here/wordpress_db/" /var/www/html/wp-config.php
                  sed -i "s/username_here/${var.db_username}/" /var/www/html/wp-config.php
                  sed -i "s/password_here/${var.db_password}/" /var/www/html/wp-config.php
                  EOF
                )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "asg" {
  name_prefix   = "asg"
  image_id      = "ami-0900fe555666598a2"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "wordpress_asg" {
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  desired_capacity   = 3
  max_size           = 99
  min_size           = 1

  launch_template {
    id      = aws_launch_template.asg.id 
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "wordpress-asg"
    propagate_at_launch = true
  }
}

# resource "aws_autoscaling_group" "wordpress_asg" {
#   name                 = "wordpress-asg"
#   availability_zones   = ["us-east-2a", "us-east-2b", "us-east-2c"]  // Specify actual zones
#   min_size             = 1
#   max_size             = 99
#   desired_capacity     = 1
#   launch_template {
#     id = aws_launch_configuration.wordpress.id
#   }
# }

# // ALB 
# # resource "aws_lb" "wordpress" {
# #   name               = "wordpress-lb"
#   internal           = false
#   load_balancer_type = "application"
#   subnets            = aws_subnet.public[*].id
# }
resource "aws_lb" "wordpress" {
  name               = "wordpress-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id 
  # Here, we specify the IDs of the public subnets created in different Availability Zones.
  
  enable_deletion_protection = false
  security_groups = [aws_security_group.web_sg.id]

  tags = {
    Name = "wordpress-lb"
  }
}

output "alb_dns_name" {
  value = aws_lb.wordpress.dns_name
}


resource "aws_lb_target_group" "wordpress" {
  name     = "wordpress-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   =  aws_vpc.main.id
}

resource "aws_lb_listener" "wordpress" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.wordpress.arn
    type             = "forward"
  }
}
// Route 53
resource "aws_route53_zone" "example" {
  name = "wordpress.rahat.com"
}

resource "aws_route53_record" "wordpress" {
  # zone_id = aws_route53_zone.example.zone_id
  zone_id = "Z05658672GPJJYC7YID7I"
  name    = "wordpress"
  type    = "A"
  # records = [aws_rds_cluster_instance.writer.endpoint]
  alias {
    name                   = aws_lb.wordpress.dns_name
    zone_id                = aws_lb.wordpress.zone_id
    evaluate_target_health = true
  }
}

# # Create an Auto Scaling Group (ASG) using the launch template
# resource "aws_launch_template" "wordpress" {
#   name_prefix   = "wordpress-template-"
#   image_id      = "ami-0900fe555666598a2"
#   instance_type = "t2.micro"
