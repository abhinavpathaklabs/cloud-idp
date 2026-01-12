<div align="center">

<img src="docs/images/banner.png" alt="Cloud IDP Banner" width="100%"/>

# 🚀 Cloud IDP — Self-Service DevOps Platform (IDP)

### Terraform • AWS • Jenkins • Docker • Kubernetes (EKS) • Helm • Trivy

<br/>

<p>
  <img alt="Terraform" src="https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" />
  <img alt="AWS" src="https://img.shields.io/badge/AWS-Cloud-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white" />
  <img alt="Jenkins" src="https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white" />
  <img alt="Kubernetes" src="https://img.shields.io/badge/EKS-Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" />
  <img alt="Docker" src="https://img.shields.io/badge/Docker-Containers-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img alt="Helm" src="https://img.shields.io/badge/Helm-Packaging-0F1689?style=for-the-badge&logo=helm&logoColor=white" />
</p>

<p>
  <img alt="Status" src="https://img.shields.io/badge/Status-Active-success?style=flat-square" />
  <img alt="Scope" src="https://img.shields.io/badge/Scope-MVP_IDP-informational?style=flat-square" />
  <img alt="Region" src="https://img.shields.io/badge/Region-us--east--1-blue?style=flat-square" />
</p>

<br/>

> **Cloud IDP** is a mini **Internal Developer Platform** that gives developers a **self-service workflow** to:
> ✅ provision an isolated environment for a service
> ✅ build/scan/push container images
> ✅ deploy to Kubernetes on **EKS** using **Helm**
> — all through Jenkins jobs (no “DevOps tickets”).

</div>

---

## 🔥 What we are doing (high-level)

We are building an **IDP (Internal Developer Platform)** where:

* **Jenkins is the “portal/UI”** that developers use.
* **Terraform is the platform engine** that provisions AWS + Kubernetes resources.
* **EKS is the runtime** that actually runs the workloads.
* **ECR stores container images**.
* **Secrets Manager stores secrets**.
* **S3 + DynamoDB provide Terraform remote state + locking** (real-world best practice).

**Two self-service actions:**

1. `create-env` → creates **namespace + quotas + ECR repo + Secrets Manager secret** per service/env
2. `deploy-service` → **Docker build → Trivy scan → push to ECR → Helm deploy to EKS**

---

## 🤔 Why we are doing this (the problem it solves)

In many teams, developers raise tickets like:

* “Create a Kubernetes namespace”
* “Create an ECR repo”
* “Add secrets”
* “Give a CI/CD pipeline”
* “Deploy to dev”

This creates delay and inconsistency.

**This project replaces ticket-based DevOps with self-service**:

* Standardized environments (repeatable)
* Standardized deployments (repeatable)
* Security scanning built-in
* Isolation per service/env using namespaces
* “Click a button” experience in Jenkins

---


Pipeline flow:
1. Checkout source code
2. Build Docker image
3. Scan image with Trivy (security gate)
4. Push image to ECR
5. Deploy/update application using Helm in EKS

👉 Result: a running service inside the correct namespace.

---

### 🔗 6. How Everything Connects (Mental Model)

- **GitHub** → defines *what should exist*
- **Jenkins** → executes *how it should happen*
- **Terraform** → provisions *infrastructure and environments*
- **EKS** → runs *applications*
- **ECR** → stores *container images*
- **S3 + DynamoDB** → store Terraform’s memory (state + lock)
- **SSM** → shares cluster metadata between stacks

> 🧠 **Quick mental model:**  
> **Jenkins = Portal** · **Terraform = Engine** · **EKS = Runtime**

---

### ✅ Why this architecture stands out

- Eliminates ticket-based DevOps
- Enforces standardization across teams
- Scales with number of services
- Secure by design (no static credentials)
- Mirrors real-world platform engineering patterns

This is not just CI/CD — it is a **self-service platform**.

```
SERVICE_NAME=payments
ENV=dev
```


This job provisions everything required for a service to exist:
- Kubernetes namespace → `dev-payments`
- ResourceQuota + LimitRange → governance
- ECR repository → `payments-dev`
- Secrets Manager secret → `dev/payments/app`

👉 Result: the environment is **ready before any deployment happens**.

---

#### 🚢 B. `deploy-service` — CI/CD Deployment

Triggered with:

```
SERVICE_NAME=payments
ENV=dev
```

Pipeline flow:
1. Checkout source code
2. Build Docker image
3. Scan image with Trivy (security gate)
4. Push image to ECR
5. Deploy/update application using Helm in EKS

