#!/bin/bash
set -euo pipefail

# -----------------------------
# Values injected by Terraform templatefile()
# -----------------------------
ADMIN_USER="${admin_user}"
ADMIN_PASSWORD="${admin_password}"
REPO_URL="${repo_url}"
REPO_BRANCH="${repo_branch}"

PROJECT="${project}"
ENV_NAME="${env}"
AWS_REGION="${region}"

# OPTIONAL (recommended): inject backend values into Jenkins jobs
# (Only works if you pass these in templatefile(...) vars map from main.tf)
TF_STATE_BUCKET="${tf_state_bucket}"
TF_LOCK_TABLE="${tf_lock_table}"

# -----------------------------
# Base packages
# -----------------------------
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release unzip git jq

# -----------------------------
# Docker
# -----------------------------
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# -----------------------------
# AWS CLI v2
# -----------------------------
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# -----------------------------
# Terraform (HashiCorp apt)
# -----------------------------
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y terraform

# -----------------------------
# kubectl
# -----------------------------
curl -fsSL https://dl.k8s.io/release/stable.txt -o /tmp/k8s_stable.txt
KVER=$(cat /tmp/k8s_stable.txt)
curl -fsSL "https://dl.k8s.io/release/$KVER/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# -----------------------------
# helm
# -----------------------------
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -----------------------------
# trivy (scanner)
# -----------------------------
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/trivy.list
apt-get update -y
apt-get install -y trivy

# -----------------------------
# Jenkins setup
# -----------------------------
mkdir -p /opt/jenkins

# plugins.txt (no variable expansion)
cat > /opt/jenkins/plugins.txt <<'EOF'
configuration-as-code
job-dsl
git
workflow-aggregator
credentials-binding
timestamper
ansiColor
EOF

# JCasC config + Job DSL
cat > /opt/jenkins/casc.yaml <<EOF
jenkins:
  systemMessage: "Cloud IDP Jenkins (Terraform + EKS + Self-service)"
  numExecutors: 2

  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "$ADMIN_USER"
          password: "$ADMIN_PASSWORD"

  authorizationStrategy:
    loggedInUsersCanDoAnything:
      allowAnonymousRead: false

  globalNodeProperties:
    - envVars:
        env:
          - key: "TF_STATE_BUCKET"
            value: "$TF_STATE_BUCKET"
          - key: "TF_LOCK_TABLE"
            value: "$TF_LOCK_TABLE"
          - key: "AWS_REGION"
            value: "$AWS_REGION"
          - key: "PROJECT"
            value: "$PROJECT"
          - key: "ENV_NAME"
            value: "$ENV_NAME"

unclassified:
  location:
    url: "http://$JENKINS_PUBLIC_HOST:8080/"

jobs:
  - script: >
      pipelineJob('create-env') {
        definition {
          cpsScm {
            scm {
              git {
                remote { url('$REPO_URL') }
                branches('*/$REPO_BRANCH')
              }
            }
            scriptPath('jenkins/Jenkinsfile-create-env')
          }
        }
      }

  - script: >
      pipelineJob('deploy-service') {
        definition {
          cpsScm {
            scm {
              git {
                remote { url('$REPO_URL') }
                branches('*/$REPO_BRANCH')
              }
            }
            scriptPath('jenkins/Jenkinsfile-deploy-service')
          }
        }
      }
EOF

# Prepare Jenkins home
mkdir -p /opt/jenkins/home

# Install plugins into Jenkins home (one-shot)
docker run --rm \
  -v /opt/jenkins/home:/var/jenkins_home \
  -v /opt/jenkins/plugins.txt:/plugins.txt \
  jenkins/jenkins:lts-jdk17 \
  bash -lc "jenkins-plugin-cli --plugin-file /plugins.txt --plugin-dir /var/jenkins_home/plugins"

# Run Jenkins container
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

docker rm -f jenkins || true
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v /opt/jenkins/home:/var/jenkins_home \
  -v /opt/jenkins/casc.yaml:/var/jenkins_home/casc.yaml \
  -e CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml \
  -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
  -e JENKINS_PUBLIC_HOST="$PUBLIC_IP" \
  jenkins/jenkins:lts-jdk17

echo "Jenkins started. URL: http://$PUBLIC_IP:8080  user: $ADMIN_USER"
