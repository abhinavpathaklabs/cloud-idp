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

🧠 Architecture (clear + readable)

Cloud IDP is a mini Internal Developer Platform (IDP) built with a clear separation between a control plane (where automation happens) and a runtime plane (where applications run).

1) Source of truth: GitHub

Everything lives in one GitHub repo:

Terraform code to create AWS infrastructure and service environments

Jenkinsfiles that define the self-service pipelines (create-env, deploy-service)

Helm chart used to deploy a sample service to Kubernetes

GitHub is the single place where platform changes are reviewed and versioned.

2) Control plane: Jenkins on EC2

Jenkins runs on an EC2 instance (inside Docker) and acts as the self-service portal:

Developers interact only with Jenkins (click jobs + provide parameters)

Jenkins pulls pipeline code from GitHub

Jenkins executes the automation steps:

runs Terraform to provision infrastructure/environment resources

runs Docker to build container images

runs Trivy to scan images for vulnerabilities

runs Helm/kubectl to deploy to Kubernetes

Jenkins is pre-configured using JCasC (Jenkins Configuration as Code) so it comes up ready without manual setup.

3) Platform infrastructure: AWS (created by Terraform)

Terraform provisions the shared platform components:

S3 + DynamoDB for Terraform remote state + state locking

VPC networking (public/private subnets, NAT)

EKS cluster (Kubernetes control plane) and managed node group (worker nodes)

IAM roles/policies so Jenkins can call AWS APIs safely using an instance profile

SSM Parameter Store to publish cluster metadata (like cluster name / OIDC ARN) for other stacks to read

This makes the platform reproducible and safe to automate.

4) Runtime plane: EKS (Kubernetes)

EKS is where applications actually run. The platform uses a consistent model:

Each service/environment gets its own namespace (example: dev-payments)

Deployments are done via Helm, producing standard Kubernetes objects:

Deployment

Service

(Optional) Ingress

This gives isolation, repeatability, and a clean “service boundary” per namespace.

5) Two self-service workflows

Cloud IDP exposes two “buttons” in Jenkins:

A) create-env (Provision an environment)
When triggered with SERVICE_NAME=payments, ENV=dev, it provisions:

Kubernetes namespace dev-payments

ResourceQuota + LimitRange (governance)

ECR repository for container images (payments-dev)

Secrets Manager secret for the service (dev/payments/app)

B) deploy-service (Build and deploy a service)
When triggered with SERVICE_NAME=payments, ENV=dev, it:

Builds a Docker image from the repo

Scans it with Trivy (security gate)

Pushes the image to ECR

Deploys/updates the service in dev-payments using Helm

6) How everything is connected

GitHub stores the definitions (IaC + pipelines + Helm)

Jenkins is the execution engine and self-service interface

Terraform creates and updates AWS + Kubernetes resources

EKS runs the workloads

ECR stores images built by Jenkins

S3/DynamoDB store Terraform state so automation is safe and consistent

SSM stores cluster metadata so different Terraform stacks can integrate cleanly

In simple terms:
Jenkins is the portal, Terraform is the engine, EKS is the runtime.



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
