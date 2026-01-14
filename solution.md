# AWS IaC with Terraform: Application Load Balancer with Auto Scaling

![Terraform](https://img.shields.io/badge/Terraform-1.5.7+-623CE4?style=flat&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20ALB%20%7C%20ASG-FF9900?style=flat&logo=amazon-aws)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Guia Passo a Passo](#-guia-passo-a-passo)
- [Recursos Criados](#-recursos-criados)
- [Explicação dos Arquivos](#-explicação-dos-arquivos)
- [Comandos Úteis](#-comandos-úteis)
- [Troubleshooting](#-troubleshooting)
- [Limpeza](#-limpeza)
- [Boas Práticas](#-boas-práticas)

---

## 🎯 Visão Geral

Este projeto implementa uma infraestrutura completa na AWS usando Terraform como Infrastructure as Code (IaC). A solução consiste em:

- **Application Load Balancer (ALB)** para distribuição de tráfego
- **Auto Scaling Group (ASG)** para gerenciamento automático de instâncias EC2
- **Launch Template** com script de inicialização personalizado
- **Integração com recursos pré-existentes** (VPC, Security Groups, IAM)

### 🎓 Objetivos de Aprendizado

- Entender conceitos de IaC com Terraform
- Configurar recursos AWS de forma programática
- Implementar alta disponibilidade e escalabilidade
- Aplicar boas práticas de versionamento e segurança

---

## 🏗️ Arquitetura

```
                        Internet
                           |
                           ↓
                  [Application Load Balancer]
                   (cmtr-k5vl9gpq-sglb)
                           |
                    ┌──────┴──────┐
                    ↓             ↓
              [Target Group]      |
                    |             |
        ┌───────────┴───────────┐ |
        ↓                       ↓ ↓
   [EC2 Instance 1]      [EC2 Instance 2]
   (Auto Scaling Group)
   - t3.micro
   - Apache HTTP Server
   - User Data Script
```

### Componentes:

1. **VPC**: `cmtr-k5vl9gpq-vpc` (pré-existente)
2. **Subnets Públicas**: Zonas de disponibilidade A e B
3. **Security Groups**: 
   - `ec2_sg` (SSH - porta 22)
   - `http_sg` (HTTP - porta 80)
   - `sglb` (Load Balancer)
4. **Launch Template**: Configuração base das instâncias
5. **Auto Scaling Group**: Mantém 2 instâncias rodando
6. **Application Load Balancer**: Distribui tráfego HTTP

---

## ✅ Pré-requisitos

### Software Necessário:

```bash
# Terraform >= 1.5.7
terraform --version

# AWS CLI configurado
aws --version
aws configure list

# Git
git --version
```

### Credenciais AWS:

```bash
# Configure suas credenciais AWS
aws configure

# Ou exporte diretamente
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Recursos Pré-existentes na AWS:

- VPC: `cmtr-k5vl9gpq-vpc`
- Security Groups: `cmtr-k5vl9gpq-ec2_sg`, `cmtr-k5vl9gpq-http_sg`, `cmtr-k5vl9gpq-sglb`
- IAM Instance Profile: `cmtr-k5vl9gpq-instance_profile`
- Key Pair: `cmtr-k5vl9gpq-keypair`

---

## 📁 Estrutura do Projeto

```
terraform-aws-lab/
├── .gitignore                 # Arquivos ignorados pelo Git
├── README.md                  # Este arquivo
├── versions.tf                # Versões do Terraform e providers
├── variables.tf               # Declaração de variáveis
├── terraform.tfvars           # Valores das variáveis
├── data.tf                    # Data sources (recursos existentes)
├── locals.tf                  # Valores locais computados
├── application.tf             # Recursos principais (ALB, ASG, Launch Template)
└── outputs.tf                 # Outputs (DNS do LB, ARNs, etc)
```

---

## 🚀 Guia Passo a Passo

### 1️⃣ Clonar ou Criar o Repositório

```bash
# Opção A: Clonar repositório existente
git clone https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git
cd SEU-REPOSITORIO

# Opção B: Criar novo repositório
mkdir terraform-aws-lab
cd terraform-aws-lab
git init
```

### 2️⃣ Criar Estrutura de Arquivos

#### 📄 versions.tf

```bash
cat > versions.tf << 'EOF'
terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF
```

**Por quê?** Define a versão mínima do Terraform e o provider AWS que será usado.

---

#### 📄 variables.tf

```bash
cat > variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "project_name" {
  description = "Project identifier used for resource naming and tagging"
  type        = string
}

variable "ami_id" {
  description = "Amazon Machine Image ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the launch template"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for EC2 instance access"
  type        = string
}

variable "vpc_name" {
  description = "Name of the existing VPC"
  type        = string
}

variable "public_subnet_cidr_a" {
  description = "CIDR block for public subnet in availability zone A"
  type        = string
}

variable "private_subnet_cidr_a" {
  description = "CIDR block for private subnet in availability zone A"
  type        = string
}

variable "public_subnet_cidr_b" {
  description = "CIDR block for public subnet in availability zone B"
  type        = string
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for private subnet in availability zone B"
  type        = string
}

variable "ec2_sg_name" {
  description = "Name of the security group for SSH access to EC2 instances"
  type        = string
}

variable "http_sg_name" {
  description = "Name of the security group for HTTP access to EC2 instances"
  type        = string
}

variable "lb_sg_name" {
  description = "Name of the security group for the load balancer"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  type        = string
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
}
EOF
```

**Por quê?** Centraliza todas as variáveis do projeto. Torna o código reutilizável e configurável.

---

#### 📄 terraform.tfvars

```bash
cat > terraform.tfvars << 'EOF'
aws_region            = "us-east-1"
project_name          = "cmtr-k5vl9gpq"
ami_id                = "ami-09e6f87a47903347c"
instance_type         = "t3.micro"
ssh_key_name          = "cmtr-k5vl9gpq-keypair"
vpc_name              = "cmtr-k5vl9gpq-vpc"
public_subnet_cidr_a  = "10.0.1.0/24"
private_subnet_cidr_a = "10.0.2.0/24"
public_subnet_cidr_b  = "10.0.3.0/24"
private_subnet_cidr_b = "10.0.4.0/24"
ec2_sg_name           = "cmtr-k5vl9gpq-ec2_sg"
http_sg_name          = "cmtr-k5vl9gpq-http_sg"
lb_sg_name            = "cmtr-k5vl9gpq-sglb"
instance_profile_name = "cmtr-k5vl9gpq-instance_profile"
asg_desired_capacity  = 2
asg_min_size          = 1
asg_max_size          = 2
EOF
```

**Por quê?** Contém os valores reais das variáveis. Permite diferentes configurações para dev/staging/prod.

---

#### 📄 data.tf

```bash
cat > data.tf << 'EOF'
# Data sources para buscar recursos pré-existentes na AWS

data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "cidr-block"
    values = [var.public_subnet_cidr_a, var.public_subnet_cidr_b]
  }
}

data "aws_security_group" "ec2_sg" {
  filter {
    name   = "group-name"
    values = [var.ec2_sg_name]
  }

  vpc_id = data.aws_vpc.existing.id
}

data "aws_security_group" "http_sg" {
  filter {
    name   = "group-name"
    values = [var.http_sg_name]
  }

  vpc_id = data.aws_vpc.existing.id
}

data "aws_security_group" "lb_sg" {
  filter {
    name   = "group-name"
    values = [var.lb_sg_name]
  }

  vpc_id = data.aws_vpc.existing.id
}

data "aws_iam_instance_profile" "existing" {
  name = var.instance_profile_name
}
EOF
```

**Por quê?** Busca recursos que já existem na AWS. Não estamos criando VPC ou Security Groups, apenas referenciando-os.

---

#### 📄 locals.tf

```bash
cat > locals.tf << 'EOF'
locals {
  # Nomes dos recursos gerados dinamicamente
  launch_template_name = "${var.project_name}-template"
  asg_name             = "${var.project_name}-asg"
  lb_name              = "${var.project_name}-loadbalancer"
  target_group_name    = "${var.project_name}-tg"

  # Tags comuns para todos os recursos
  common_tags = {
    Terraform = "true"
    Project   = var.project_name
  }

  # Script de inicialização user_data
  user_data = <<-EOF
    #!/bin/bash
    # Atualiza pacotes do sistema
    yum update -y
    
    # Instala dependências necessárias
    yum install -y aws-cli httpd jq
    
    # Configura o servidor web para iniciar automaticamente
    systemctl enable httpd
    systemctl start httpd
    
    # Obtém token IMDSv2 (mais seguro que IMDSv1)
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    
    # Obtém metadados da instância usando o token
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
    
    # Cria página HTML com informações da instância
    cat > /var/www/html/index.html << HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>Instance Info</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 50px; }
            h1 { color: #232F3E; }
            p { font-size: 18px; }
        </style>
    </head>
    <body>
        <h1>🚀 EC2 Instance Information</h1>
        <p>This message was generated on instance <strong>$INSTANCE_ID</strong> with the following IP: <strong>$PRIVATE_IP</strong></p>
    </body>
    </html>
    HTML
    
    # Garante permissões corretas
    chmod 644 /var/www/html/index.html
  EOF
}
EOF
```

**Por quê?** 
- **Locals**: Valores calculados usados em múltiplos lugares
- **User Data**: Script bash que roda quando a instância EC2 inicializa
- **IMDSv2**: Método mais seguro de obter metadados da instância

---

#### 📄 application.tf

```bash
cat > application.tf << 'EOF'
# Launch Template - Define como as instâncias EC2 serão criadas
resource "aws_launch_template" "main" {
  name          = local.launch_template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  # Configuração de rede
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups = [
      data.aws_security_group.ec2_sg.id,
      data.aws_security_group.http_sg.id
    ]
  }

  # Profile IAM para permissões da instância
  iam_instance_profile {
    name = data.aws_iam_instance_profile.existing.name
  }

  # Configuração de metadados
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  # Script de inicialização
  user_data = base64encode(local.user_data)

  tags = merge(
    local.common_tags,
    {
      Name = local.launch_template_name
    }
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      {
        Name = "${local.launch_template_name}-instance"
      }
    )
  }
}

# Target Group - Agrupa instâncias para o Load Balancer
resource "aws_lb_target_group" "main" {
  name     = local.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.target_group_name
    }
  )
}

# Application Load Balancer - Distribui tráfego
resource "aws_lb" "main" {
  name               = local.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.lb_sg.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = merge(
    local.common_tags,
    {
      Name = local.lb_name
    }
  )
}

# Listener - Escuta requisições HTTP na porta 80
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = local.common_tags
}

