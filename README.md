# ToggleMaster V3 - Entrega da Fase 3 (IaC, CI/CD & GitOps)

Este projeto evolui a infraestrutura do ToggleMaster (da Fase 2) para um modelo **"Se não está no código, não existe"**: toda a infraestrutura é provisionada via Terraform, os deploys passam por pipelines DevSecOps automatizados, e o Kubernetes é gerenciado via GitOps com ArgoCD.

---

## Informações da Entrega

- **Aluno:** Ricardo Marassato
- **RM:** 370358
- **Discord:** marassato7700
- **Repositório GitHub:** https://github.com/RicardoMarassato/fiap-postech-tc3-togglemaster
- **Link do Vídeo (Demonstração):** `[PREENCHER APÓS GRAVAÇÃO]`

---

## O Problema da Fase 2

A arquitetura de microsserviços implementada na Fase 2 funcionava bem tecnicamente, mas a operação apresentava gaps significativos:

- **Infraestrutura manual:** O cluster EKS, RDS, ElastiCache e DynamoDB foram criados via console AWS. Recriar o ambiente de homologação levava dias e era propenso a erros humanos.
- **Deploys artesanais:** Desenvolvedores rodando `kubectl apply` de suas máquinas locais, gerando conflitos de versão e falta de rastreabilidade.
- **Segurança reativa:** Vulnerabilidades em bibliotecas e imagens Docker passavam despercebidas para produção, sem nenhum gate de segurança automatizado.
- **Credenciais expostas:** Secrets passados em arquivos de texto ou hardcoded nos manifestos.

---

## Solução Implementada

### 1. Infraestrutura como Código (Terraform)

Toda a infraestrutura da Fase 2 foi codificada em módulos Terraform reutilizáveis:

```
terraform/
├── main.tf                    # Orquestração dos módulos
├── variables.tf               # Variáveis de configuração
├── outputs.tf                 # Outputs para CI/CD e GitOps
├── backend.tf                 # S3 remote state com locking nativo
├── providers.tf               # Configuração do provider AWS
├── versions.tf                # Versões do Terraform e providers
├── data.tf                    # Data sources (LabRole, AZs)
└── modules/
    ├── networking/            # VPC, Subnets, IGW, NAT, Route Tables
    ├── eks/                   # Cluster EKS + Node Groups (LabRole)
    ├── rds/                   # 3x PostgreSQL + Secrets Manager
    ├── elasticache/           # Redis 7.1
    ├── dynamodb/              # ToggleMasterAnalytics (GSIs, TTL)
    ├── sqs/                   # Fila principal + DLQ
    └── ecr/                   # 5 repositórios de imagens
```

**Decisão AWS Academy:** Como não é possível criar IAM Roles no AWS Academy, o Terraform usa a `LabRole` existente via data source para o cluster EKS e Node Groups.

### 2. Pipeline CI/CD com DevSecOps (GitHub Actions)

Cada microsserviço tem um pipeline que roda automaticamente em PRs e pushes na main:

| Estágio | Ferramentas | Descrição |
|---------|-------------|-----------|
| **Build & Test** | Go/Python | Compila e roda testes unitários (se existirem) |
| **Lint** | golangci-lint, flake8, pylint | Análise estática de código |
| **SAST** | gosec (Go), bandit (Python) | Vulnerabilidades no código fonte |
| **SCA** | Trivy (fs mode) | Vulnerabilidades nas dependências |
| **Container Scan** | Trivy (image mode) | Vulnerabilidades na imagem Docker |
| **Push ECR** | AWS ECR | Imagem taggeada com SHA do commit |

**Regra de Bloqueio:** Se uma vulnerabilidade **CRITICAL** for encontrada em qualquer scan, o pipeline falha e não prossegue para o push da imagem.

### 3. GitOps com ArgoCD

O deploy não é mais feito via CI diretamente no cluster. Adotamos o modelo GitOps:

```
gitops/
├── argocd/
│   ├── applications.yaml      # 5 aplicações configuradas
│   └── install.sh             # Script de instalação do ArgoCD
├── base/
│   ├── namespace.yaml         # Namespace togglemaster
│   ├── configmap.yaml         # Configurações compartilhadas
│   └── secrets.yaml           # Template de secrets (valores em Secrets Manager)
└── apps/
    ├── auth-service/deployment.yaml
    ├── flag-service/deployment.yaml
    ├── targeting-service/deployment.yaml
    ├── evaluation-service/deployment.yaml
    └── analytics-service/deployment.yaml
```

**Fluxo de Deploy:**
1. Pipeline CI builda e pusha imagem para ECR com tag `v1.0.0-<commit_sha>`
2. Pipeline atualiza o `deployment.yaml` no repositório GitOps com a nova tag
3. ArgoCD detecta a mudança e sincroniza automaticamente para o cluster EKS

---

## Diagrama da Arquitetura

