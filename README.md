# Capgemini - Infraestructura Moderna en AWS con Terraform & Docker

## Bienvenido 👋

Este es un proyecto **profesional y completo** que muestra cómo implementar Infrastructure as Code (IaC) usando **Terraform**, **AWS**, **Docker** y **Docker Compose**. Es un ejemplo real de cómo las empresas modernas gestionan infraestructura en la nube.

---

## 📚 Tabla de Contenidos

1. [Qué es Terraform](#qué-es-terraform)
2. [Qué es Docker](#qué-es-docker)
3. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
4. [Estructura de Carpetas](#estructura-de-carpetas)
5. [Instalación y Setup](#instalación-y-setup)
6. [Comandos Principales](#comandos-principales)
7. [Workflow Completo](#workflow-completo)
8. [Mejores Prácticas](#mejores-prácticas)

---

## 🏗️ Qué es Terraform?

### Definición Simple

**Terraform** es una herramienta que permite **escribir código para describir tu infraestructura en la nube**. En lugar de hacer clic en la consola de AWS, escribes archivos `.tf` que especifican qué recursos quieres crear.

### Características Principales

| Característica | Descripción |
|---|---|
| **Declarativo** | Describes QJUÉ quieres, no CÓMO hacerlo |
| **Agnóstico** | Funciona con AWS, Azure, GCP, Kubernetes, etc. |
| **Idempotente** | Ejecutar 10 veces = mismo resultado |
| **Versionable** | Tu infraestructura está en Git |
| **Reproducible** | Fácil replicar ambientes exactamente |

### Comparación: Manual vs Terraform

**Manual (❌ No recomendado):**
```
1. Abrir consola AWS
2. Ir a VPC
3. Crear VPC con CIDR 10.0.0.0/16
4. Crear Internet Gateway
5. Adjuntar IGW a VPC
6. Crear subnet pública
... (muchos pasos más)
```

**Con Terraform (✅ Recomendado):**
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

### Ciclo de Vida de Terraform

```
┌─────────────────────────────────────────┐
│ 1. terraform init                       │ ← Descargar proveedores
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ 2. terraform plan                       │ ← Ver cambios (preview)
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ 3. terraform apply                      │ ← Crear recursos en AWS
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ 4. terraform destroy                    │ ← Eliminar recursos
└─────────────────────────────────────────┘
```

### Archivos Principales

#### `provider.tf` - Configuración del Proveedor
Define qué proveedor de nube usarás (AWS, Azure, GCP, etc.) y qué región.

```hcl
terraform {
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
```

#### `variables.tf` - Define Inputs
Las variables son como parámetros. Puedes cambiarlas sin modificar el código.

```hcl
variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_count" {
  description = "Número de instancias EC2"
  type        = number
  default     = 2
}

variable "environment" {
  description = "Ambiente: dev, staging, prod"
  type        = string
  default     = "dev"
}
```

#### `main.tf` - Define Recursos
Aquí defines los recursos que quieres crear: VPC, EC2, Security Groups, etc.

```hcl
# Crear VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Crear Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-igw" }
}

# Crear Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.environment}-public-subnet" }
}

# Crear Instancia EC2
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.deployer.key_name
  
  # Script para instalar Docker automáticamente
  user_data = file("${path.module}/scripts/user_data.sh")

  tags = { Name = "${var.environment}-web-server" }
}
```

#### `outputs.tf` - Define Outputs
Los outputs son valores que Terraform retorna después de crear recursos.

```hcl
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID de la VPC"
}

output "instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "IP pública de la instancia EC2"
}

output "instance_private_ip" {
  value       = aws_instance.web.private_ip
  description = "IP privada de la instancia EC2"
}
```

---

## 🐳 Qué es Docker?

### Definición Simple

**Docker** es una plataforma que **empaqueta tu aplicación con todas sus dependencias** en un contenedor aislado. Es como una caja hermética que contiene todo lo que tu app necesita.

### El Problema que Docker Resuelve

```
Problema Clásico:
────────────────────────────────────
"Funciona en mi máquina pero no en el servidor"

Con Docker:
────────────────────────────────────
Tu app en un contenedor = Funciona igual en:
- Tu laptop
- Servidor de desarrollo
- Servidor de staging  
- Servidor de producción
```

### Conceptos Clave

| Concepto | Explicación |
|---|---|
| **Imagen** | Plantilla/blueprint (como una clase en POO) |
| **Contenedor** | Instancia en ejecución de la imagen (como un objeto) |
| **Dockerfile** | Archivo con instrucciones para construir la imagen |
| **docker-compose** | Orquesta múltiples contenedores como un sistema |
| **Red (Network)** | Permite que contenedores se comuniquen entre sí |

### Dockerfile Explicado

```dockerfile
# Base image: Sistema operativo + Python
FROM python:3.11-slim

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar archivos de tu máquina al contenedor
COPY index.html .
COPY styles.css .
COPY server.py .

# Exponer puerto 8000 (el contenedor escucha aquí)
EXPOSE 8000

# Comando a ejecutar cuando inicia el contenedor
CMD ["python", "-m", "http.server", "8000"]
```

**Explicación línea por línea:**
1. `FROM python:3.11-slim` → Descarga imagen de Python 3.11 (versión ligera)
2. `WORKDIR /app` → Crea directorio `/app` y lo establece como directorio actual
3. `COPY index.html .` → Copia archivo de tu máquina (.) al directorio del contenedor (.)
4. `EXPOSE 8000` → "Advierte" que el contenedor usa puerto 8000
5. `CMD [...]` → Comando que se ejecuta al iniciar

### Docker Compose Explicado

```yaml
version: '3.8'

services:
  # Primer servicio: servidor web principal
  web:
    build: .                              # Construir desde Dockerfile
    container_name: capgemini-web         # Nombre del contenedor
    ports:
      - "8000:8000"                      # puerto_local:puerto_contenedor
    volumes:
      - ./index.html:/app/index.html     # Sincronizar archivos
    environment:
      - PYTHONUNBUFFERED=1               # Variables de entorno
    restart: unless-stopped               # Reiniciar si falla
    networks:
      - capgemini-network                # Conectar a red personalizada

  # Segundo servicio: API de datos
  team-api:
    image: python:3.11-slim              # Usar imagen existente (no construir)
    working_dir: /app                    # Directorio de trabajo
    command: python -m http.server 8001 --directory /app/data
    ports:
      - "8001:8001"
    volumes:
      - ./data:/app/data                 # Compartir carpeta de datos
    networks:
      - capgemini-network

# Red personalizada para que servicios se comuniquen
networks:
  capgemini-network:
    driver: bridge                        # Tipo de red
```

**Explicación:**
- `services:` → Lista de contenedores a ejecutar
- `build: .` → Construir imagen desde Dockerfile en el directorio actual
- `image:` → Usar imagen existente de Docker Hub
- `ports:` → Mapeo de puertos (para acceder desde fuera)
- `volumes:` → Carpetas compartidas entre host y contenedor
- `environment:` → Variables de entorno del contenedor
- `networks:` → Redes para que se comuniquen contenedores

---

## 🏛️ Arquitectura del Proyecto

```
┌─────────────────────────────────────────────────────────┐
│           Tu Computadora (Desarrollo)                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │        Docker Compose (docker-compose.yml)       │  │
│  │  ┌──────────────┐  ┌──────────────┐            │  │
│  │  │ Contenedor   │  │ Contenedor   │            │  │
│  │  │   Web App    │  │  API Team    │            │  │
│  │  │ (Puerto 8000)│  │ (Puerto 8001)│            │  │
│  │  └──────────────┘  └──────────────┘            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│                   AWS (Nube)                            │
│         (Creada automáticamente por Terraform)         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │  VPC (Red Virtual: 10.0.0.0/16)                 │  │
│  │  ├─ Subnet Pública (10.0.1.0/24)               │  │
│  │  │  └─ EC2 Instance 1 (t3.micro)              │  │
│  │  │     └─ Docker + Contenedores               │  │
│  │  ├─ Subnet Privada (10.0.2.0/24)              │  │
│  │  │  └─ Base de datos (opcional)               │  │
│  │  └─ Internet Gateway (acceso a Internet)       │  │
│  │  └─ Security Groups (Firewalls)               │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │ CloudWatch (Monitoreo y Logs)                  │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Estructura de Carpetas

```
capgemini/
├── Dockerfile                  # Receta para construir imagen Docker
├── docker-compose.yml          # Orquestación de contenedores
├── index.html                  # Página web principal
├── team.html                   # Página del equipo
├── styles.css                  # Estilos CSS
├── server.py                   # Servidor Python
│
├── provider.tf                 # Configuración del proveedor AWS
├── main.tf                     # Recursos principales (VPC, EC2, etc.)
├── variables.tf                # Definición de variables
├── outputs.tf                  # Valores de salida
│
├── environments/               # Configuraciones por ambiente
│   ├── dev/
│   │   └── terraform.tfvars    # Variables para desarrollo
│   ├── staging/
│   │   └── terraform.tfvars    # Variables para staging
│   └── prod/
│       └── terraform.tfvars    # Variables para producción
│
├── scripts/
│   └── user_data.sh           # Script ejecutado al crear EC2
│                              # Instala Docker y la app
│
├── data/
│   ├── projects.json          # Datos de proyectos
│   └── team.json              # Datos del equipo
│
├── Makefile                    # Comandos útiles
├── README.md                   # Este archivo
└── .gitignore                  # Archivos excluidos de Git
```

---

## ⚙️ Instalación y Setup

### Requisitos Previos

```bash
# 1. Terraform (descarga desde https://www.terraform.io/downloads)
terraform --version              # Verificar instalación

# 2. AWS CLI
aws --version                    # Verificar instalación

# 3. Docker y Docker Compose
docker --version                 # Verificar Docker
docker-compose --version         # Verificar Compose

# 4. Git
git --version                    # Verificar Git
```

### Configurar AWS CLI

```bash
# Conectar tu cuenta AWS
aws configure

# Se te pedirá:
# AWS Access Key ID: [Tu KEY]
# AWS Secret Access Key: [Tu SECRET]
# Default region: us-east-1
# Default output format: json

# Verificar conexión
aws sts get-caller-identity
```

### Clonar el Proyecto

```bash
# Clonar repositorio
git clone <URL>
cd capgemini

# Crear virtual environment (recomendado)
python -m venv capgemini.venv
source capgemini.venv/bin/activate    # Linux/Mac
capgemini.venv\Scripts\activate        # Windows PowerShell
```

---

## 🚀 Comandos Principales

### Docker Compose (Local)

```bash
# Iniciar todos los contenedores
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Listar contenedores corriendo
docker-compose ps

# Detener contenedores
docker-compose down

# Detener y eliminar datos (volúmenes)
docker-compose down -v

# Ejecutar comando en un contenedor
docker-compose exec web bash

# Reconstruir imagen
docker-compose build --no-cache
```

### Terraform (Infraestructura AWS)

```bash
# 1. Inicializar Terraform (solo la primera vez)
terraform init

# 2. Validar sintaxis
terraform validate

# 3. Ver qué cambios haría (MUY IMPORTANTE)
terraform plan -var-file=environments/dev/terraform.tfvars

# 4. Aplicar cambios (crear recursos en AWS)
terraform apply -var-file=environments/dev/terraform.tfvars

# 5. Ver estado actual
terraform show

# 6. Ver outputs
terraform output

# 7. Obtener valor específico
terraform output instance_public_ip

# 8. Destruir infraestructura (CUIDADO: elimina todo)
terraform destroy -var-file=environments/dev/terraform.tfvars
```

### AWS CLI (Verificación)

```bash
# Ver identidad conectada
aws sts get-caller-identity

# Listar instancias EC2
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table

# Listar VPCs
aws ec2 describe-vpcs --output table

# Listar Security Groups
aws ec2 describe-security-groups --output table

# Ver costos (opcional)
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

---

## 🔄 Workflow Completo

### Paso 1: Desarrollo Local con Docker Compose

```bash
# Iniciar la app localmente
docker-compose up -d

# Visita http://localhost:8000
# Tu app se ejecuta en contenedores aislados
# Los cambios en archivos se reflejan en tiempo real (gracias a volumes)
```

### Paso 2: Definir Infraestructura AWS con Terraform

```bash
# Revisar el archivo main.tf
# Está configurado para crear:
# - VPC con subnets públicas y privadas
# - EC2 instance con script para instalar Docker
# - Security Groups para permitir tráfico HTTP/HTTPS
# - Outputs con las IPs de acceso
```

### Paso 3: Crear Infraestructura

```bash
# Cambiar a directorio del proyecto
cd capgemini

# Inicializar Terraform
terraform init

# Ver qué se va a crear
terraform plan -var-file=environments/dev/terraform.tfvars

# Crear infraestructura en AWS
terraform apply -var-file=environments/dev/terraform.tfvars

# Esperar a que termine (2-5 minutos)
# Terraform mostrará las IPs públicas en los outputs
```

### Paso 4: Verificar en AWS Console (Opcional)

```
https://console.aws.amazon.com/ec2/
→ Instances
→ Deberías ver tu instancia corriendo
```

### Paso 5: Ver Aplicación en Servidor

```bash
# Obtener IP pública de la instancia
terraform output instance_public_ip

# Acceder (ejemplo):
# http://18.234.123.45:8000

# SSH a la instancia (si tienes la key)
ssh -i tu-key.pem ec2-user@18.234.123.45

# Ver logs de Docker
docker ps
docker logs <container-id>
```

### Paso 6: Destruir (cuando termines)

```bash
# ADVERTENCIA: Esto elimina TODO en AWS
terraform destroy -var-file=environments/dev/terraform.tfvars

# Confirmar escribiendo: yes
# Esperar a que termine
```

---

## 📋 Mejores Prácticas

### 1. Usa Variables para Reutilizar Código
```hcl
# ❌ Malo: Valores hardcodeados
resource "aws_instance" "web" {
  instance_type = "t3.micro"  # Qué pasa si quiero t3.small?
}

# ✅ Bien: Usa variables
variable "instance_type" {
  default = "t3.micro"
}

resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

### 2. Usa Ambientes Separados
```
environments/
├── dev/terraform.tfvars
├── staging/terraform.tfvars
└── prod/terraform.tfvars
```

### 3. Siempre Ejecuta `plan` Antes de `apply`
```bash
# ✅ Correcto
terraform plan -var-file=environments/dev/terraform.tfvars  # Ver cambios
terraform apply -var-file=environments/dev/terraform.tfvars  # Aplicar

# ❌ Incorrecto
terraform apply  # Aplicar sin ver cambios
```

### 4. Guarda Estado en Remote (No en Local)
```hcl
# Para proyectos en equipo, usa S3 para guardar estado:
terraform {
  backend "s3" {
    bucket = "mi-terraform-state"
    key    = "capgemini/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### 5. Usa .gitignore Correctamente
```
# No commits estos archivos
.terraform/
terraform.tfstate
terraform.tfstate.backup
.DS_Store
*.pem
```

### 6. Documenta con Tags
```hcl
# Identifica recursos en AWS Console
tags = {
  Environment = var.environment
  Project     = "capgemini"
  ManagedBy   = "terraform"
  Owner       = "tu-nombre"
}
```

---

## 🔗 Recursos Útiles

### Documentación Oficial
- [Terraform Docs](https://www.terraform.io/docs)
- [AWS Provider Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Guide](https://docs.docker.com/compose/gettingstarted/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/)

### Tutoriales Recomendados
- Terraform Tutorial: https://learn.hashicorp.com/collections/terraform/aws
- Docker Getting Started: https://docker-curriculum.com/
- AWS Free Tier: https://aws.amazon.com/free/

---

## ❓ Preguntas Frecuentes

### P: ¿Terraform destroye mis datos?
**R:** `terraform destroy` elimina todos los recursos creados por Terraform. Los datos en S3, RDS, etc. pueden ser retenidos según tu configuración.

### P: ¿Cuánto cuesta este proyecto?
**R:** Con AWS Free Tier: $0-5 USD/mes. Sin free tier: ~$15-30 USD/mes dependiendo del uso.

### P: ¿Puedo usar Terraform con otros proveedores?
**R:** Sí. Terraform soporta: AWS, Azure, GCP, Kubernetes, DigitalOcean, etc. Misma sintaxis.

### P: ¿Docker Compose es como Kubernetes?
**R:** No exactamente. Docker Compose es para desarrollo/testing. Kubernetes es para producción escalada.

### P: ¿Cómo manejo secrets como API keys?
**R:** Usa AWS Secrets Manager o variables de entorno encriptadas. Nunca hardcodees secrets en código.

---

## 👥 Contribuir

Si encuentras bugs o tienes mejoras:
1. Fork el proyecto
2. Crea rama: `git checkout -b fix/bug-name`
3. Commit: `git commit -am 'Fix: descripción'`
4. Push: `git push origin fix/bug-name`
5. Abre Pull Request

---

## 📞 Soporte

Para preguntas o problemas:
- GitHub Issues: [Tu repo]/issues
- Email: [tu-email]
- Slack: [tu-workspace]

---

## 📄 Licencia

Este proyecto está bajo licencia MIT. Ver archivo LICENSE para más detalles.

---

**Última actualización:** Enero 2026  
**Versión:** 2.0  
**Mantenedor:** Capgemini Team
   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Configure credentials:**
   Set up your cloud provider credentials (AWS, Azure, GCP, etc.)

## Workflow

### 1. **Plan Phase**
   Review infrastructure changes before applying:
   ```bash
   terraform plan -out=tfplan
   ```
   
   For specific environment:
   ```bash
   terraform plan -var-file="environments/dev/terraform.tfvars" -out=tfplan
   ```

### 2. **Review Phase**
   - Examine the plan output
   - Verify resources to be created, modified, or destroyed
   - Peer review recommended for production changes

### 3. **Apply Phase**
   Deploy infrastructure changes:
   ```bash
   terraform apply tfplan
   ```

### 4. **Validate Phase**
   Verify deployed resources:
   ```bash
   terraform validate
   ```

### 5. **Destroy Phase** (if needed)
   Remove infrastructure:
   ```bash
   terraform destroy -var-file="environments/dev/terraform.tfvars"
   ```

## Usage

### Deploy to Development
```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Deploy to Staging
```bash
terraform plan -var-file="environments/staging/terraform.tfvars"
terraform apply -var-file="environments/staging/terraform.tfvars"
```

### Deploy to Production
```bash
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### View Current State
```bash
terraform state list
terraform state show <resource-address>
```

### Refresh State
```bash
terraform refresh
```

## Best Practices

- **Use modules** for code reusability and organization
- **Separate environments** with distinct variable files
- **Use remote state** with Terraform Cloud or S3 backends
- **Version control** — commit .tf files, exclude tfstate files
- **Code review** — peer review all infrastructure changes
- **Lock files** — use `.terraform.lock.hcl` for dependency versioning
- **Naming conventions** — maintain consistent resource naming
- **Documentation** — document variables, outputs, and custom modules
- **Plan before apply** — always run `terraform plan` before `terraform apply`
- **Use workspaces** for environment isolation if needed

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and test locally
3. Run `terraform plan` and validate output
4. Commit changes: `git commit -m "Add your message"`
5. Push to repository: `git push origin feature/your-feature`
6. Create a Pull Request for review

## License

This project is licensed under the MIT License — see LICENSE file for details.
