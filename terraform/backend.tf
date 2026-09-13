# =============================================================================
# Backend Remoto - S3
# =============================================================================

terraform {
  backend "s3" {
    bucket       = "toggle-master-tc3"
    key          = "togglemaster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # Terraform 1.10+ native locking
  }
}