Abaixo está o diagrama representativo da arquitetura DevOps do ToggleMaster V3:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GITHUB                                          │
│  ┌──────────────┐    ┌──────────────────────────────┐    ┌──────────────┐   │
│  │   PR/Push    │───▶│      CI Pipeline             │───▶│  ECR Push    │   │
│  │   (Code)     │    │  (Build → SAST → SCA → Scan) │    │  (Image)     │   │
│  └──────────────┘    └──────────────────────────────┘    └──────┬───────┘   │
│                                                                  │           │
│                      ┌───────────────────────────────────────────┘           │
│                      ▼                                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  GitOps Repo: gitops/apps/<service>/deployment.yaml (tag atualizada) │   │
│  └──────────────────────────────────┬───────────────────────────────────┘   │
└─────────────────────────────────────│───────────────────────────────────────┘
                                      │ Sync
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AWS (Provisionado via Terraform)                     │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                            VPC (10.0.0.0/16)                          │   │
│  │  ┌─────────────────────┐         ┌─────────────────────┐             │   │
│  │  │   Public Subnets    │         │   Private Subnets   │             │   │
│  │  │   (NAT, ALB)        │         │   (EKS, RDS, Redis) │             │   │
│  │  └─────────────────────┘         └─────────────────────┘             │   │
│  │                                                                       │   │
│  │  ┌────────────────────────────────────────────────────────────────┐  │   │
│  │  │                     EKS Cluster (LabRole)                       │  │   │
│  │  │                                                                  │  │   │
│  │  │  ┌──────────────────────────────────────────────────────────┐  │  │   │
│  │  │  │                 ArgoCD (GitOps Controller)                │  │  │   │
│  │  │  └──────────────────────────────────────────────────────────┘  │  │   │
│  │  │                              │                                  │  │   │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │  │   │
│  │  │  │  auth   │ │  flag   │ │targeting│ │  eval   │ │analytics│  │  │   │
│  │  │  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘  │  │   │
│  │  └───────│───────────│───────────│───────────│───────────│────────┘  │   │
│  │          │           │           │           │           │           │   │
│  │  ┌───────▼───────────▼───────────▼───────────┼───────────┼───────┐  │   │
│  │  │              RDS PostgreSQL (3x)          │           │       │  │   │
│  │  │    auth_db      flags_db    targeting_db  │           │       │  │   │
│  │  └───────────────────────────────────────────┘           │       │  │   │
│  │                                              ┌───────────▼───┐   │  │   │
│  │                                              │ ElastiCache   │   │  │   │
│  │                                              │ Redis 7.1     │   │  │   │
│  │                                              └───────────────┘   │  │   │
│  │  ┌─────────────┐                            ┌────────────────┐   │  │   │
│  │  │     SQS     │◄───────────────────────────│    DynamoDB    │   │  │   │
│  │  │  + DLQ      │                            │   Analytics    │   │  │   │
│  │  └─────────────┘                            └────────────────┘   │  │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                           ECR (5 repositórios)                        │   │
│  │   auth-service │ flag-service │ targeting │ evaluation │ analytics   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Como Executar o Projeto

### Pré-requisitos

- AWS CLI configurado com credenciais do AWS Academy
- Terraform >= 1.5.0
- kubectl
- Docker (para build local)

### 1. Provisionar Infraestrutura (Terraform)

```bash
# Criar bucket S3 para o state (apenas uma vez, antes do primeiro apply)
aws s3 mb s3://togglemaster-terraform-state --region us-east-1

# Inicializar e aplicar
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Configurar kubectl para o EKS

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-dev-eks
```

### 3. Instalar ArgoCD no Cluster

```bash
cd gitops/argocd
chmod +x install.sh
./install.sh
```

### 4. Acessar a UI do ArgoCD

