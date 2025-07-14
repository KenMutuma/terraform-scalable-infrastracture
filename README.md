# 🛠️ AWS Infrastructure Deployment using Terraform

This Terraform project provisions a production-ready AWS environment including VPC, subnets, security groups, Auto Scaling Group (ASG), Application Load Balancer (ALB), and AWS WAF. It's ideal for deploying scalable and secure web applications in the **`us-east-1`** region.

## 🚀 Features

- **VPC and Subnets**: Creates a custom VPC with two public subnets.
- **Internet Gateway and Route Table**: Enables internet access for public subnets.
- **Security Groups**: Implements granular security rules for:
  - Web access (HTTP, HTTPS, SSH)
  - Application Load Balancer
  - Launch Template instances
- **Launch Template & ASG**: Automatically scales EC2 instances across subnets using a Launch Template.
- **ALB**: Distributes traffic to healthy instances across the ASG.
- **WAF**: Adds AWS-managed Web Application Firewall rules for security hardening.
- **Listener Rule**: Forwards all HTTP requests to target group.
- **Outputs**: Displays ALB DNS for easy access after deployment.

## 🧱 Resources Created

| Resource Type | Purpose |
|---------------|---------|
| `aws_vpc` | Isolated network space |
| `aws_subnet` | Public subnets in different AZs |
| `aws_internet_gateway` | Internet access |
| `aws_route_table` & `association` | Routing for internet access |
| `aws_security_group` | Controls inbound/outbound traffic |
| `aws_launch_template` | EC2 instance blueprint |
| `aws_autoscaling_group` | Horizontal scaling of EC2 |
| `aws_lb` | Application Load Balancer |
| `aws_lb_listener` & `rule` | HTTP routing configuration |
| `aws_wafv2_web_acl` | WAF rules for common threats |
| `aws_lb_target_group` | Routes traffic to EC2 instances |
| `output` | ALB DNS URL |

## 🔐 Security

- Allows inbound access to:
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
  - Port 22 (SSH)
- Restricts ALB egress to VPC CIDR for added protection.
- WAF rules include:
  - `AWSManagedRulesCommonRuleSet`
  - `AWSManagedRulesKnownBadInputsRuleSet`

## 📦 Requirements

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- AWS credentials configured (via environment or IAM roles)
- An SSH key pair if EC2 access is required

## ⚙️ Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/kenMutuma/terraform-aws-infra.git
   cd terraform-aws-infra
   ```

2. Initialise Terraform:
   ```bash
   terraform init
   ```

3. Review planned changes:
   ```bash
   terraform plan
   ```

4. Apply infrastructure:
   ```bash
   terraform apply
   ```

5. Access your app using the ALB DNS output:
   ```
   alb_dns_name = <your-alb-dns>
   ```

## 📝 Notes

- The AMI used in the Launch Template is hardcoded (`ami-04b4f1a9cf54c11d0`) and should be updated as needed.
- The Auto Scaling Group ensures a minimum of 2 and a maximum of 6 instances.
- Some blocks (e.g., EC2 instance using a standalone network interface) are commented out but left for future extension.

## 📂 File Structure

```
.
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

## 🧼 Disclaimer

> Do **not** commit sensitive information like AWS access keys. They have been commented out in the code, but best practice is to use IAM roles or environment variables for authentication.

## 🧠 Author

**Your Name**  
[GitHub Profile](https://github.com/kenMutuma)  
Cloud & DevSecOps Enthusiast

---

Happy Terraforming! ☁️🚀
