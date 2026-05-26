# 🏛️ Documentación Técnica - Arquitectura Completa

## Tabla de Contenidos
1. [Arquitectura General](#arquitectura-general)
2. [Componentes Terraform Detallados](#componentes-terraform-detallados)
3. [Componentes Docker Detallados](#componentes-docker-detallados)
4. [Flujo de Datos](#flujo-de-datos)
5. [Seguridad](#seguridad)
6. [Escalabilidad](#escalabilidad)
7. [Monitoreo](#monitoreo)

---

## 🏗️ Arquitectura General

### Diagrama de Tres Capas

```
┌────────────────────────────────────────────────────────────────┐
│  CAPA 1: APLICACIÓN (Docker - Local o en EC2)                │
│  ┌──────────────┬──────────────┐                               │
│  │   Web App    │  Team API    │                               │
│  │ (Puerto 8000)│ (Puerto 8001)│                               │
│  └──────────────┴──────────────┘                               │
└────────────────────────────────────────────────────────────────┘
                           ↕
┌────────────────────────────────────────────────────────────────┐
│  CAPA 2: ORQUESTACIÓN (Docker Compose o Kubernetes)           │
│  ┌────────────────────────────────────────────────────────────┐│
│  │  Red bridge: capgemini-network                             ││
│  │  Volumes compartidos                                        ││
│  │  Reinicio automático                                        ││
│  └────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────┘
                           ↕
┌────────────────────────────────────────────────────────────────┐
│  CAPA 3: INFRAESTRUCTURA (Terraform + AWS)                    │
│  ┌────────────────────────────────────────────────────────────┐│
│  │  VPC: 10.0.0.0/16                                          ││
│  │  ├─ Subnet Pública: 10.0.1.0/24                           ││
│  │  │  └─ EC2 Instance (t3.micro/small/medium)              ││
│  │  ├─ Subnet Privada: 10.0.2.0/24                          ││
│  │  │  └─ Recursos privados (DB, etc.)                      ││
│  │  └─ Internet Gateway                                       ││
│  │  └─ Security Groups (Firewall)                             ││
│  └────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────┘
```

### Ciclo de Vida Completo

```
FASE 1: DESARROLLO LOCAL (Tu Máquina)
├─ docker-compose up
├─ Contenedores se inician
├─ Acceso a http://localhost:8000
└─ Volúmenes sincronizados para cambios en tiempo real

FASE 2: PREPARACIÓN INFRAESTRUCTURA (Tu Máquina)
├─ terraform init (descargar proveedores)
├─ terraform plan (ver cambios)
├─ terraform apply (crear en AWS)
└─ Guardar outputs (IPs públicas)

FASE 3: DESPLIEGUE PRODUCCIÓN (AWS EC2)
├─ Script user_data.sh se ejecuta automáticamente
├─ Instala Docker y Docker Compose
├─ Clona/descarga tu aplicación
├─ Ejecuta docker-compose up
└─ Tu app disponible en http://ip-publica:puerto

FASE 4: MONITOREO Y MANTENIMIENTO
├─ Ver logs con CloudWatch
├─ Escalar aumentando instancias
├─ Actualizar terraform.tfvars
└─ terraform apply (sin destruir, solo actualiza)

FASE 5: CLEANUP
├─ terraform destroy
└─ Todo eliminado, pagas $0
```

---

## 🔧 Componentes Terraform Detallados

### 1. Provider Configuration (provider.tf)

```hcl
terraform {
  # Versión mínima de Terraform requerida
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Compatible con 5.x, pero no 6.x
    }
  }
  
  # Guardar estado localmente (cambiar a S3 para producción)
  # backend "s3" {
  #   bucket = "mi-terraform-state"
  #   key    = "capgemini/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
  
  # Tags por defecto para todos los recursos
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# Obtener zonas de disponibilidad automáticamente
data "aws_availability_zones" "available" {
  state = "available"
}
```

### 2. Variables (variables.tf)

```hcl
variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"  # Más barato
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Ambiente debe ser: dev, staging, o prod"
  }
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"  # Free tier eligible
  
  # Diferentes tipos según ambiente
  # dev: t3.micro (gratis)
  # staging: t3.small ($0.023/hora)
  # prod: t3.medium ($0.0464/hora)
}

variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
  default     = "10.0.0.0/16"  # 65,536 IPs disponibles
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]  # 256 IPs c/u
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks para subnets privadas"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Team       = "DevOps"
    CostCenter = "Engineering"
  }
}
```

### 3. Recursos Principales (main.tf)

#### VPC y Networking

```hcl
# 1. VPC (Red Virtual Privada)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Habilitar DNS
  enable_dns_support   = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-vpc"
    }
  )
}

# 2. Internet Gateway (puerta de salida a Internet)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-igw"
    }
  )
}

# 3. Subnets Públicas (accesibles desde Internet)
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  # Asignar IP pública automáticamente a instancias
  map_public_ip_on_launch = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-subnet-${count.index + 1}"
      Type = "Public"
    }
  )
}

# 4. Subnets Privadas (NO accesibles desde Internet)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-private-subnet-${count.index + 1}"
      Type = "Private"
    }
  )
}

# 5. Route Table Pública (definir rutas)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  # Ruta por defecto: todo va al Internet Gateway
  route {
    cidr_block      = "0.0.0.0/0"  # Cualquier destino
    gateway_id      = aws_internet_gateway.main.id
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-rt"
    }
  )
}

# 6. Asociar Route Table a Subnets Públicas
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

#### Security Groups (Firewalls)

```hcl
# Security Group para acceso web
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Permitir HTTP/HTTPS/SSH"
  vpc_id      = aws_vpc.main.id
  
  # Regla de entrada: HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Desde cualquier lugar
  }
  
  # Regla de entrada: HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Regla de entrada: SSH (cambiar a tu IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️  Abierto (solo para demo)
  }
  
  # Puertos custom para Docker (ej: 8000, 8001)
  ingress {
    from_port   = 8000
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Regla de salida: Todo permitido (por defecto)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Todos los protocolos
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-web-sg"
    }
  )
}
```

#### Instancias EC2

```hcl
# Key Pair para SSH (debes crear la key previamente)
resource "aws_key_pair" "deployer" {
  key_name   = "${var.environment}-deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Tu clave pública
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-deployer-key"
    }
  )
}

# Instancia EC2
resource "aws_instance" "web" {
  count                = var.instance_count  # Número de instancias
  ami                  = data.aws_ami.amazon_linux_2.id  # OS: Amazon Linux 2
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public[count.index % length(aws_subnet.public)].id
  security_groups      = [aws_security_group.web.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = aws_key_pair.deployer.key_name
  
  # Script ejecutado automáticamente al iniciar
  user_data = file("${path.module}/scripts/user_data.sh")
  
  # Monitoreo detallado
  monitoring = true
  
  # Etiquetas
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-web-server-${count.index + 1}"
    }
  )
  
  # Esperar a que se ejecute el script
  depends_on = [aws_internet_gateway.main]
  
  # Ejecutar script de aprovisionamiento
  provisioner "remote-exec" {
    inline = ["echo 'EC2 instance configurada'"]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}

# Data source para obtener la última AMI de Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

#### IAM Role para EC2 (Permisos)

```hcl
# Role de IAM
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Política para acceder a CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Política para acceder a S3 (opcional)
resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Instance Profile (contenedor para el role)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
```

### 4. Outputs (outputs.tf)

```hcl
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID de la VPC"
}

output "instance_ids" {
  value       = aws_instance.web[*].id
  description = "IDs de las instancias EC2"
}

output "instance_public_ips" {
  value       = aws_instance.web[*].public_ip
  description = "IPs públicas de las instancias"
}

output "instance_private_ips" {
  value       = aws_instance.web[*].private_ip
  description = "IPs privadas de las instancias"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "IDs de subnets públicas"
}

output "security_group_id" {
  value       = aws_security_group.web.id
  description = "ID del Security Group web"
}

# Información de acceso
output "ssh_connection_string" {
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.web[0].public_ip}"
  description = "Comando para conectarse por SSH"
}

output "web_url" {
  value       = "http://${aws_instance.web[0].public_ip}:8000"
  description = "URL para acceder a la web"
}
```

---

## 🐳 Componentes Docker Detallados

### Dockerfile Optimizado

```dockerfile
# ETAPA 1: Base (reutilizable)
FROM python:3.11-slim as base

# Configurar pip para usar caché
ENV PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# ETAPA 2: Builder (construir dependencias)
FROM base as builder

WORKDIR /build

# Copiar archivos de requirments (si existen)
COPY requirements.txt .
RUN pip install --user --no-warn-script-location -r requirements.txt || true

# ETAPA 3: Runtime (imagen final, más pequeña)
FROM base

WORKDIR /app

# Copiar dependencias instaladas del builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copiar archivos de la aplicación
COPY index.html .
COPY team.html .
COPY styles.css .
COPY server.py .

# Crear usuario no-root (seguridad)
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Exponer puerto
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000')" || exit 1

# Comando de inicio
CMD ["python", "-m", "http.server", "8000", "--bind", "0.0.0.0"]
```

### docker-compose.yml Avanzado

```yaml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      cache_from:  # Usar caché de builds anteriores
        - web:latest
    
    container_name: capgemini-web
    
    ports:
      - "${WEB_PORT:-8000}:8000"  # Variable de entorno
    
    volumes:
      - ./index.html:/app/index.html
      - ./team.html:/app/team.html
      - ./styles.css:/app/styles.css
      - ./data:/app/data
      - /app/__pycache__  # Excluir caché
    
    environment:
      - PYTHONUNBUFFERED=1
      - ENVIRONMENT=development
      - LOG_LEVEL=INFO
    
    depends_on:
      team-api:
        condition: service_healthy
    
    restart: unless-stopped
    
    networks:
      - capgemini-network
    
    # Limites de recursos
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
    
    # Logging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    
    labels:
      com.capgemini.description: "Web server principal"

  team-api:
    image: python:3.11-slim
    
    container_name: capgemini-team-api
    
    working_dir: /app
    
    command: python -m http.server 8001 --directory /app/data
    
    ports:
      - "${TEAM_API_PORT:-8001}:8001"
    
    volumes:
      - ./data:/app/data:ro  # Read-only
    
    environment:
      - PYTHONUNBUFFERED=1
    
    restart: unless-stopped
    
    networks:
      - capgemini-network
    
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 128M
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s
    
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "2"

  # Servicio opcional: Reverse Proxy (Nginx)
  # proxy:
  #   image: nginx:alpine
  #   ports:
  #     - "80:80"
  #   volumes:
  #     - ./nginx.conf:/etc/nginx/nginx.conf:ro
  #   depends_on:
  #     - web
  #     - team-api
  #   networks:
  #     - capgemini-network

networks:
  capgemini-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16  # Rango específico
```

---

## 📊 Flujo de Datos

### Request HTTP: Local
```
1. Navegador: http://localhost:8000
2. Docker Network intercepta puerto 8000
3. Ruta hacia contenedor 'web'
4. Python HTTP Server en /app
5. Retorna index.html + styles.css
6. Navegador renderiza página
```

### Request HTTP: AWS
```
1. Navegador: http://18.234.123.45:8000
2. Internet → Security Group (puerto 8000)
3. EC2 instancia recibe tráfico
4. Docker dentro de EC2 recibe en puerto 8000
5. Contenedor 'web' procesa
6. Retorna contenido
7. Respuesta viaja de vuelta
```

---

## 🔐 Seguridad

### Best Practices Implementadas

```hcl
# 1. Restringir SSH a IP específica
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["YOUR_IP/32"]  # Solo tu IP
  security_group_id = aws_security_group.web.id
}

# 2. Usar subnets privadas para datos
resource "aws_instance" "database" {
  # Instancia en subnet privada, no accesible desde Internet
  subnet_id = aws_subnet.private[0].id
}

# 3. Usar IAM roles (no credentials hardcodeados)
resource "aws_iam_role_policy" "custom" {
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::my-bucket/*"
    }]
  })
}

# 4. Encriptar EBS volumes
resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

# 5. Usar SSL/TLS (certificate)
resource "aws_acm_certificate" "main" {
  domain_name       = "example.com"
  validation_method = "DNS"
}

# 6. Logs centralizados
resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/aws/ec2/${var.environment}"
  retention_in_days = 30
}
```

### Docker Security

```dockerfile
# No ejecutar como root
USER appuser

# Hacer sistema de archivos read-only donde sea posible
RUN chmod -R 555 /app

# Usar non-root user
RUN useradd -r -u 1000 appuser

# No hacer pip install como root
RUN pip install --user --no-warn-script-location -r requirements.txt
```

---

## 📈 Escalabilidad

### Auto-Scaling Group (próxima versión)

```hcl
resource "aws_launch_configuration" "web" {
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  user_data     = file("${path.module}/scripts/user_data.sh")
}

resource "aws_autoscaling_group" "web" {
  launch_configuration = aws_launch_configuration.web.id
  min_size             = 1
  max_size             = 5
  desired_capacity     = 2
  vpc_zone_identifier  = aws_subnet.public[*].id
  
  tag {
    key                 = "Name"
    value               = "${var.environment}-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "web" {
  name               = "${var.environment}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "web" {
  name        = "${var.environment}-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
}
```

---

## 📊 Monitoreo

### CloudWatch Metrics

```python
# Script para enviar métricas personalizadas a CloudWatch
import boto3
from datetime import datetime

cloudwatch = boto3.client('cloudwatch')

def put_metric(metric_name, value):
    cloudwatch.put_metric_data(
        Namespace='Capgemini/Docker',
        MetricData=[{
            'MetricName': metric_name,
            'Value': value,
            'Unit': 'Count',
            'Timestamp': datetime.utcnow()
        }]
    )

# Uso
put_metric('ActiveContainers', 2)
put_metric('MemoryUsage', 256)
```

### CloudWatch Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU está alto"
  alarm_actions       = [aws_sns_topic.alerts.arn]  # Enviar email
}

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "tu-email@example.com"
}
```

---

## 🔄 CI/CD Workflow (Próxima)

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Build and push Docker image
        run: |
          docker build -t capgemini:${{ github.sha }} .
          aws ecr get-login-password | docker login --username AWS --password-stdin ${{ secrets.ECR_REGISTRY }}
          docker tag capgemini:${{ github.sha }} ${{ secrets.ECR_REGISTRY }}/capgemini:latest
          docker push ${{ secrets.ECR_REGISTRY }}/capgemini:latest
      
      - name: Deploy with Terraform
        run: |
          terraform init
          terraform plan -out=tfplan
          terraform apply tfplan
```

---

**Documento técnico actualizado: Enero 2026**