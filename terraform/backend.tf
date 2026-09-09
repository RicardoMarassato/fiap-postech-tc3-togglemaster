# =============================================================================
# Backend Remoto - S3
# =============================================================================
# IMPORTANTE: O bucket S3 deve ser criado ANTES de rodar terraform init
# Execute: aws s3 mb s3://togglemaster-terraform-state-<504636433271> --region us-east-1
# =============================================================================

terraform {
  backend "s3" {
    bucket       = "tf-state-toggle-master-504636433271"
    key          = "togglemaster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # Terraform 1.10+ native locking
  }
}
