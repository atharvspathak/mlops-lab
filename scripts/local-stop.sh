#!/bin/bash

echo "🛑 Stopping MLOps local environment..."

pkill -f "port-forward"
pkill -f "mlflow server"
fuser -k 5000/tcp 2>/dev/null
minikube stop

echo "✅ All services stopped"