# Auto Scaling Group - Gerencia instâncias automaticamente
resource "aws_autoscaling_group" "main" {
  name                = local.asg_name
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  vpc_zone_identifier = data.aws_subnets.public.ids

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Ignora mudanças em load_balancers e target_group_arns
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tag {
    key                 = "Name"
    value               = local.asg_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

# Attachment - Conecta ASG ao Target Group do Load Balancer
resource "aws_autoscaling_attachment" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.id
  lb_target_group_arn    = aws_lb_target_group.main.arn
}
EOF
```

**Por quê?** Este é o coração do projeto. Cria todos os recursos principais:
- **Launch Template**: Molde para criar instâncias
- **Target Group**: Agrupa instâncias para health checks
- **Load Balancer**: Distribui tráfego entre instâncias
- **Listener**: Escuta na porta 80
- **Auto Scaling Group**: Mantém número desejado de instâncias
- **Attachment**: Conecta ASG ao LB

---

#### 📄 outputs.tf

```bash
cat > outputs.tf << 'EOF'
output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.main.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.main.id
}
EOF
```

**Por quê?** Exibe informações importantes após o deploy, como o DNS do Load Balancer.

---

#### 📄 .gitignore

```bash
cat > .gitignore << 'EOF'
# Terraform state files - contêm informações sensíveis
*.tfstate
*.tfstate.*
*.tfstate.backup