👉 Result: a running service inside the correct namespace.

---

### 🔗 6. How Everything Connects (Mental Model)

- **GitHub** → defines *what should exist*
- **Jenkins** → executes *how it should happen*
- **Terraform** → provisions *infrastructure and environments*
- **EKS** → runs *applications*
- **ECR** → stores *container images*
- **S3 + DynamoDB** → store Terraform’s memory (state + lock)
- **SSM** → shares cluster metadata between stacks

> 🧠 **Quick mental model:**  
> **Jenkins = Portal** · **Terraform = Engine** · **EKS = Runtime**

---

### ✅ Why this architecture stands out

- Eliminates ticket-based DevOps
- Enforces standardization across teams
- Scales with number of services
- Secure by design (no static credentials)
- Mirrors real-world platform engineering patterns

This is not just CI/CD — it is a **self-service platform**.



---

## 🧱 Repo structure (what each folder means)

```
infra/terraform/bootstrap/   # creates S3 bucket + DynamoDB lock table
infra/terraform/platform/    # VPC + EKS + Jenkins EC2 + addons (Helm)
infra/terraform/service-env/ # per service/env (namespace/ECR/secrets/quotas)

jenkins/                     # Jenkins pipelines (Jenkinsfiles)
deploy/helm/sample-service/  # Helm chart used by deploy pipeline
scripts/                     # 0→hero scripts + teardown scripts
docs/images/                 # screenshots/diagrams/banner
```

---

## ✅ Prerequisites (before you start)

### Tools

* Terraform `>= 1.6`
* AWS CLI configured (run `aws sts get-caller-identity`)
* Git

### AWS permissions

For personal projects, easiest is to use an admin-like IAM user/role.
(For production: least privilege.)

### Network access

Jenkins is exposed on EC2 port `8080`.
You must allow your **public IP/CIDR**.

---

# 🦸 0 → Hero: Full Setup (step-by-step)

> 🗺️ **Region:** `us-east-1`
> 🧪 **Environment:** `dev`
> 🔐 **Access:** Jenkins UI open only to your IP (`ALLOWED_CIDR`)

---

## Step 0) Clone the repo

```bash
git clone https://github.com/abhinavpathaklabs/cloud-idp.git
cd cloud-idp
```

---

## Step 1) Export required environment variables

### 1.1 Get your public IP

```bash
curl -s ifconfig.me
```

### 1.2 Export env vars (REQUIRED)

```bash
export AWS_REGION="us-east-1"
export ALLOWED_CIDR="YOUR_PUBLIC_IP/32"
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"
export REPO_URL="https://github.com/abhinavpathaklabs/cloud-idp.git"
export REPO_BRANCH="main"
```

✅ What these do:

* `ALLOWED_CIDR` → restrict Jenkins/SSH access to you only
* `SSH_PUBLIC_KEY` → allows SSH into EC2 (optional but recommended)
* `REPO_URL` / `REPO_BRANCH` → Jenkins loads pipelines from GitHub

---

## Step 2) Bootstrap Terraform backend (S3 state + DynamoDB lock)

This is required because Terraform cannot store state in S3 if S3 doesn’t exist yet.

```bash
bash scripts/01_bootstrap.sh
```

It prints outputs. Export them:

```bash
export TF_STATE_BUCKET="cloud-idp-tfstate-<ACCOUNT_ID>"
export TF_LOCK_TABLE="cloud-idp-tflock"
```

---

## Step 3) Provision the platform (VPC + EKS + Jenkins)

```bash
bash scripts/02_apply_platform.sh
```

This creates:

* VPC (public/private subnets + NAT)
* EKS cluster + managed node group
* Jenkins EC2 instance (Dockerized Jenkins)
* Addons via Helm (metrics-server, external-secrets)
* SSM params for cluster info

### Output you get at the end

Terraform prints:

* `jenkins_url` → open in browser
* `jenkins_admin_password` → login

**Username:** `admin`

---

## Step 4) Open Jenkins

Open:

* `http://<JENKINS_PUBLIC_IP>:8080`

Expected Jenkins jobs (already created automatically):

* ✅ `create-env`
* ✅ `deploy-service`

📸 Suggested screenshot: `docs/images/jenkins-jobs.png`

---

# 🎬 Demo: What to click in Jenkins (real platform demo)

## Demo 1: Create a service environment (Self-Service)

This job provisions the environment for a service using Terraform.

**Jenkins → create-env → Build with Parameters**

* `SERVICE_NAME=payments`
* `ENV=dev`
* `ACTION=apply`

