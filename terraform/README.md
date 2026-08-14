# ToggleMaster - Infraestrutura como Código (Terraform)

Código Terraform para provisionar toda a infraestrutura do ToggleMaster na AWS.

## Arquitetura Provisionada

| Recurso | Descrição |
|---------|-----------|
| **VPC** | VPC com subnets públicas e privadas em 2 AZs |
| **EKS** | Cluster Kubernetes 1.29 com Node Group |
| **RDS** | 3 instâncias PostgreSQL 16 (auth, flags, targeting) |
| **ElastiCache** | Cluster Redis 7.1 |
| **DynamoDB** | Tabela ToggleMasterAnalytics |
| **SQS** | Fila de eventos com DLQ |
| **ECR** | 5 repositórios de container |

## Pré-requisitos

1. **Terraform** >= 1.5.0
2. **AWS CLI** configurado
3. **kubectl** (para interagir com o EKS)
4. **Bucket S3** para remote state

## Setup Inicial

### 1. Criar bucket S3 para o state (apenas uma vez)

```bash
aws s3 mb s3://togglemaster-terraform-state --region us-east-1
```

### 2. Configurar variáveis

```bash
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars conforme necessário
```

### 3. Inicializar Terraform

```bash
terraform init
```

## Deploy

### Plan (visualizar mudanças)

```bash
terraform plan
```

### Apply (aplicar mudanças)

```bash
terraform apply
```

### Destroy (remover tudo)

```bash
terraform destroy
```

## AWS Academy (LabRole)

Este código está configurado para funcionar com o AWS Academy usando a **LabRole** existente.

**Restrições do AWS Academy:**
- Não é possível criar IAM Roles ou Policies via Terraform
- O Terraform usa a LabRole existente via data source

Para usar com conta pessoal, altere no `terraform.tfvars`:

```hcl
use_lab_role = false
lab_role_arn = "arn:aws:iam::SEU_ACCOUNT_ID:role/SuaRole"
```

## Configurar kubectl após deploy

Após o `terraform apply`, execute:

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-dev-eks
```

Ou use o output do Terraform:

```bash
$(terraform output -raw eks_configure_kubectl)
```

## Outputs Importantes

| Output | Descrição |
|--------|-----------|
| `eks_cluster_endpoint` | Endpoint do cluster EKS |
| `ecr_repository_urls` | URLs dos repositórios ECR |
| `rds_endpoints` | Endpoints das instâncias RDS |
| `redis_url` | URL de conexão do Redis |
| `sqs_queue_url` | URL da fila SQS |

Ver todos os outputs:

```bash
terraform output
```

## Estrutura de Módulos

```
terraform/
├── main.tf              # Orquestração dos módulos
├── variables.tf         # Variáveis de entrada
├── outputs.tf           # Outputs exportados
├── providers.tf         # Configuração de providers
├── backend.tf           # Backend S3 para state
├── versions.tf          # Versões requeridas
├── data.tf              # Data sources (LabRole)
└── modules/
    ├── networking/      # VPC, Subnets, IGW, NAT
    ├── eks/             # EKS Cluster e Node Groups
    ├── rds/             # Instâncias PostgreSQL
    ├── elasticache/     # Cluster Redis
    ├── dynamodb/        # Tabela Analytics
    ├── sqs/             # Fila de Mensageria
    └── ecr/             # Repositórios de Container
```

## Custos Estimados

Para ambiente de desenvolvimento (t3.micro/small):
- **EKS Cluster**: ~$0.10/hora
- **EKS Nodes** (2x t3.medium): ~$0.08/hora
- **RDS** (3x db.t3.micro): ~$0.05/hora
- **ElastiCache** (cache.t3.micro): ~$0.02/hora
- **NAT Gateway**: ~$0.05/hora + transferência
- **Total estimado**: ~$0.30/hora ou ~$220/mês

> **Dica**: Destrua a infraestrutura quando não estiver usando para economizar!

## Troubleshooting

### Erro de permissão IAM

Se estiver usando AWS Academy e receber erro de IAM:
```
Error: Error creating IAM Role
```

Verifique se `use_lab_role = true` no `terraform.tfvars`.

### EKS nodes não conectam

Verifique se o NAT Gateway foi criado e as subnets privadas têm rota para ele.

### Timeout no RDS

RDS pode levar 10-15 minutos para ser criado. Aguarde pacientemente.
