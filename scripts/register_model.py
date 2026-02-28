import mlflow
from mlflow.tracking import MlflowClient

# ── 1. Connect to MLflow ───────────────────────────────────
client = MlflowClient()

# ── 2. Get Best Run ────────────────────────────────────────
experiment = client.get_experiment_by_name("iris-classification")
runs = client.search_runs(
    experiment_ids=[experiment.experiment_id],
    order_by=["metrics.accuracy DESC"],
    max_results=1
)

best_run = runs[0]
best_run_id = best_run.info.run_id
best_accuracy = best_run.data.metrics["accuracy"]

print(f"Best Run ID  : {best_run_id}")
print(f"Best Accuracy: {best_accuracy:.4f}")

# ── 3. Register Model ──────────────────────────────────────
model_name = "iris-classifier"
model_uri = f"runs:/{best_run_id}/model"

registered = mlflow.register_model(
    model_uri=model_uri,
    name=model_name
)

print(f"\nModel registered successfully!")
print(f"Model Name   : {registered.name}")
print(f"Model Version: {registered.version}")

# ── 4. Set Staging Alias ───────────────────────────────────
client.set_registered_model_alias(
    name=model_name,
    alias="staging",
    version=registered.version
)

print(f"\nAlias 'staging' set on Version {registered.version}")

# ── 5. Verify Registration ─────────────────────────────────
model_version = client.get_model_version_by_alias(
    name=model_name,
    alias="staging"
)

print(f"\nVerification:")
print(f"Name   : {model_version.name}")
print(f"Version: {model_version.version}")
print(f"Aliases: {model_version.aliases}")
print(f"Run ID : {model_version.run_id}")
print(f"Source : {model_version.source}")
