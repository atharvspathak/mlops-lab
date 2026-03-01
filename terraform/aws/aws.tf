# ── AWS Provider ────────────────────────────────────────────

# ── S3 Bucket — MLflow + Model Artifacts ───────────────────
resource "aws_s3_bucket" "mlops_artifacts" {
  bucket = "${var.project_name}-artifacts-${var.aws_account_id}"

  tags = {
    Project     = var.project_name
    Environment = "local"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "mlops_artifacts" {
  bucket = aws_s3_bucket.mlops_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mlops_artifacts" {
  bucket = aws_s3_bucket.mlops_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ── ECR Repository — Docker Images ─────────────────────────
resource "aws_ecr_repository" "iris_serving" {
  name                 = "${var.project_name}/iris-serving"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# ── ECR Lifecycle Policy — Keep last 10 images ─────────────
resource "aws_ecr_lifecycle_policy" "iris_serving" {
  repository = aws_ecr_repository.iris_serving.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ── IAM User for GitHub Actions ────────────────────────────
resource "aws_iam_user" "github_actions" {
  name = "${var.project_name}-github-actions"

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_user_policy" "github_actions" {
  name = "${var.project_name}-github-actions-policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.mlops_artifacts.arn,
          "${aws_s3_bucket.mlops_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# ── Outputs ─────────────────────────────────────────────────
output "s3_bucket_name" {
  value = aws_s3_bucket.mlops_artifacts.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.iris_serving.repository_url
}

output "github_actions_access_key" {
  value     = aws_iam_access_key.github_actions.id
  sensitive = false
}

output "github_actions_secret_key" {
  value     = aws_iam_access_key.github_actions.secret
  sensitive = true
}
