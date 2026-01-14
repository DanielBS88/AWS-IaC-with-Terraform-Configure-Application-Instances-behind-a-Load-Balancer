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
    </head>
    <body>
        <h1>EC2 Instance Information</h1>
        <p>This message was generated on instance $INSTANCE_ID with the following IP: $PRIVATE_IP</p>
    </body>
    </html>
    HTML
    
    # Garante permissões corretas
    chmod 644 /var/www/html/index.html
  EOF
}
