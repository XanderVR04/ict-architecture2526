FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]

# Usage (local build, alternative to the Docker Swarm config approach in poc.yaml):
#   docker build -t archief-api .
#   docker run -p 6000:5000 -e KEYCLOAK_URL=http://localhost:8080 archief-api