# Terraform directory
.terraform/
.terraform.lock.hcl

# Crash log files
crash.log
crash.*.log

# Variable files que podem conter dados sensíveis
# NOTA: Removido *.tfvars desta lista para este projeto específico
# *.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI configuration files
.terraformrc
terraform.rc

# MacOS files
.DS_Store

# Editor files
*.swp
*.swo
*~
.vscode/
.idea/

# Backup files
*.bak
EOF
```

**Por quê?** 
- Protege informações sensíveis (`.tfstate`)
- Evita commit de arquivos grandes (`.terraform/`)
- Melhora colaboração (cada dev tem suas configs)

---

### 3️⃣ Inicializar Git e Conectar ao Repositório

```bash
# Inicializar repositório Git (se ainda não foi feito)
git init

# Adicionar remote (substitua pela URL do seu repositório)
git remote add origin https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git

# Configurar usuário Git
git config user.name "Seu Nome"
git config user.email "seu@email.com"
```

---

### 4️⃣ Executar Terraform

```bash
# 1. Inicializar Terraform (baixa providers)
terraform init

# 2. Formatar código
terraform fmt

# 3. Validar configuração
terraform validate

# 4. Ver plano de execução (sem aplicar)
terraform plan

# 5. Aplicar infraestrutura (digite 'yes' quando solicitado)
terraform apply
```

**Saída esperada:**

```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

