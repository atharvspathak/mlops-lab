import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score
import pandas as pd
import numpy as np
import os
import mlflow

# ── MLflow Tracking ────────────────────────────────────────
tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
mlflow.set_tracking_uri(tracking_uri)

# ── 1. Load Data ───────────────────────────────────────────
iris = load_iris()
X = pd.DataFrame(iris.data, columns=iris.feature_names)
y = iris.target

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# ── 2. Define Parameters ───────────────────────────────────
params = {
    "n_estimators": 200,
    "max_depth": 2,
    "random_state": 42
}

# ── 3. MLflow Experiment ───────────────────────────────────
mlflow.set_experiment("iris-classification")

with mlflow.start_run():

    # Train model
    model = RandomForestClassifier(**params)
    model.fit(X_train, y_train)

    # Evaluate
    predictions = model.predict(X_test)
    accuracy = accuracy_score(y_test, predictions)
    f1 = f1_score(y_test, predictions, average="weighted")

    # Log parameters
    mlflow.log_params(params)

    # Log metrics
    mlflow.log_metric("accuracy", accuracy)
    mlflow.log_metric("f1_score", f1)

    # Log model
    mlflow.sklearn.log_model(model, "model")

    print(f"Parameters : {params}")
    print(f"Accuracy   : {accuracy:.4f}")
    print(f"F1 Score   : {f1:.4f}")
    print(f"Run ID     : {mlflow.active_run().info.run_id}")

    os.makedirs("models/iris-classifier", exist_ok=True)
    mlflow.sklearn.save_model(model, "models/iris-classifier")
    print(f"Model saved to models/iris-classifier/")