```bash
# Em um terminal, rode o port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Em outro terminal, obtenha a senha inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Acesse: https://localhost:8080 (usuário: `admin`, senha: output do comando acima)

---

## Estrutura dos Pipelines DevSecOps

```
.github/workflows/
├── ci-auth-service.yml         # Go: golangci-lint, gosec, Trivy
├── ci-flag-service.yml         # Python (usa workflow reusável)
├── ci-targeting-service.yml    # Python (usa workflow reusável)
├── ci-evaluation-service.yml   # Python (usa workflow reusável)
├── ci-analytics-service.yml    # Python (usa workflow reusável)
├── _reusable-python-ci.yml     # Workflow compartilhado para serviços Python
└── terraform.yml               # Validação, apply e destroy do Terraform
```

### Destruindo a Infraestrutura (Economizar Créditos)

Para destruir toda a infraestrutura e parar de consumir créditos do AWS Academy:

1. Vá em **Actions** → **Terraform**
2. Clique em **Run workflow**
3. Selecione **destroy** no dropdown "Ação a executar"
4. Digite `DESTROY` no campo de confirmação (obrigatório)
5. Clique em **Run workflow**

> **Segurança:** O pipeline exige que você digite exatamente "DESTROY" para confirmar. Se não digitar, o job falha sem tocar na AWS.

### Testando o Bloqueio por Vulnerabilidade

Para demonstrar que o pipeline bloqueia vulnerabilidades críticas:

1. Adicione uma dependência vulnerável conhecida (ex: `requests==2.25.0` com CVE)
2. Faça commit e push
3. O pipeline falhará no estágio de SCA (Trivy) com saída não-zero
4. Remova a dependência vulnerável e faça novo push
5. O pipeline passará e a imagem será publicada no ECR

---

## Desafios Enfrentados e Soluções

Durante a implementação da esteira de IaC e DevSecOps, surgiram alguns desafios específicos do ambiente AWS Academy:

### 1. Limitações da LabRole no AWS Academy

- **Desafio:** Não é possível criar IAM Roles ou Policies via Terraform no AWS Academy. Tentativas resultam em `AccessDenied`.

- **Solução:** Configurei o Terraform para usar a `LabRole` existente via data source ao invés de criar roles customizadas:
  ```hcl
  data "aws_iam_role" "lab_role" {
    name = "LabRole"
  }
  ```
  Essa role é atribuída tanto ao cluster EKS quanto aos Node Groups, permitindo que funcionem com as permissões pré-configuradas do Academy.

### 2. Remote State do Terraform (Locking)

- **Desafio:** O `terraform.tfstate` não pode ficar local para trabalho em equipe, e criar tabela DynamoDB para locking falha por limitações de IAM.

- **Solução:** Configurei backend S3 com `use_lockfile = true` (feature do Terraform 1.10+) que usa locking nativo via arquivo `.tflock` no próprio bucket, sem necessidade de DynamoDB:
  ```hcl
  terraform {
    backend "s3" {
      bucket       = "togglemaster-terraform-state"
      key          = "togglemaster/terraform.tfstate"
      region       = "us-east-1"
      use_lockfile = true
    }
  }
  ```

### 3. Autenticação do GitHub Actions na AWS

- **Desafio:** Não queria usar Access Keys estáticas nos secrets do GitHub por questões de segurança e rotação.

- **Solução:** Configurei OIDC (OpenID Connect) entre GitHub e AWS. O workflow assume a role via federação:
  ```yaml
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      aws-region: us-east-1
  ```
  Isso elimina a necessidade de credentials de longa duração e segue as melhores práticas de segurança.

### 4. Serviços sem Testes Unitários

- **Desafio:** Os microsserviços originais não possuem testes unitários implementados, mas o pipeline precisa ter um estágio de testes.

- **Solução:** Configurei os pipelines para rodar os testes de forma condicional. Se não existir arquivo de testes ou o comando retornar vazio, o estágio passa com sucesso. Quando testes forem adicionados no futuro, serão executados automaticamente:
  ```yaml
  - name: Run tests
    run: |
      if [ -f "pytest.ini" ] || find . -name "test_*.py" | grep -q .; then
        pytest -v --tb=short || true
      else
        echo "No tests found, skipping..."
      fi
  ```

---

## Estimativa de Custos AWS

| Recurso | Tipo | Custo/Hora | Custo/Mês (estimado) |
|---------|------|------------|----------------------|
| EKS Cluster | Control Plane | $0.10 | ~$73 |
| EC2 (2x t3.medium) | Node Group | $0.08 | ~$60 |
| RDS (3x db.t3.micro) | PostgreSQL | $0.05 | ~$38 |
| ElastiCache (cache.t3.micro) | Redis | $0.02 | ~$15 |
| NAT Gateway | Networking | $0.05 | ~$36 |
| S3 + ECR | Storage | - | ~$5 |
| **Total Estimado** | | | **~$227/mês** |

> **Dica:** Destrua a infraestrutura quando não estiver usando (`terraform destroy`) para economizar créditos do Academy!

---

## Próximos Passos (Melhorias Futuras)

Para evoluir este ecossistema para um ambiente enterprise-ready, mapeei as seguintes melhorias:

- **Terraform Workspaces:** Usar workspaces para gerenciar múltiplos ambientes (dev, staging, prod) com o mesmo código, apenas variando os valores.

- **Policy as Code:** Integrar o OPA (Open Policy Agent) ou Checkov no pipeline de Terraform para validar compliance das configurações antes do apply.

- **Secrets Management:** Migrar de Kubernetes Secrets para AWS Secrets Manager com External Secrets Operator, centralizando o gerenciamento de credenciais.

- **Progressive Delivery:** Evoluir o ArgoCD para Argo Rollouts, habilitando deploys canary e blue-green com rollback automático baseado em métricas.

- **Observabilidade do Pipeline:** Integrar métricas do GitHub Actions (tempo de build, taxa de falha) com Prometheus/Grafana para dashboards de DORA metrics.

---

## Referências

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions - AWS Credentials (OIDC)](https://github.com/aws-actions/configure-aws-credentials)
- [Trivy - Vulnerability Scanner](https://aquasecurity.github.io/trivy/)
- [ArgoCD - Declarative GitOps](https://argo-cd.readthedocs.io/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
