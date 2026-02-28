# ── Base Image ─────────────────────────────────────────────
FROM python:3.11-slim

# ── Set Working Directory ──────────────────────────────────
WORKDIR /app

# ── Install Dependencies ───────────────────────────────────
COPY requirements_serve.txt .
RUN pip install --no-cache-dir -r requirements_serve.txt

# ── Copy Model ─────────────────────────────────────────────
COPY models/iris-classifier /app/models/iris-classifier

# ── Copy Serving Script ────────────────────────────────────
COPY scripts/serve.py .

# ── Expose Port ────────────────────────────────────────────
EXPOSE 8000

# ── Run Server ─────────────────────────────────────────────
CMD ["python", "serve.py"]
