terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "us-west-2"
}

# Define the first EC2 instance resource
resource "aws_instance" "Monithor_jenkins" {
  ami             = "ami-05d38da78ce859165"
  instance_type   = "t2.micro"
  vpc_security_group_ids = ["sg-02b3d29bdcd49a0cc"]
  key_name = "MoniNordic"
  tags = {
    Purpose     = "jenkins"  
    Name        = "jenkins"
    Owner       = "Nordic"
  }
}

# Define the second EC2 instance resource
resource "aws_instance" "Monithor_docker_agent" {
  ami             = "ami-05d38da78ce859165"
  instance_type   = "t2.micro"
  vpc_security_group_ids = ["sg-02b3d29bdcd49a0cc"]
  key_name = "MoniNordic"
  tags = {
    Purpose     = "docker_agent"  
    Name        = "docker_agent"
    Owner       = "Nordic"
  }
}

# Define the second EC2 instance resource
resource "aws_instance" "Monithor_ansible_agent" {
  ami             = "ami-05d38da78ce859165"
  instance_type   = "t2.micro"
  vpc_security_group_ids = ["sg-02b3d29bdcd49a0cc"]
  key_name = "MoniNordic"
  tags = {
    Purpose     = "ansible_agent"  
    Name        = "ansible_agent"
    Owner       = "Nordic"
  }
}

# Define the second EC2 instance resource
resource "aws_instance" "Monithor_prod1" {
  ami             = "ami-05d38da78ce859165"
  instance_type   = "t2.micro"
  vpc_security_group_ids = ["sg-02b3d29bdcd49a0cc"]
  key_name = "MoniNordic"
  tags = {
    Purpose     = "production"  
    Name        = "prod1"
    Owner       = "Nordic"
  }

}

# Define the second EC2 instance resource
resource "aws_instance" "Monithor_prod2" {
  ami             = "ami-05d38da78ce859165"
  instance_type   = "t2.micro"
  vpc_security_group_ids = ["sg-02b3d29bdcd49a0cc"]
  key_name = "MoniNordic"
  tags = {
    Purpose     = "production"  
    Name        = "prod2"
    Owner       = "Nordic"
  }

}


# Data source to get the default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

# Data source to get the subnet IDs of the default VPC
data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# Define the security group for the Application Load Balancer
resource "aws_security_group" "alb" {
  name = "alb-security-group"
}


# Define the Application Load Balancer
resource "aws_lb" "load_balancer" {
  name               = "web-app-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default_subnet.ids
  security_groups    = ["sg-02b3d29bdcd49a0cc"]
}

# Define the HTTP listener for the ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  # Default action to return a 404 response
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# Define the target group for the EC2 instances
resource "aws_lb_target_group" "Monithor_prod" {
  name     = "app-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  # Health check configuration
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
      
  }
  stickiness { 
    type = "lb_cookie" 
    cookie_duration = 86400 # 1 day in seconds 
    }
}

locals {
  prod_instances = [
    aws_instance.Monithor_prod1.id,
    aws_instance.Monithor_prod2.id
  ]
}

# Attach the first EC2 instance to the target group
resource "aws_lb_target_group_attachment" "Monithor_prod" {
  count = length(local.prod_instances)  
  target_group_arn = aws_lb_target_group.Monithor_prod.arn
  target_id        = local.prod_instances[count.index]
  port             = 8080
}


# Define the listener rule to forward traffic to the target group
resource "aws_lb_listener_rule" "Monithor_prod" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Monithor_prod.arn
  }
}

# Output the public IP address of the first instance
output "Monithor_jenkins_public_ip" {
  description = "The public IP address of instance jenkins"
  value       = aws_instance.Monithor_jenkins.public_ip
}

# Output the public IP address of the second instance
output "Monithor_docker_agent_public_ip" {
  description = "The public IP address of instance docker agent"
  value       = aws_instance.Monithor_docker_agent.public_ip
}

# Output the public IP address of the second instance
output "Monithor_ansible_agent_public_ip" {
  description = "The public IP address of instance ansible agent"
  value       = aws_instance.Monithor_ansible_agent.public_ip
}

# Output the public IP address of the second instance
output "Monithor_prod1_public_ip" {
  description = "The public IP address of instance prod1"
  value       = aws_instance.Monithor_prod1.public_ip
}

# Output the public IP address of the second instance
output "Monithor_prod2_public_ip" {
  description = "The public IP address of instance prod2"
  value       = aws_instance.Monithor_prod2.public_ip
}

# Output the DNS name of the load balancer
output "load_balancer_dns" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.load_balancer.dns_name
}
