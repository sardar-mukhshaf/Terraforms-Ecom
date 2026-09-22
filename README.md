# Terraform E-Commerce Infrastructure

Production-grade Terraform for running an e-commerce platform on AWS: EKS for compute, RDS PostgreSQL for data, S3 + ECR for storage and images, ALB for ingress, and CloudWatch for observability. Two fully separated environments (prod, dev), eight reusable modules, remote state with locking.

## Why this exists

Most "e-commerce on AWS" tutorials stop at a single EC2 instance or a manually clicked-through console setup. This repo is the opposite: it's what the infrastructure looks like once you actually need it to survive an AZ failure, scale under a traffic spike, and be reproducible by someone other than the person who built it.

It exists to answer three questions concretely, in code rather than in a diagram:

- **How do you run a stateful e-commerce workload on Kubernetes without losing data?** Multi-AZ RDS, encrypted EBS, S3 with versioning.
- **How do you keep prod and dev from ever touching each other?** Separate state backends, separate variable files, separate account or region — no shared resources, no "temporarily pointed at prod" mistakes.
- **How do you make this deployable by someone who didn't write it?** Every module takes explicit variables, every environment has a `terraform.tfvars.example`, and every destructive command is called out before you run it.

It is a reference implementation, not a finished product — you're expected to adapt sizing, regions, and security groups to your own traffic and compliance requirements before running it against a real production account.

---

## Architecture

