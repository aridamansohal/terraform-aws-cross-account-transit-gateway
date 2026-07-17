# 🚀 Terraform AWS Cross-Account Transit Gateway

> A production-style Terraform project demonstrating a **Cross-Account AWS Transit Gateway** implementation using reusable modules, Remote State, and AWS Resource Access Manager (RAM).

---

## 📖 Project Overview

This repository demonstrates how to build a scalable AWS network using **Terraform** and **AWS Transit Gateway** across multiple AWS accounts.

The project follows Infrastructure as Code (IaC) best practices by separating reusable Terraform modules from environment-specific root modules.

Key concepts covered include:

- Cross-Account AWS Transit Gateway
- AWS Resource Access Manager (RAM)
- Terraform Remote State
- Modular Terraform Design
- Reusable Child Modules
- Root Module Composition
- Cross-Account Networking
- Route Table Management
- Infrastructure Documentation

---

# ✨ Features

- ✅ Modular Terraform Architecture
- ✅ Cross-Account Transit Gateway
- ✅ AWS RAM Resource Sharing
- ✅ Terraform Remote State
- ✅ Reusable Modules
- ✅ Multi-Environment Deployment
- ✅ Private Networking
- ✅ VPC Endpoints
- ✅ EC2 Deployment
- ✅ IAM Instance Profiles
- ✅ Complete Documentation
- ✅ Troubleshooting Guide

---

# 🏗️ Architecture

> **Architecture diagram will be added in the next step.**

```text
                    AWS Organization

          +-------------------------------+
          |         DEV ACCOUNT           |
          |-------------------------------|
          |                               |
          |  VPC                          |
          |  EC2                          |
          |  Transit Gateway              |
          |  AWS RAM Share                |
          |                               |
          +---------------+---------------+
                          |
                 AWS RAM Share
                          |
                          |
          +---------------v---------------+
          |         PROD ACCOUNT          |
          |-------------------------------|
          |                               |
          |  VPC                          |
          |  EC2                          |
          |  TGW Attachment               |
          |                               |
          +-------------------------------+
```

---

# 📂 Repository Structure

```text
terraform-aws-cross-account-transit-gateway/

├── docs/
├── examples/
├── live/
│   ├── bootstrap/
│   ├── dev/
│   └── prod/
│
├── modules/
│   ├── ec2/
│   ├── iam-instance-profile/
│   ├── ram-share/
│   ├── ram-share-accepter/
│   ├── sg/
│   ├── tgw-attachment/
│   ├── transit-gateway/
│   ├── transit-gateway-routes/
│   ├── vpc/
│   └── vpc-endpoint/
│
├── README.md
├── LICENSE
└── .gitignore
```

---

# 🧩 Modules

| Module | Purpose |
|---------|---------|
| VPC | Creates networking infrastructure |
| Security Group | Creates Security Groups |
| IAM Instance Profile | Creates IAM Role & Instance Profile |
| EC2 | Deploys EC2 Instances |
| VPC Endpoint | Creates AWS VPC Endpoints |
| Transit Gateway | Creates AWS Transit Gateway |
| RAM Share | Shares Transit Gateway |
| RAM Share Accepter | Accepts RAM Share |
| TGW Attachment | Connects VPC to TGW |
| TGW Routes | Creates VPC Routes |

---

# 🚀 Deployment Workflow

```text
Bootstrap

↓

DEV Infrastructure

↓

Transit Gateway

↓

AWS RAM Share

↓

Remote State

↓

PROD Infrastructure

↓

Accept RAM Share

↓

TGW Attachment

↓

VPC Routes

↓

EC2 Communication
```
# 📁 Examples

This repository includes example Terraform configurations to help you understand the project at different levels of complexity.

| Example | Description | Status |
|----------|-------------|--------|
| `minimal/` | Deploys a minimal AWS environment demonstrating the core Terraform module structure. | 🚧 Planned |
| `single-account/` | Deploys the infrastructure into a single AWS account for learning and testing. | 🚧 Planned |
| `cross-account/` | Deploys the complete DEV ↔ PROD architecture using AWS Transit Gateway, AWS RAM, and Terraform Remote State. | 🚧 Planned |

> These examples will be added in future updates as the repository evolves.
---

# 📚 Documentation

## Project Guides

| Chapter | Description |
|----------|-------------|
| 01 | AWS Architecture |
| 02 | Deployment SOP |
| 03 | Terraform Thinking |
| 04 | Understanding for_each |
| 05 | Maps, Lookups & Outputs |
| 06 | Root vs Child Modules |
| 07 | Terraform Remote State |
| 08 | Transit Gateway |
| 09 | AWS RAM |
| 10 | Cross-Account TGW |
| 11 | Routing |
| 12 | Troubleshooting |
| 13 | Terraform Design Patterns |
| 14 | Lessons Learned |

---

# 🧠 What I Learned

During this project I learned:

- Building reusable Terraform modules
- Root Module orchestration
- Child Module design
- Cross-account networking
- Terraform Remote State
- AWS Transit Gateway
- AWS RAM
- Route Tables
- Packet Flow
- Infrastructure Design
- Infrastructure Documentation

---

# 🎯 Technologies Used

- Terraform
- AWS EC2
- AWS VPC
- AWS Transit Gateway
- AWS RAM
- AWS IAM
- AWS Systems Manager
- AWS VPC Endpoints
- Amazon S3
- DynamoDB

---

# 📈 Future Improvements

Planned enhancements:

- Multi-Region Transit Gateway
- AWS Network Firewall
- Direct Connect Gateway
- Site-to-Site VPN
- GitHub Actions CI/CD
- Automated Testing
- Policy as Code
- Landing Zone Integration

---

# 🤝 Contributing

Contributions are welcome.

Feel free to:

- Open an Issue
- Submit a Pull Request
- Suggest Improvements
- Report Bugs

---

# 📄 License

This project is licensed under the MIT License.

---

# ⭐ Acknowledgements

This project was created as a hands-on learning project to understand:

- Terraform Module Design
- Infrastructure as Code
- AWS Networking
- Cross-Account Architectures
- Production-style Terraform Repository Structure
