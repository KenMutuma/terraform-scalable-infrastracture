provider "aws" {
  region = "us-east-1"
  
}

variable "subnet-prefix" {
  description = "cidr block for the subnet"
  default = [
    {
      cidr_block = "10.0.1.0/24"
      name       = "prod-subnet-1"
    },
    {
      cidr_block = "10.0.2.0/24"
      name       = "prod-subnet-2"
    }
    
      
   ]
  
}

#creating a vpc
 resource "aws_vpc" "prod-vpc" {
    cidr_block =  "10.0.0.0/16"
    tags = {
      Name = "production"
    }
   
 }



#creating an Internet Getway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  # tags = {
  #   Name = "main"
  # }
}


resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-rt"
  }
}

 #creating a subnet
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet-prefix[0].cidr_block
    availability_zone = "us-east-1a"

    tags = {
      Name = var.subnet-prefix[0].name
    }
   
 }

  #creating a subnet
resource "aws_subnet" "subnet-2" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet-prefix[1].cidr_block
    availability_zone = "us-east-1b"

    tags = {
      Name = var.subnet-prefix[1].name
    }
   
 }

#route table assosciation. Associated the route table with the subnet
 resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}


resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"   
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "HTTP"   
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "SSH"   
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_web_traffic"
  }
}



# resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic_ipv6" {
#   security_group_id = aws_security_group.allow_web.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

#  resource "aws_network_interface" "web_server_nic" {
#   subnet_id       = aws_subnet.subnet-1.id
#   private_ips     = ["10.0.1.50"]
#   security_groups = [aws_security_group.allow_web.id]

#   # attachment {
#   #   instance     = aws_instance.web-server.id
#   #   device_index = 1
#   # }
# }

# resource "aws_eip" "one" {
#   #vpc = true
#   network_interface         = aws_network_interface.web_server_nic.id
#   associate_with_private_ip = "10.0.1.50"
#   depends_on = [ aws_internet_gateway.gw ]
# }



#create an instance
# resource "aws_instance" "web-server" {
#  ami = "ami-04b4f1a9cf54c11d0"
#  instance_type = "t2.micro"
#  availability_zone = "us-east-1a"
#  key_name = "vokey"

#  network_interface {
#    device_index = 0
#    network_interface_id = aws_network_interface.web_server_nic.id
#  }
#  user_data = <<-EOF
#              #!/bin/bash
#              sudo apt update -y
#              sudo apt install apache2 -y
#              sudo systemctl start apache2
#              sudo bash -c 'echo your first web server > /var/www/html/index.html'
#              EOF

#   tags = {
#    Name = "ubuntu-server"
#  }
#}
 #

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type= number
    default = 8080
  
}
#security group for launch configuration
resource "aws_security_group" "aws_lc_sg" {
 name = "Launch_Template_Security_group"
 vpc_id      = aws_vpc.prod-vpc.id
 
 ingress {
 from_port = var.server_port
 to_port = var.server_port
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 security_groups = [aws_security_group.alb-sg.id] #Allow ALB access
 }
}

resource "aws_launch_template" "aws_lc" {
  name_prefix   = "asg_launch_conf"
  image_id      = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  
  

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.aws_lc_sg.id]
    
  }
# Adding user_data with proper variable interpolation
# We use base64encode to ensure correct formating for EC2
   user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF
  )
 # Required when using a launch configuration with an auto scaling group.
 lifecycle {
 create_before_destroy = true
 }
}

resource "aws_autoscaling_group" "web-asg" {
  name = "web-asg"
  vpc_zone_identifier = [aws_subnet.subnet-1.id,aws_subnet.subnet-2.id]
  
  
  
  target_group_arns = [aws_lb_target_group.lb_trg.arn]
  health_check_grace_period = 300
  health_check_type = "ELB"

  min_size = 2
  max_size = 6

  launch_template {
    id = aws_launch_template.aws_lc.id
    version = "$Latest"
  }

  tag {
      key = "Name"
      value = "web-server-asg"
      propagate_at_launch = true
 }
}

# data "aws_vpc" "default" {
#  default = true
# }

# data "aws_subnets" "default" {
#  filter {
#  name = "vpc-id"
#  values = [data.aws_vpc.default.id]
#  }
# }

resource "aws_lb" "web-server-lb" {
  name               = "web-server-lb" 
  load_balancer_type = "application"
  subnets = [aws_subnet.subnet-1.id,aws_subnet.subnet-2.id]
  security_groups = [aws_security_group.alb-sg.id]

  
}


resource "aws_lb_listener" "http" {
 load_balancer_arn = aws_lb.web-server-lb.arn
 port = 80
 protocol = "HTTP"

# By default, return a simple 404 page
 default_action {
 type = "fixed-response"
 fixed_response {
 content_type = "text/plain"
 message_body = "404: page not found"
 status_code = 404
 }
 }
}

resource "aws_security_group" "alb-sg" {
  name = "Application_LB_SG"
  description = "Security group for Application Load Balancer"
  vpc_id = aws_vpc.prod-vpc.id
  #allow inbound HTTP requests
  ingress  {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 #Allow all outboud request
  egress {
    description = "Allow traffic to instances on app port"
    from_port = var.server_port #e.g 8080
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = [aws_vpc.prod-vpc.cidr_block] #Restricted to VPC
  }

  tags = {
    Name = "alb-security-group"
  }

  
}
# WAF Configuration
resource "aws_wafv2_web_acl" "web_acl" {
  name        = "alb-web-acl"
  description = "Web ACL for ALB protection"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "alb-web-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb_association" {
  resource_arn = aws_lb.web-server-lb.arn
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}

resource "aws_lb_target_group" "lb_trg" {
 name = "lb-trg"
 port = var.server_port
 protocol = "HTTP"
 vpc_id = aws_vpc.prod-vpc.id
 
 
      health_check {
          path = "/"
          protocol = "HTTP"
          matcher = "200"
          interval = 30
          timeout = 3
          healthy_threshold = 2
          unhealthy_threshold = 2
      }
}

# The preceding code adds a listener rule that sends requests that match any path to the target group that contains  ASG
resource "aws_lb_listener_rule" "asg" {
 listener_arn = aws_lb_listener.http.arn
 priority = 100
      condition {
          path_pattern {
          values = ["*"]
          }
      }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lb_trg.arn
  }
}

output "alb_dns_name" {
 value = aws_lb.web-server-lb.dns_name
 description = "The domain name of the load balancer"
}
