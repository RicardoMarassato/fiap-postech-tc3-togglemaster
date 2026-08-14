# =============================================================================
# Backend Remoto - S3
# =============================================================================
# IMPORTANTE: O bucket S3 deve ser criado ANTES de rodar terraform init
# Execute: aws s3 mb s3://togglemaster-terraform-state-<ACCOUNT_ID> --region us-east-1
# =============================================================================

terraform {
  backend "s3" {
    bucket       = "togglemaster-terraform-state"  # Altere para seu bucket
    key          = "togglemaster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true  # Terraform 1.10+ native locking
  }
}
