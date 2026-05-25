# 🐳 Ejecutar Capgemini con Docker

Este documento explica cómo ejecutar el proyecto Capgemini usando Docker y Docker Compose.

## Requisitos Previos

- Docker instalado ([descargar](https://www.docker.com/products/docker-desktop))
- Docker Compose (incluido con Docker Desktop)
- Git para clonar el repositorio

## Estructura de Puertos

El proyecto utiliza dos puertos principales:

| Puerto | Servicio | Descripción |
|--------|----------|-------------|
| **8000** | Aplicación Web | Página principal y equipo (HTML/CSS/JS) |
| **8001** | API de Datos | Datos en JSON (team.json, projects.json) |
| **3996** | Desarrollo Local | Servidor Python local (alternativo) |

## Inicio Rápido

### 1. Opción A: Usar Docker Compose (Recomendado)

```bash
# Navegar al directorio del proyecto
cd c:\Users\jupar\OneDrive\Escritorio\Capgemini

# Compilar y ejecutar los contenedores
docker-compose up -d

# Ver logs de los contenedores
docker-compose logs -f

# Detener los contenedores
docker-compose down
```

### 2. Opción B: Compilar y ejecutar manualmente

```bash
# Compilar la imagen Docker
docker build -t capgemini-web .

# Ejecutar el contenedor
docker run -d \
  --name capgemini-web \
  -p 8000:8000 \
  -v $(pwd):/app \
  capgemini-web

# Para el servidor API en otro terminal
docker run -d \
  --name capgemini-api \
  -p 8001:8001 \
  -v $(pwd)/data:/app/data \
  python:3.11-slim \
  python -m http.server 8001 --directory /app/data
```

## Acceso a la Aplicación

Una vez que los contenedores están ejecutándose:

### 🌐 Página Principal
**URL:** [http://localhost:8000](http://localhost:8000)

- Información del proyecto
- Características principales
- Stack tecnológico
- Comandos Terraform
- Enlace a la página de equipo

### 👥 Página de Equipo
**URL:** [http://localhost:8000/team.html](http://localhost:8000/team.html)

- Información del equipo
- Perfiles profesionales
- Skills y experiencia
- Datos del contacto

### 📊 API de Datos
**URLs disponibles:**
- [http://localhost:8001/team.json](http://localhost:8001/team.json) - Información del equipo en JSON
- [http://localhost:8001/projects.json](http://localhost:8001/projects.json) - Proyectos en JSON

## Comandos Docker Útiles

```bash
# Ver contenedores en ejecución
docker ps

# Ver todos los contenedores (incluyendo detenidos)
docker ps -a

# Ver logs de un contenedor
docker logs capgemini-web
docker logs -f capgemini-api

# Entrar a un contenedor
docker exec -it capgemini-web /bin/bash

# Detener un contenedor
docker stop capgemini-web

# Iniciar un contenedor detenido
docker start capgemini-web

# Eliminar un contenedor
docker rm capgemini-web

# Eliminar una imagen
docker rmi capgemini-web
```

## Monitoreo y Troubleshooting

### Ver estado de los servicios
```bash
docker-compose ps
```

### Ver logs en tiempo real
```bash
docker-compose logs -f web
docker-compose logs -f team-api
```

### Reiniciar los servicios
```bash
docker-compose restart
```

### Verificar conectividad
```bash
# Desde PowerShell
Invoke-WebRequest -Uri "http://localhost:8000" -UseBasicParsing

# Desde terminal
curl http://localhost:8000
curl http://localhost:8001/team.json
```

## Edición de Archivos

Los archivos están mapeados en volúmenes, por lo que puedes editar:

- `index.html` - Página principal
- `team.html` - Página de equipo
- `styles.css` - Estilos CSS
- `data/team.json` - Datos del equipo
- `data/projects.json` - Proyectos

Los cambios se reflejarán automáticamente en los contenedores ejecutados.

## Construcción y Deploy en Producción

### Construir imagen para producción
```bash
docker build -t capgemini-web:latest .
docker build -t capgemini-web:1.0.0 .
```

### Publicar en Docker Hub (opcional)
```bash
# Hacer login en Docker Hub
docker login

# Taggear la imagen
docker tag capgemini-web:latest tuusuario/capgemini-web:latest

# Subir la imagen
docker push tuusuario/capgemini-web:latest
```

### Ejecutar en producción
```bash
docker run -d \
  --name capgemini-prod \
  -p 8000:8000 \
  --restart always \
  capgemini-web:latest
```

## Arquitectura

```
┌─────────────────────────────────────┐
│      Docker Network (bridge)        │
├─────────────────────────────────────┤
│                                     │
│  ┌────────────────────────────┐    │
│  │   capgemini-web (8000)     │    │
│  │  - index.html              │    │
│  │  - team.html               │    │
│  │  - styles.css              │    │
│  │  - Python HTTP Server      │    │
│  └────────────────────────────┘    │
│                                     │
│  ┌────────────────────────────┐    │
│  │   capgemini-team-api (8001)│    │
│  │  - team.json               │    │
│  │  - projects.json           │    │
│  │  - Python HTTP Server      │    │
│  └────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
         ↓            ↓
      http://localhost:8000
      http://localhost:8001
```

## Preguntas Frecuentes

**P: ¿Por qué no se ve mi sitio?**
R: Asegúrate de que los contenedores están ejecutándose con `docker ps`. Si no, ejecuta `docker-compose up -d`.

**P: ¿Cómo cambio los puertos?**
R: Edita `docker-compose.yml` y cambia los puertos en la sección `ports`. Ejemplo: `"9000:8000"`.

**P: ¿Puedo ejecutar esto sin Docker Compose?**
R: Sí, usa los comandos en "Opción B" arriba.

**P: ¿Cómo acceso desde otra máquina?**
R: Cambia `localhost` por la IP de tu máquina. Ejemplo: `http://192.168.1.100:8000`

## Soporte

Para más información sobre Docker:
- [Documentación Docker](https://docs.docker.com/)
- [Documentación Docker Compose](https://docs.docker.com/compose/)

Para más información sobre el proyecto:
- [GitHub Repository](https://github.com/jramirezma50/Capgemini)
- Email: devops@capgemini.com
