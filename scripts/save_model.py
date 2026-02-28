import mlflow
import mlflow.sklearn
import os

# Connect to MLflow
mlflow.set_tracking_uri("http://localhost:5000")

# Load model from registry
model_uri = "models:/iris-classifier@staging"
model = mlflow.sklearn.load_model(model_uri)

# Save locally
os.makedirs("models/iris-classifier", exist_ok=True)
mlflow.sklearn.save_model(model, "models/iris-classifier")

print("Model saved to models/iris-classifier/")