```
Internet
   │
   ▼
Route 53 (DNS) → CloudFront (optional, static assets)
   │
   ▼
Application Load Balancer (HTTP/HTTPS, path-based routing)
   │
   ▼
┌─────────────────────────── VPC (10.10.0.0/16) ───────────────────────────┐
│                                                                            │
│  EKS cluster, 3 AZs                                                       │
│    Public subnets:  IGW, NAT Gateway (per AZ)                             │
│    Private subnets: EKS worker nodes (t3.medium, autoscaling 2–8)         │
│                                                                            │
│  Data tier (private subnets)                                              │
│    RDS PostgreSQL — Multi-AZ, automated backups, encrypted at rest        │
│    ECR — private image registry, scan-on-push                            │
│    S3 — versioned, encrypted, public access blocked                       │
│                                                                            │
│  Observability                                                            │
│    CloudWatch Logs/Metrics/Alarms, 30-day retention (prod)                │
│    CloudTrail audit logging                                               │
│    Secrets Manager for DB credentials                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

| Component | Role | HA strategy |
|---|---|---|
| VPC | Network isolation | Multi-AZ subnets, separate CIDRs per env |
| ALB | Ingress, TLS termination | Health-checked target groups |
| EKS | Container orchestration | Managed control plane, autoscaling node groups |
| RDS PostgreSQL | Primary datastore | Multi-AZ failover (prod), automated backups |
| ECR | Image registry | Regional, vulnerability scanning on push |
| S3 | Object/asset storage | Versioning, optional cross-region replication |
| CloudWatch | Logs & metrics | 30-day retention (prod), 3-day (dev) |
| IAM | Access control | Least-privilege roles + GitHub OIDC federation |

---

## Repository structure

```
.
├── modules/                # 8 reusable modules — no environment-specific values
│   ├── vpc/                 # Subnets, IGW, NAT, route tables, flow logs
│   ├── iam/                 # EKS roles, GitHub OIDC provider, CI/CD role
│   ├── eks/                 # Cluster, node groups, add-ons (VPC CNI, CoreDNS)
│   ├── rds/                 # PostgreSQL instance, subnet group, parameter group
│   ├── ecr/                 # Private registry, lifecycle policy
│   ├── s3/                  # Buckets, versioning, encryption, CORS
│   ├── alb/                 # Load balancer, listeners, target groups
│   └── cloudwatch/          # Log groups, alarms, retention
│
├── envs/
│   ├── prod/                # 3 AZs, multi-AZ RDS, private EKS endpoint, HA node counts
│   └── dev/                 # 2 AZs, single-AZ RDS, public EKS endpoint, minimal nodes
│
├── versions.tf              # Provider version constraints
├── variables.tf             # Global variables and locals
└── outputs.tf                # Root-level outputs
```

Each module has `main.tf`, `variables.tf`, `outputs.tf` and nothing environment-specific — all per-environment values live in `envs/*/terraform.tfvars`.

---

## Prerequisites

```bash
terraform --version   # >= 1.3.0
aws --version          # >= 2.0
kubectl version --client   # >= 1.27
aws sts get-caller-identity   # confirms your credentials are active
```

Your IAM user/role needs permissions for: EC2/VPC/Security Groups, EKS, IAM, RDS, ECR, S3, CloudWatch, DynamoDB, Auto Scaling.

**For CI/CD (optional):** a GitHub repo and its OIDC thumbprint —

```bash
curl -s https://token.actions.githubusercontent.com/.well-known/openid-configuration \
  | jq -r '.jwks_uri | split("/")[2]' \
  | xargs -I {} openssl s_client -connect {}:443 -showcerts < /dev/null 2>/dev/null \
  | openssl x509 -fingerprint -noout | tr -d ':' | tr A-F a-f | cut -d= -f2
```

---

## Deploying

### 1. Create the state backend (one time)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="ecom-tfstate-$ACCOUNT_ID"

aws s3api create-bucket --bucket "$BUCKET" --region us-east-1
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name ecom-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 2. Configure the environment

```bash
cd envs/prod
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — every value marked `REPLACE_ME` must change before you apply:

```hcl
aws_region             = "us-east-1"
availability_zones     = ["us-east-1a", "us-east-1b", "us-east-1c"]
cluster_name           = "ecom-prod-eks"
db_master_password     = "REPLACE_ME"          # 32+ chars, or pull from Secrets Manager — see Security
assets_bucket_name     = "ecom-assets-prod-<account-id>"   # must be globally unique
github_repo            = "your-org/your-repo"
github_oidc_thumbprint = "REPLACE_ME"
```

### 3. Plan and apply

```bash
terraform init
terraform validate
terraform plan -out=tfplan   # read this output — check instance types, security groups, backup settings
terraform apply tfplan       # provisions real AWS resources; prod takes 25–45 minutes
```

### 4. Connect and verify

```bash
aws eks update-kubeconfig --name "$(terraform output -raw eks_cluster_name)" \
  --region "$(terraform output -raw aws_region)"
kubectl cluster-info
kubectl get nodes

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl create namespace ecommerce
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password="$(terraform output -raw db_master_password)" \
  -n ecommerce
```

### 5. Push and deploy the application image

```bash
aws ecr get-login-password --region "$(terraform output -raw aws_region)" \
  | docker login --username AWS --password-stdin \
    "$(terraform output -raw ecr_registry_id).dkr.ecr.$(terraform output -raw aws_region).amazonaws.com"

docker build -t ecommerce-app:v1.0.0 .
REPO_URL=$(terraform output -raw ecr_repository_url)
docker tag ecommerce-app:v1.0.0 "$REPO_URL:v1.0.0"
docker push "$REPO_URL:v1.0.0"

kubectl apply -f deployment.yaml   # your Deployment/Service/Ingress manifests
```

Dev follows the same steps from `envs/dev/`, with smaller instance sizes and a single-AZ database.

---

## Configuration reference

| Variable | Type | Prod default | Dev default |
|---|---|---|---|
| `vpc_cidr` | string | `10.10.0.0/16` | `10.20.0.0/16` |
| `eks_desired_nodes` / `min` / `max` | number | 3 / 2 / 8 | 1 / 1 / 2 |
| `eks_instance_type` | string | `t3.medium` | `t3.small` |
| `db_instance_class` | string | `db.m5.large` | `db.t3.micro` |
| `multi_az` | bool | `true` | `false` |
| `backup_retention` | number | 30 days | 7 days |
| `endpoint_public_access` | bool | `false` (private) | `true` |
| `log_retention_days` | number | 30 | 3 |

---

## Security

**Secrets:** never commit `terraform.tfvars` with a real password. Pull it from AWS Secrets Manager instead:

```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "ecom/db/password"
}
```

**Network:** production EKS endpoint access should stay private, or restricted to known CIDRs:

```hcl
endpoint_public_access      = false
endpoint_public_access_cidrs = ["203.0.113.0/24"]  # your office/VPN range, if you need any public access at all
```

**What's already enforced by the modules:** RDS and S3 encryption at rest (KMS/AES-256), TLS 1.2+ in transit, private subnets for nodes and database, security groups scoped to least privilege, S3 public-access blocking, automated RDS backups with a defined window, CloudTrail logging.

**Before going to production, also do these yourself** — they're not automated here: enable GuardDuty, enable Security Hub, set up CloudWatch alarms for anomalous IAM/API activity, enforce MFA on console access, and rotate IAM credentials on a schedule.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `not authorized to perform: eks:CreateCluster` | IAM user lacks EKS permissions | Attach a policy covering EKS/EC2/IAM/RDS/ECR/S3 |
| `Error acquiring the state lock` | Concurrent apply, or a crashed run | Wait and retry; if stale, `terraform force-unlock <LOCK_ID>` |
| `x509: certificate has expired` on `kubectl` | Stale kubeconfig | `aws eks update-kubeconfig --name ... --region ...` |
| RDS connection timeout | Security group not open to the pod's subnet | Check `aws ec2 describe-security-groups`; test with a throwaway `psql` pod |
| ALB returns 503 | Unhealthy targets or missing ingress | `aws elbv2 describe-target-health`, `kubectl describe ingress -n ecommerce` |
| `terraform plan` hangs or times out | AWS API rate limiting, or network issue | Retry with `-parallelism=1`; check `ping api.terraform.io` |

Useful commands: `terraform state list`, `terraform state show <resource>`, `kubectl describe pod <pod> -n ecommerce`, `aws logs tail /aws/eks/<cluster>/cluster --follow`.

---

## Estimated cost

| | Prod | Dev |
|---|---|---|
| EKS nodes | t3.medium × 2–8 | t3.small × 1–2 |
| RDS | db.m5.large, Multi-AZ | db.t3.micro, single-AZ |
| Log retention | 30 days | 3 days |
| **Rough monthly total** | **~$500–600** | **~$170** |

These are compute/RDS/log estimates only — data transfer, NAT Gateway hours, and S3 storage will add to the total depending on traffic.

---

## Contributing

1. Branch from `main`, test in `envs/dev/` first.
2. `terraform fmt -recursive && terraform validate` before committing.
3. Mark any new customization point with `# REPLACE_ME` and document it in the variable's `description`.
4. PR description should state what changed and why, not just what.

---

## Disclaimer

This is a reference implementation. Review sizing, security group rules, and compliance requirements against your own organization's standards before pointing this at a real production AWS account.
