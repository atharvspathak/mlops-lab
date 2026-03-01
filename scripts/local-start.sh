#!/bin/bash

echo "🚀 Starting MLOps local environment..."

# ── 1. Start Minikube ──────────────────────────────────────
echo "Starting Minikube..."
minikube start --driver=docker --cpus=2 --memory=2048
echo "✅ Minikube started"

# ── 2. Apply Terraform ─────────────────────────────────────
echo "Applying Terraform..."
cd ~/mlops-lab/terraform/local
terraform apply -auto-approve
echo "✅ Terraform applied"

# ── 3. Wait for pods ───────────────────────────────────────
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=iris-serving \
  -n mlops \
  --timeout=120s
echo "✅ iris-serving pods ready"

# ── 4. Port forwards ───────────────────────────────────────
echo "Starting port forwards..."
pkill -f "port-forward" 2>/dev/null

kubectl port-forward svc/iris-serving-svc 8080:80 -n mlops &
echo "✅ iris-serving → http://localhost:8080"

kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring &
echo "✅ Grafana → http://localhost:3000 (admin/mlops123)"

kubectl port-forward svc/prometheus-stack-kube-prom-prometheus 9090:9090 -n monitoring &
echo "✅ Prometheus → http://localhost:9090"

# ── 5. Start MLflow ────────────────────────────────────────
cd ~/mlops-lab
source venv/bin/activate
mlflow server --host 0.0.0.0 --port 5000 &
echo "✅ MLflow → http://localhost:5000"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ MLOps local environment ready!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "iris-serving  → http://localhost:8080"
echo "MLflow UI     → http://localhost:5000"
echo "Grafana       → http://localhost:3000"
echo "Prometheus    → http://localhost:9090"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
