# =============================================================================
# ToggleMaster - Infraestrutura Principal
# =============================================================================
# Este arquivo orquestra todos os módulos para criar a infraestrutura completa
# do ToggleMaster na AWS, incluindo:
# - Networking (VPC, Subnets, IGW, NAT, Route Tables)
# - EKS (Cluster Kubernetes e Node Groups)
# - RDS (3 instâncias PostgreSQL)
# - ElastiCache (Redis)
# - DynamoDB (Analytics)
# - SQS (Fila de Mensageria)
# - ECR (5 Repositórios de Container)
# =============================================================================

locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
  name_prefix  = "${var.project_name}-${var.environment}"
}

# =============================================================================
# 1. Networking
# =============================================================================
module "networking" {
  source = "./modules/networking"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = local.cluster_name
  enable_nat_gateway   = true  # Necessário para nodes privados acessarem ECR
}

# =============================================================================
# 2. EKS Cluster
# =============================================================================
module "eks" {
  source = "./modules/eks"

  name_prefix     = local.name_prefix
  cluster_name    = local.cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id          = module.networking.vpc_id
  subnet_ids      = concat(module.networking.public_subnet_ids, module.networking.private_subnet_ids)
  node_subnet_ids = module.networking.private_subnet_ids  # Nodes em subnets privadas

  # AWS Academy - usar LabRole
  use_lab_role = var.use_lab_role
  lab_role_arn = local.lab_role_arn

  # Node Group config
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size

  depends_on = [module.networking]
}

# =============================================================================
# 3. RDS - PostgreSQL (3 instâncias)
# =============================================================================
module "rds" {
  source = "./modules/rds"

  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids

  # Permitir acesso do EKS nodes
  allowed_security_group_ids = [module.eks.node_security_group_id]

  # Configuração das instâncias
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  engine_version    = var.rds_engine_version
  multi_az          = var.rds_multi_az

  # Bancos de dados: auth, flags, targeting
  databases = [
    { name = "auth", db_name = "auth_db", username = "auth_admin" },
    { name = "flags", db_name = "flags_db", username = "flags_admin" },
    { name = "targeting", db_name = "targeting_db", username = "targeting_admin" }
  ]

  depends_on = [module.networking, module.eks]
}

# =============================================================================
# 4. ElastiCache - Redis
# =============================================================================
module "elasticache" {
  source = "./modules/elasticache"

  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids

  # Permitir acesso do EKS nodes
  allowed_security_group_ids = [module.eks.node_security_group_id]

  # Configuração
  node_type       = var.redis_node_type
  num_cache_nodes = var.redis_num_cache_nodes
  engine_version  = var.redis_engine_version

  depends_on = [module.networking, module.eks]
}

# =============================================================================
# 5. DynamoDB - Analytics
# =============================================================================
module "dynamodb" {
  source = "./modules/dynamodb"

  name_prefix  = local.name_prefix
  table_name   = "ToggleMasterAnalytics"
  billing_mode = var.dynamodb_billing_mode

  # Features
  enable_ttl                    = true
  enable_point_in_time_recovery = true
  enable_streams                = false
}

# =============================================================================
# 6. SQS - Fila de Eventos
# =============================================================================
module "sqs" {
  source = "./modules/sqs"

  name_prefix = local.name_prefix
  queue_name  = "events"

  # Configuração
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600  # 4 dias

  # DLQ
  enable_dlq        = true
  max_receive_count = 3
}

# =============================================================================
# 7. ECR - Repositórios de Container
# =============================================================================
module "ecr" {
  source = "./modules/ecr"

  name_prefix = var.project_name

  repositories = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service"
  ]

  # Configuração
  image_tag_mutability    = var.ecr_image_tag_mutability
  scan_on_push            = var.ecr_scan_on_push
  enable_lifecycle_policy = true
  max_image_count         = 10
  max_tagged_image_count  = 30
}