✅ What gets created:

* Namespace: `dev-payments`
* ResourceQuota + LimitRange (governance)
* ECR repo: `payments-dev`
* Secrets Manager secret: `dev/payments/app`

Verify (optional):

```bash
kubectl get ns | grep dev-payments
```

---

## Demo 2: Deploy service (CI/CD)

This job builds + scans + pushes + deploys.

**Jenkins → deploy-service → Build with Parameters**

* `SERVICE_NAME=payments`
* `ENV=dev`
* `IMAGE_TAG=` (leave blank)

Pipeline stages:

1. Checkout repo
2. Read ECR repo URL from Terraform output (state-driven, no hardcoding)
3. Docker build
4. Trivy scan
5. Push to ECR
6. Deploy to EKS via Helm
7. Smoke check

Verify:

```bash
kubectl -n dev-payments get pods
kubectl -n dev-payments get svc
kubectl -n dev-payments get ingress
```

📸 Suggested screenshot: `docs/images/pipeline-run.png`

---

# 🔍 How it works: Code flow (what each part does)

## 1) `infra/terraform/bootstrap/` — Backend foundation

**File:** `infra/terraform/bootstrap/main.tf`

Creates:

* `aws_s3_bucket` → Terraform remote state store
* `aws_dynamodb_table` → state lock table

Why:

* Prevents corrupted Terraform state
* Enables teamwork and automation

---

## 2) `infra/terraform/platform/` — Platform resources

**Key pieces:**

* `module "vpc"` → networking
* `module "eks"` → Kubernetes cluster
* `aws_instance "jenkins"` → Jenkins EC2
* `helm_release` → installs cluster addons
* `aws_ssm_parameter` → writes cluster info to SSM

### Jenkins automation (the heart)

**File:** `infra/terraform/platform/userdata.sh.tpl`

At instance boot it:

* Installs: docker, awscli, terraform, kubectl, helm, trivy
* Starts Jenkins as a Docker container
* Uses JCasC to:

  * create admin user
  * create pipeline jobs
  * set global env vars (TF backend values)

This is why Jenkins is ready immediately (no manual clicks).

---

## 3) `infra/terraform/service-env/` — Per service/env resources

**Goal:** create isolated environments (dev-payments, dev-orders, etc.)

Creates:

* Kubernetes namespace + quotas
* ECR repo per service/env
* Secrets Manager secret per service/env

**State key per service**:

* `services/dev/payments.tfstate`

This is what makes the platform scale: each service can be managed independently.

---

## 4) Jenkins pipelines

### `jenkins/Jenkinsfile-create-env`

* runs Terraform `apply/destroy` for service-env stack
* produces namespace/ECR/secrets automatically

### `jenkins/Jenkinsfile-deploy-service`

* reads environment outputs from Terraform state
* builds/scans/pushes image to ECR
* deploys via Helm into correct namespace

---

# 🔐 Security & Best Practices (what makes it “real”)

✅ **Remote state + locking** (S3 + DynamoDB)
✅ **No AWS keys stored in Jenkins** (EC2 instance profile)
✅ **Namespace isolation** for each service/env
✅ **Quotas & limits** enforce fair usage
✅ **Image security scanning** using Trivy
✅ **Clean Git hygiene** using `.gitignore` + `.tfignore`

---

# 🧨 Teardown / Destroy (automated, correct order)

To avoid AWS costs, teardown is scripted in reverse dependency order.

### Destroy everything (recommended)

```bash
export TF_STATE_BUCKET="..."
export TF_LOCK_TABLE="..."
bash scripts/00_destroy_all.sh
```

### Optional: destroy Terraform backend last (wipe everything)

```bash
bash scripts/99_destroy_bootstrap.sh
```

---

# 🛠️ Troubleshooting

<details>
<summary><b>Jenkins UI not opening on :8080</b></summary>

* Check `ALLOWED_CIDR` is correct: `curl -s ifconfig.me`
* Ensure inbound rules allow TCP 8080 from your IP/32
* First boot can take a few minutes (docker pull + plugins)

</details>

<details>
<summary><b>EKS cluster read error during apply (eventual consistency)</b></summary>

Apply in two steps:

```bash
terraform apply -auto-approve -target=module.vpc -target=module.eks
terraform apply -auto-approve
```

</details>

<details>
<summary><b>Ingress has no external address</b></summary>

You need AWS Load Balancer Controller for ALB ingress.
(Planned in advanced roadmap.)

</details>

---

## 📝 License

MIT (or update as needed)
