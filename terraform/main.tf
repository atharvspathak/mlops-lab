terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Create requirements.txt
resource "local_file" "requirements" {
  filename = "/home/${var.username}/mlops-lab/requirements.txt"
  content  = <<-EOT
    # Experiment Tracking
    mlflow==2.11.1

    # Data versioning
    dvc==3.49.0

    # ML libraries
    scikit-learn==1.4.1.post1
    pandas==2.2.1
    numpy==1.26.4

    # Model serving
    fastapi==0.110.0
    uvicorn==0.27.1

    # Monitoring
    evidently==0.4.22

    # AWS SDK (for later phase)
    boto3==1.34.52

    # Utilities
    jupyter==1.0.0
    ipykernel==6.29.3
    requests==2.31.0
  EOT
}

# Create virtual environment
resource "null_resource" "create_venv" {
  provisioner "local-exec" {
    command = "python3.11 -m venv /home/${var.username}/mlops-lab/venv"
  }

  depends_on = [local_file.requirements]
}

# Install requirements inside venv
resource "null_resource" "install_requirements" {
  provisioner "local-exec" {
    command = "/home/${var.username}/mlops-lab/venv/bin/pip install -r /home/${var.username}/mlops-lab/requirements.txt"
  }

  depends_on = [null_resource.create_venv]
}

