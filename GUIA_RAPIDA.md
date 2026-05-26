# 🚀 Guía Rápida: Terraform + Docker + AWS

## 5 Minutos para Entender TODO

### 1️⃣ TERRAFORM: Infrastructure as Code

**¿Qué es?**
Código que crea infraestructura en AWS automáticamente.

**En 30 segundos:**
```
provider.tf     →  "Conectar a AWS"
variables.tf    →  "Qué parámetros usar (región, tipo instancia)"
main.tf         →  "Qué crear (VPC, EC2, Security Groups)"
outputs.tf      →  "Qué valores retornar (IPs, IDs)"
```

**Ciclo de vida:**
```
terraform init    →  Preparar proyecto
terraform plan    →  Ver qué cambios hace (IMPORTANTE)
terraform apply   →  Crear en AWS
terraform destroy →  Eliminar (cuando termines)
```

**Beneficios:**
✅ Reproducible - Mismo código = Mismo resultado siempre
✅ Versionable - Está en Git, ves histórico
✅ Escalable - Cambiar 1 instancia → 10 es un número
✅ Automático - No clics en AWS Console

---

### 2️⃣ DOCKER: Containerización

**¿Qué es?**
Empaquetar tu app con TODAS sus dependencias en una caja hermética.

**En 30 segundos:**
```
Dockerfile              →  "Receta para construir la imagen"
docker build            →  "Construir la imagen"
docker run              →  "Ejecutar un contenedor"
docker-compose.yml      →  "Orquestar varios contenedores"
```

**Beneficios:**
✅ Portabilidad - Funciona igual en laptop, servidor, AWS
✅ Aislamiento - No interfiere con otras cosas
✅ Reproducible - La app no cambia entre ambientes
✅ Ligero - Usa menos recursos que VMs

---

### 3️⃣ INTEGRACIÓN: Terraform + Docker + AWS

**Workflow:**

```
1. Desarrollo Local
   └─ docker-compose up
      └─ Tu app en contenedores en tu máquina
         └─ Visita http://localhost:8000

2. Infraestructura AWS
   └─ terraform init
   └─ terraform plan
   └─ terraform apply
      └─ Terraform crea VPC, EC2, etc. en AWS

3. Docker en EC2
   └─ Script automático instala Docker en la instancia
   └─ Tu app corre en contenedores en AWS
      └─ Accede a http://tu-ip-publica:8000

4. Terminar
   └─ terraform destroy
      └─ Elimina todo, pagas $0
```

---

## ⚡ Comandos Essenciales

### Para Desarrollo Local (Docker)
```bash
# Iniciar
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

### Para AWS (Terraform)
```bash
# Preparar
terraform init

# Ver cambios ANTES
terraform plan -var-file=environments/dev/terraform.tfvars

# Crear
terraform apply -var-file=environments/dev/terraform.tfvars

# Destruir
terraform destroy -var-file=environments/dev/terraform.tfvars
```

---

## 📊 Estructura Explicada

```
capgemini/
│
├── 🐳 Docker (Tu App)
│   ├── Dockerfile           ← Receta para construir imagen
│   ├── docker-compose.yml   ← Ejecuta múltiples contenedores
│   ├── index.html           ← Tu página web
│   ├── styles.css
│   └── server.py
│
├── 🏗️  Terraform (Infraestructura AWS)
│   ├── provider.tf          ← Conectar a AWS
│   ├── variables.tf         ← Variables (región, tipo instancia)
│   ├── main.tf              ← Recursos (VPC, EC2, Security Groups)
│   └── outputs.tf           ← Valores a retornar (IPs)
│
├── 🌍 Ambientes
│   └── environments/
│       ├── dev/             ← Para desarrollo
│       ├── staging/         ← Para pruebas
│       └── prod/            ← Para usuarios finales
│
└── 📝 Documentación
    ├── README.md            ← Documentación completa
    └── GUIA_RAPIDA.md       ← Este archivo
```

---

## 🎯 Casos de Uso

### Caso 1: Desarrollar Localmente
```bash
# 1. Iniciar Docker
docker-compose up -d

# 2. Abrir navegador
http://localhost:8000

# 3. Editar archivos (cambios se ven automáticamente)
# Editar index.html → F5 en navegador

