import mlflow
import mlflow.sklearn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
import uvicorn
from prometheus_fastapi_instrumentator import Instrumentator


# ── 1. Load Model from Registry ────────────────────────────
model_name = "iris-classifier"
model_alias = "staging"
model_path = "/app/models/iris-classifier"

print(f"Loading model from: {model_path}")
model = mlflow.sklearn.load_model(model_path)
print(f"Model loaded successfully!")

# ── 2. Define FastAPI App ──────────────────────────────────
app = FastAPI(
    title="Iris Classifier API",
    description="MLOps Lab — Model Serving with FastAPI + MLflow",
    version="1.0.0"
)

# ── Prometheus Metrics ─────────────────────────────────────
Instrumentator().instrument(app).expose(app)

# ── 3. Define Request Schema ───────────────────────────────
class IrisFeatures(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float

# ── 4. Define Response Schema ──────────────────────────────
class PredictionResponse(BaseModel):
    species_id: int
    species_name: str
    confidence: float

# ── 5. Species Mapping ─────────────────────────────────────
SPECIES = {
    0: "setosa",
    1: "versicolor",
    2: "virginica"
}

# ── 6. Health Check Endpoint ───────────────────────────────
@app.get("/health")
def health():
    return {
        "status": "healthy",
        "model": model_name,
        "alias": model_alias
    }

# ── 7. Predict Endpoint ────────────────────────────────────
@app.post("/predict", response_model=PredictionResponse)
def predict(features: IrisFeatures):
    try:
        # Convert input to numpy array
        input_data = np.array([[
            features.sepal_length,
            features.sepal_width,
            features.petal_length,
            features.petal_width
        ]])

        # Get prediction
        prediction = model.predict(input_data)[0]

        # Get confidence (probability of predicted class)
        probabilities = model.predict_proba(input_data)[0]
        confidence = float(probabilities[prediction])

        return PredictionResponse(
            species_id=int(prediction),
            species_name=SPECIES[int(prediction)],
            confidence=round(confidence, 4)
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ── 8. Run Server ──────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
