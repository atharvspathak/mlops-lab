# MLOps Lab

A complete MLOps platform built from scratch — experiment tracking, model registry, containerized serving, Kubernetes deployment, CI/CD pipeline, and monitoring.

## Architecture
```
Developer pushes code
        ↓
GitHub Actions (CI/CD)
  ├── Train model (MLflow tracked)
  ├── Register model (MLflow Registry)
  ├── Build Docker image (versioned)
  └── Verify predictions
        ↓
Docker image on ECR/DockerHub
        ↓
Kubernetes deployment (Minikube/GKE/EKS)
  ├── 2 replicas
  ├── Health + readiness probes
  └── FastAPI serving predictions
        ↓
Prometheus scraping /metrics
        ↓
Grafana dashboards
```

## Stack

| Component | Tool |
|---|---|
| Experiment Tracking | MLflow |
| Model Registry | MLflow Registry |
| Model Serving | FastAPI + Uvicorn |
| Containerization | Docker |
| Container Registry | ECR / DockerHub |
| Infrastructure as Code | Terraform |
| Orchestration | Kubernetes |
| CI/CD | GitHub Actions |
| Metrics | Prometheus |
| Dashboards | Grafana |
| Cloud | AWS (S3, ECR) |

## Project Structure
```
mlops-lab/
├── .github/
│   └── workflows/
│       └── mlops-pipeline.yml    # CI/CD pipeline
├── manifests/
│   ├── app/
│   │   ├── deployment.yaml       # K8s deployment
│   │   └── service.yaml          # K8s service
│   ├── monitoring/
│   │   └── servicemonitor.yaml   # Prometheus scrape config
│   └── namespaces/
│       ├── mlops.yaml            # mlops namespace
│       └── monitoring.yaml       # monitoring namespace
├── scripts/
│   ├── train.py                  # Train + track with MLflow
│   ├── register_model.py         # Register best model
│   ├── serve.py                  # FastAPI serving API
│   ├── save_model.py             # Save model to local file
│   ├── local-start.sh            # Start local environment
│   └── local-stop.sh             # Stop local environment
├── terraform/
│   ├── local/                    # Minikube + K8s + monitoring
│   │   ├── main.tf
│   │   ├── k8s.tf
│   │   └── monitoring.tf
│   └── aws/                      # S3 + ECR + IAM
│       ├── main.tf
│       ├── variables.tf
│       └── aws.tf
├── Dockerfile                    # Container definition
├── requirements.txt              # Full dev dependencies
└── requirements_serve.txt        # Minimal serving dependencies
```

## Quick Start

### Prerequisites
- WSL2 (Ubuntu 22.04)
- Docker
- Minikube
- kubectl
- Terraform
- Python 3.11

### Local Development

**Start everything:**
```bash
mlops-start
```

**Activate Python environment:**
```bash
mlops
```

**Train a model:**
```bash
python scripts/train.py
```

**Register best model:**
```bash
python scripts/register_model.py
```

**Test prediction:**
```bash
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}'
```

**Stop everything:**
```bash
mlops-stop
```

### Services

| Service | URL | Credentials |
|---|---|---|
| iris-serving API | http://localhost:8080 | - |
| API Docs (Swagger) | http://localhost:8080/docs | - |
| MLflow UI | http://localhost:5000 | - |
| Grafana | http://localhost:3000 | admin / mlops123 |
| Prometheus | http://localhost:9090 | - |

### CI/CD Pipeline

Push to `main` branch triggers:
1. Train model + track with MLflow
2. Register best model
3. Build Docker image tagged with `{run_number}-{commit_sha}`
4. Push to DockerHub
5. Health check + prediction verification

### AWS Infrastructure
```bash
cd terraform/aws
terraform init
terraform apply
```

Provisions:
- S3 bucket for model artifacts
- ECR repository for Docker images
- IAM user for GitHub Actions

## Model API

### Health Check
```bash
GET /health
```

### Predict
```bash
POST /predict
{
  "sepal_length": 5.1,
  "sepal_width": 3.5,
  "petal_length": 1.4,
  "petal_width": 0.2
}
```

Response:
```json
{
  "species_id": 0,
  "species_name": "setosa",
  "confidence": 0.9985
}
```

## Monitoring

Prometheus scrapes `/metrics` from iris-serving pods every 15s.

Key metrics:
- `http_requests_total` — total requests by endpoint
- `http_request_duration_seconds` — request latency
- `python_gc_objects_collected_total` — GC stats

## Author

Atharv Pathak — DevOps → MLOps transition