# 4. Cuando termines
docker-compose down
```

### Caso 2: Subir a Producción
```bash
# 1. Revisar infraestructura
nano main.tf

# 2. Ver qué se va a crear
terraform plan -var-file=environments/prod/terraform.tfvars

# 3. Crear en AWS
terraform apply -var-file=environments/prod/terraform.tfvars

# 4. Obtener IP pública
terraform output instance_public_ip

# 5. Acceder
http://tu-ip-publica:8000
```

### Caso 3: Cambiar Ambiente
```bash
# De dev a staging
terraform destroy -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/staging/terraform.tfvars

# Diferencia automática:
# dev:     t3.micro,   1 instancia
# staging: t3.small,   2 instancias  
# prod:    t3.medium,  3+ instancias
```

---

## 🔧 Troubleshooting

### "Error: AWS Credentials"
```bash
# Verificar conexión a AWS
aws sts get-caller-identity

# Si falla, configurar:
aws configure
```

### "Error: docker not found"
```bash
# Instalar Docker
# Windows: https://www.docker.com/products/docker-desktop
# Linux:   sudo apt-get install docker-ce docker-compose
# Mac:     brew install docker docker-compose
```

### "Error: terraform not found"
```bash
# Descargar desde
https://www.terraform.io/downloads

# Agregar a PATH o usar ruta completa
C:\terraform\terraform init
```

### "Error: Port 8000 already in use"
```bash
# Cambiar puerto en docker-compose.yml
ports:
  - "8080:8000"  ← Cambiar primer número

# O matar proceso
lsof -ti:8000 | xargs kill -9    # Linux/Mac
Get-Process -Name python | Stop-Process  # Windows
```

### "terraform apply muy lento"
```bash
# Es normal, AWS tarda 2-5 minutos
# Ver progreso:
watch "aws ec2 describe-instances --query 'Reservations[*].Instances[*].State.Name'"
```

---

## 💰 Costos Estimados

### Con AWS Free Tier (Gratis)
- 12 meses: t2.micro/t3.micro gratuito
- Almacenamiento S3: 5 GB gratis
- Total: **$0 USD/mes**

### Sin Free Tier
- t3.micro: ~$7 USD/mes
- Transferencia de datos: ~$5 USD/mes
- Total: **~$12-15 USD/mes**

### Cómo ahorrar
```bash
# Destruye cuando no usas
terraform destroy

# Usa t3.micro (más barato)
instance_type = "t3.micro"

# Usa us-east-1 (región más barata)
region = "us-east-1"

# Apaga instancias por la noche
aws ec2 stop-instances --instance-ids i-xxxxx
```

---

## 📚 Lo Que Aprendiste

| Tema | Lo Básico |
|---|---|
| **Terraform** | Código para crear infraestructura automáticamente |
| **Docker** | Empaquetar app con dependencias en contenedor |
| **AWS** | Nube donde corren tus recursos |
| **Variables** | Parámetros reutilizables (región, tipo instancia) |
| **Ambientes** | dev, staging, prod con diferentes configuraciones |
| **Outputs** | Valores que Terraform retorna (IPs, IDs) |

---

## 🎓 Próximos Pasos

1. **Domina Terraform**
   - Aprende módulos reutilizables
   - Usa remote state (S3)
   - Implementa auto-scaling

2. **Domina Docker**
   - Crea tu propia imagen personalizada
   - Usa Docker Networks avanzadas
   - Push a Docker Hub

3. **DevOps Avanzado**
   - CI/CD con GitHub Actions
   - Kubernetes para orquestación
   - Terraform + Kubernetes

---

## 🔗 Links Útiles

- Terraform: https://www.terraform.io/
- Docker: https://www.docker.com/
- AWS: https://aws.amazon.com/
- Learn Terraform: https://learn.hashicorp.com/terraform
- Docker Academy: https://docker-curriculum.com/

---

## 💡 Recuerda

```
┌─────────────────────────────────────────┐
│  "Plan, Verify, Apply, Destroy"        │
│                                         │
│  Siempre ejecuta terraform plan        │
│  ANTES de terraform apply              │
│                                         │
│  Una vez termines, terraform destroy   │
│  para no pagar de más                  │
└─────────────────────────────────────────┘
```

---

**¿Necesitas ayuda?** Lee README.md para documentación detallada.

**Last Update:** Enero 2026