autoscaling_group_name = "cmtr-k5vl9gpq-asg"
launch_template_id = "lt-0a1b2c3d4e5f6g7h8"
load_balancer_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/cmtr-k5vl9gpq-loadbalancer/1234567890abcdef"
load_balancer_dns = "cmtr-k5vl9gpq-loadbalancer-1234567890.us-east-1.elb.amazonaws.com"
target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/cmtr-k5vl9gpq-tg/1234567890abcdef"
```

---

### 5️⃣ Testar a Aplicação

```bash
# Obter DNS do Load Balancer
LB_DNS=$(terraform output -raw load_balancer_dns)

# Testar com curl
curl http://$LB_DNS

# Ou abrir no navegador
echo "Acesse: http://$LB_DNS"
```

**Resposta esperada:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Instance Info</title>
    ...
</head>
<body>
    <h1>🚀 EC2 Instance Information</h1>
    <p>This message was generated on instance i-0a1b2c3d4e5f6g7h8 with the following IP: 10.0.1.123</p>
</body>
</html>
```

---

### 6️⃣ Commitar e Enviar para GitHub

```bash
# Adicionar todos os arquivos
git add .

# Verificar status
git status

# Fazer commit
git commit -m "feat: initial terraform configuration for AWS ALB with ASG"

# Enviar para GitHub
git push -u origin main
```

---

## 📦 Recursos Criados

Após executar `terraform apply`, os seguintes recursos serão criados:

| Recurso | Nome | Tipo | Descrição |
|---------|------|------|-----------|
| Launch Template | `cmtr-k5vl9gpq-template` | `aws_launch_template` | Configuração base das instâncias EC2 |
| Auto Scaling Group | `cmtr-k5vl9gpq-asg` | `aws_autoscaling_group` | Gerencia 1-2 instâncias automaticamente |
| Load Balancer | `cmtr-k5vl9gpq-loadbalancer` | `aws_lb` | Distribui tráfego HTTP |
| Target Group | `cmtr-k5vl9gpq-tg` | `aws_lb_target_group` | Agrupa instâncias para health checks |
| Listener | - | `aws_lb_listener` | Escuta na porta 80 |
| ASG Attachment | - | `aws_autoscaling_attachment` | Conecta ASG ao LB |

**Custos Estimados:** ~$0.02/hora com 2 instâncias t3.micro

---

## 📚 Explicação dos Arquivos

### versions.tf
- Define versão mínima do Terraform (`>= 1.5.7`)
- Configura provider AWS (`~> 5.0`)
- **Por quê separar?** Facilita upgrades e mantém consistência entre ambientes

