FROM python:3.11-slim

WORKDIR /app

# Copiar archivos del proyecto
COPY index.html .
COPY team.html .
COPY styles.css .

# Exponer puerto 8000
EXPOSE 8000

# Comando para ejecutar el servidor
CMD ["python", "-m", "http.server", "8000"]
