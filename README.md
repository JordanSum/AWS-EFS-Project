# AWS EFS Project with Terraform

A production-ready Terraform project that deploys a multi-AZ AWS infrastructure with Elastic File System (EFS) shared storage across EC2 instances. This setup demonstrates how to create a highly available, scalable file storage solution accessible from multiple compute instances.

## Architecture Overview

This project provisions:
- **VPC** with DNS support and Internet Gateway
- **Two subnets** across availability zones (us-west-2a and us-west-2b)
- **Two EC2 instances** (one per AZ) with SSM Session Manager access
- **Elastic IPs** for public internet access
- **EFS file system** with mount targets in both AZs
- **Security groups** configured for EFS NFS traffic (port 2049)
- **Automated mounting** of EFS to `/terraform-efs` on instance launch

## Prerequisites

Before you begin, ensure you have the following:

### Required Tools
- **Terraform** >= 1.0.0 ([Installation Guide](https://developer.hashicorp.com/terraform/downloads))
- **AWS CLI** configured with credentials ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **Git** for version control

### AWS Requirements
- **AWS Account** with appropriate permissions
- **IAM User/Role** with permissions for:
  - EC2 (instances, network interfaces, EIPs)
  - VPC (subnets, route tables, internet gateways)
  - EFS (file systems, mount targets)
  - Security Groups
  - SSM (Systems Manager for instance access)
- **AWS credentials** configured locally:
  ```bash
  aws configure
  ```
  Or set environment variables:
  ```bash
  export AWS_ACCESS_KEY_ID="your-access-key"
  export AWS_SECRET_ACCESS_KEY="your-secret-key"
  export AWS_DEFAULT_REGION="us-west-2"
  ```

### Knowledge Prerequisites
- Basic understanding of AWS services (VPC, EC2, EFS)
- Familiarity with Terraform workflows
- Basic Linux command line knowledge

## Project Structure

```
.
├── main.tf                    # Root module configuration
├── variables.tf               # Root variable definitions
├── terraform.tfvars          # Variable values (customize this)
├── terraform.tfvars.example  # Example configuration
├── modules/
│   ├── compute/              # EC2 instances, NICs, EIPs
│   │   ├── main.tf
│   │   ├── variable.tf
│   │   └── output.tf
│   ├── efs/                  # EFS file system and mount targets
│   │   ├── main.tf
│   │   ├── variable.tf
│   │   └── output.tf
│   ├── network/              # VPC, subnets, routing, IGW
│   │   ├── main.tf
│   │   ├── variable.tf
│   │   └── output.tf
│   └── security/             # Security groups
│       ├── main.tf
│       ├── variable.tf
│       └── output.tf
└── README.md
```

## Getting Started

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd aws-efs-project
```

### 2. Configure Variables

Copy the example configuration and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your desired values:

```hcl
project_name  = "efs-terraform-project"
environment   = "development"
cidr_block    = "192.168.0.0/16"
subnet_az_a   = "192.168.10.0/24"
subnet_az_b   = "192.168.20.0/24"
ami_id        = "ami-054b7fc3c333ac6d2"  # Amazon Linux 2023 (us-west-2)
instance_type = "t3.micro"
```

> **Note:** To find the latest AMI ID for your region:
> ```bash
> aws ec2 describe-images \
>   --owners amazon \
>   --filters "Name=name,Values=al2023-ami-*" \
>   --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
>   --output text
> ```

### 3. Initialize Terraform

```bash
terraform init
```

This downloads required provider plugins and initializes the backend.

### 4. Review the Execution Plan

```bash
terraform plan
```

Review the resources that will be created. Ensure everything looks correct before proceeding.

### 5. Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm deployment.

Alternatively, auto-approve for CI/CD pipelines:
```bash
terraform apply --auto-approve
```

### 6. Verify Deployment

After successful deployment, verify EFS is mounted on instances:

**Connect via SSM Session Manager:**
```bash
aws ssm start-session --target <instance-id>
```

**Check EFS mount:**
```bash
# Verify mount
df -h | grep terraform-efs

# List files
ls -la /terraform-efs

# View test files
cat /terraform-efs/testfile.txt
```

## Features

### Multi-AZ High Availability
- Resources distributed across two availability zones
- EFS automatically replicates data across AZs
- Instances can access shared storage even if one AZ fails

### Automated Configuration
- **SSM Agent** automatically installed for secure shell access
- **EFS utilities** pre-installed on instances
- **EFS automatically mounted** at `/terraform-efs` on boot
- Retry logic for network-dependent operations

### Security
- Security groups restrict NFS traffic to VPC CIDR
- SSM Session Manager for secure instance access (no SSH keys needed)
- TLS encryption for EFS mounts
- Private subnet instances with NAT-free internet via EIPs

### Monitoring and Debugging
- Comprehensive logging in `/var/log/user-data.log`
- Cloud-init output in `/var/log/cloud-init-output.log`
- Verbose mount debugging available

## Usage Examples

### Test Shared Storage

**On instance in AZ-A:**
```bash
echo "Hello from AZ-A" | sudo tee /terraform-efs/shared-file.txt
```

**On instance in AZ-B:**
```bash
cat /terraform-efs/shared-file.txt
# Output: Hello from AZ-A
```

### Persistent Mount Configuration

The user_data script mounts EFS on boot. For persistent mounts across reboots, add to `/etc/fstab`:

```bash
echo "<EFS-ID>:/ /terraform-efs efs _netdev,tls,iam 0 0" | sudo tee -a /etc/fstab
```

## Troubleshooting

### EFS Not Mounting

**Check user-data logs:**
```bash
sudo cat /var/log/user-data.log
sudo cat /var/log/cloud-init-output.log | grep -i efs
```

**Verify DNS resolution:**
```bash
nslookup <efs-id>.efs.us-west-2.amazonaws.com
```

**Check security group:**
```bash
# Ensure port 2049 is open from VPC CIDR
aws ec2 describe-security-groups --group-ids <sg-id>
```

**Manual mount attempt:**
```bash
sudo mount -t efs -o tls,verbose <efs-id>:/ /terraform-efs
```

### Instance Not Accessible

**SSM Agent status:**
```bash
sudo systemctl status amazon-ssm-agent
```

**Restart SSM Agent:**
```bash
sudo systemctl restart amazon-ssm-agent
```

### Terraform State Issues

**Refresh state:**
```bash
terraform refresh
```

**View current state:**
```bash
terraform show
```

## Cost Considerations

Estimated monthly costs (us-west-2):
- **EC2 (2x t3.micro):** ~$15/month
- **EFS (First 50GB):** ~$7.50/month (Standard storage class)
- **Elastic IPs (associated):** Free
- **Data transfer:** Variable

> **Tip:** Use `terraform destroy` when not in use to avoid unnecessary charges.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will remove:
- EC2 instances and associated resources
- EFS file system and mount targets
- VPC and networking components
- Security groups

> **Warning:** This action is irreversible and will delete all data in the EFS file system.

## Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_name` | Name prefix for resources | - | Yes |
| `environment` | Environment (dev/staging/prod) | - | Yes |
| `cidr_block` | VPC CIDR block | - | Yes |
| `subnet_az_a` | Subnet CIDR for AZ-A | - | Yes |
| `subnet_az_b` | Subnet CIDR for AZ-B | - | Yes |
| `ami_id` | EC2 AMI ID (Amazon Linux 2023) | - | Yes |
| `instance_type` | EC2 instance type | `t3.micro` | Yes |

## Outputs

After deployment, Terraform provides:
- VPC ID
- Subnet IDs
- Instance IDs
- EFS File System ID
- Security Group IDs
- Elastic IP addresses

View outputs:
```bash
terraform output
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Open an issue in the GitHub repository
- Check AWS documentation for service-specific issues
- Review Terraform documentation for configuration questions

## Additional Resources

- [AWS EFS Documentation](https://docs.aws.amazon.com/efs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Amazon Linux 2023 User Guide](https://docs.aws.amazon.com/linux/al2023/)

---

**Built using Terraform and AWS**