### variables.tf
- Declaração de todas as variáveis
- Inclui tipo (`string`, `number`) e descrição
- **Boa prática:** Nunca usar valores default para evitar hardcoding

### terraform.tfvars
- Valores reais das variáveis
- **Atenção:** Normalmente este arquivo é ignorado (pode conter senhas)
- Neste projeto é commitado porque não há dados sensíveis

### data.tf
- Busca recursos existentes na AWS
- Usa `data sources` ao invés de criar recursos
- **Evita duplicação:** Não cria VPC/SG que já existem

### locals.tf
- Valores computados localmente
- Evita repetição de código
- Contém o script `user_data` que roda nas instâncias

### application.tf
- **Arquivo principal** com todos os recursos
- Launch Template → ASG → Target Group → Load Balancer → Listener
- **Fluxo:** Usuário → LB → Target Group → Instâncias EC2

### outputs.tf
- Exibe informações após `terraform apply`
- DNS do Load Balancer, ARNs, IDs
- Útil para integração com outros sistemas

### .gitignore
- **Crítico para segurança!**
- Bloqueia `.tfstate` (contém IDs, IPs, senhas)
- Bloqueia `.terraform/` (grande e desnecessário)

---

## 🛠️ Comandos Úteis

### Comandos Terraform

```bash
# Ver estado atual
terraform show

# Listar recursos gerenciados
terraform state list

# Ver detalhes de um recurso
terraform state show aws_lb.main

# Ver outputs
terraform output

# Ver output específico
terraform output load_balancer_dns

# Formatar código
terraform fmt -recursive

# Validar configuração
terraform validate

# Planejar mudanças
terraform plan

# Aplicar mudanças
terraform apply

# Aplicar sem confirmação (cuidado!)
terraform apply -auto-approve

# Destruir infraestrutura
terraform destroy
```

### Comandos AWS CLI

```bash
# Verificar instâncias do Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names cmtr-k5vl9gpq-asg

# Verificar health checks do Target Group
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)

# Ver logs do Load Balancer (se configurado)
aws logs tail /aws/elasticloadbalancing/app/cmtr-k5vl9gpq-loadbalancer --follow
```

### Comandos de Teste

```bash
# Testar Load Balancer múltiplas vezes (ver balanceamento)
for i in {1..10}; do
  curl http://$(terraform output -raw load_balancer_dns)
  echo ""
done

# Monitorar em tempo real
watch -n 2 'curl -s http://$(terraform output -raw load_balancer_dns) | grep instance'
```

---

## 🔍 Troubleshooting

### Problema: `terraform init` falha

**Erro:**
```
Error: Failed to install provider
```

**Solução:**
```bash
# Limpar cache
rm -rf .terraform .terraform.lock.hcl

# Reinicializar
terraform init
```

---

### Problema: Instâncias não passam no health check

**Sintomas:**
- Load Balancer retorna 503 Service Unavailable
- Target Group mostra instâncias "unhealthy"

**Diagnóstico:**
```bash
# Verificar health do Target Group
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)
```

**Soluções:**
1. Aguardar 5-10 minutos (tempo de inicialização)
2. Verificar Security Groups (porta 80 aberta?)
3. SSH na instância e verificar Apache:
   ```bash
   sudo systemctl status httpd
   curl localhost
   ```

---

### Problema: `git push` rejeitado

**Erro:**
```
! [rejected] main -> main (fetch first)
```

**Solução:**
```bash
# Pull com rebase
git pull origin main --rebase

# Resolver conflitos (se houver)
git add .
git rebase --continue

# Push
git push origin main
```

---

### Problema: Formatação incorreta

**Erro:**
```
Code in TF configuration needs formatting
```

**Solução:**
```bash
# Formatar todos os arquivos
terraform fmt -recursive

# Verificar
terraform fmt -check

# Commitar
git add .
git commit -m "style: apply terraform formatting"
git push
```

---

## 🧹 Limpeza

### Destruir Infraestrutura

```bash
