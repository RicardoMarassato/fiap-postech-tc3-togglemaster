# ToggleMaster V3 - Relatório Técnico de Entrega (Fase 3: IaC, DevSecOps & GitOps)

Este documento constitui o relatório técnico oficial de entrega da **Fase 3 do Tech Challenge** da pós-graduação em DevOps & Cloud Architecture da FIAP. O projeto consolida a transformação da operação do **ToggleMaster**, evoluindo de uma implantação manual para um ecossistema inteiramente governado como código (**IaC**), protegido por esteiras com gates estritos de segurança (**DevSecOps**) e entregue continuamente através do paradigma declarativo **GitOps com ArgoCD**.

---

## Informações da Entrega

* **Aluno:** Ricardo Marassato
* **RM:** 370358
* **Discord:** marassato7700
* **Repositório GitHub:** [https://github.com/RicardoMarassato/fiap-postech-tc3-togglemaster](https://github.com/RicardoMarassato/fiap-postech-tc3-togglemaster)
* **Link do Vídeo (Demonstração):** [https://drive.google.com/](https://drive.google.com/) *(Preencher com o link da gravação)*

---

## Do Caos Operacional à Imutabilidade ("Se não está no código, não existe")

Na Fase 2, o ecossistema de microsserviços do ToggleMaster foi validado com sucesso do ponto de vista de arquitetura de software e particionamento de dados. No entanto, a operação em ambiente de nuvem enfrentava gargalos críticos:

1. **Infraestrutura Artesanal e Drift de Configuração:** Cluster EKS, VPC, instâncias RDS, cluster Redis, filas SQS e tabelas DynamoDB eram criados e ajustados manualmente no console AWS. Recriar ambientes homogêneos para homologação ou recuperação de desastres levava dias e introduzia divergências silenciosas.
2. **Deploys Não Rastreados:** Desenvolvedores executavam `kubectl apply` diretamente de suas estações de trabalho, sobrepondo versões, dificultando o rastreio de auditoria e gerando estados inconsistentes no cluster.
3. **Vulnerabilidades Ocultas no Caminho Crítico:** Bibliotecas com falhas de segurança conhecidas e contêineres mal configurados podiam alcançar produção sem qualquer bloqueio ou análise estática prévia.
4. **Exposição de Credenciais:** Informações sensíveis e strings de conexão trafegavam em arquivos de texto sem governança criptográfica.

Para sanar essas vulnerabilidades operacionais, a Fase 3 estabelece o princípio **"Se não está no código, não existe"**, estruturado em três pilares integrados:
* **Infraestrutura Imutável via Terraform:** 100% dos recursos provisionados declarativamente em módulos reutilizáveis.
* **Segurança Shift-Left (DevSecOps):** Análise estática de código (SAST), análise de composição de software (SCA) e varredura de contêineres com **bloqueio imediato** para falhas críticas.
* **Operação Declarativa com GitOps (ArgoCD):** O repositório Git torna-se a única fonte da verdade (*Single Source of Truth*), eliminando o acesso direto de desenvolvedores ao Kubernetes de produção.

---

## Arquitetura Geral da Solução

O ecossistema é formado por 5 microsserviços especializados interagindo com bancos dedicados, cache e mensageria assíncrona:

* **auth-service (Go):** Responsável pela emissão e autenticação de API keys via SHA-256. Persistência em instância dedicada do PostgreSQL (`auth_db`).
* **flag-service (Python/Flask):** CRUD de configuração das *feature flags* e estados. Persistência em PostgreSQL (`flags_db`).
* **targeting-service (Python/Flask):** Definição e gestão de regras de segmentação de usuários (ex: percentual de rollout). Persistência em PostgreSQL (`targeting_db`).
* **evaluation-service (Go):** Caminho crítico (*hot path*) de avaliação de flags. Consulta em altíssima performance utilizando ElastiCache Redis como cache em memória (TTL de 30s) e publica eventos de auditoria de forma não bloqueante na fila AWS SQS.
* **analytics-service (Python):** Processador em background (*worker*) que consome continuamente as mensagens da fila SQS e grava as métricas de telemetria na tabela AWS DynamoDB (`ToggleMasterAnalytics`).

### Diagrama da Arquitetura Integrada

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              GITHUB & DEVSECOPS CI                                     │
│                                                                                        │
│  [Developer Push/PR]                                                                   │
│          │                                                                             │
│          ▼                                                                             │
│  ┌─────────────────┐     ┌──────────────────┐     ┌────────────────┐                   │
│  │ Build & Test    │────▶│ SAST / Lint      │────▶│ SCA (Trivy fs) │                   │
│  │ (go test/pytest)│     │ (gosec / bandit) │     │ [GATE CRITICAL]│                   │
│  └─────────────────┘     └──────────────────┘     └───────┬────────┘                   │
│                                                           │ Pass                       │
│                                                           ▼                            │
│  ┌─────────────────┐     ┌──────────────────┐     ┌────────────────┐                   │
│  │ Update GitOps   │◀────│ ECR Push         │◀────│ Container Scan │                   │
│  │ (deployment.yml)│     │ (v1.0.0-<sha>)   │     │ (Trivy image)  │                   │
│  └────────┬────────┘     └──────────────────┘     └────────────────┘                   │
└───────────│────────────────────────────────────────────────────────────────────────────┘
            │ Git Commit (Tag atualizada)
            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               GITOPS ENGINE (ARGOCD)                                   │
│                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │ ArgoCD Controller (App of Apps: togglemaster, auth, flag, target, eval, analytic)│  │
│  │ Sincronização Automática: Git -> EKS (Self-Heal & Prune habilitados)              │  │
│  └────────────────────────────────────────┬─────────────────────────────────────────┘  │
└───────────────────────────────────────────│────────────────────────────────────────────┘
                                            │ Desired State Reconciled
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                            AWS INFRASTRUCTURE (TERRAFORM)                              │
│                                                                                        │
│  VPC (10.0.0.0/16)                                                                     │
│  ├── Public Subnets (NAT Gateway, NGINX Ingress Load Balancer)                         │
│  └── Private Subnets:                                                                  │
│      ├── EKS Cluster (Kubernetes 1.31 + Node Groups via LabRole)                       │
│      │   ├── Ingress NGINX (http://<alb>/auth, /flags, /targeting, /evaluation)        │
│      │   ├── auth-service ───▶ RDS PostgreSQL (auth_db)                                │
│      │   ├── flag-service ───▶ RDS PostgreSQL (flags_db)                               │
│      │   ├── targeting-service ─▶ RDS PostgreSQL (targeting_db)                        │
│      │   ├── evaluation-service ─▶ ElastiCache Redis (Cache) ──▶ SQS Events Queue     │
│      │   └── analytics-service ──▶ SQS Events Queue ───────────▶ DynamoDB Analytics   │
│      ├── 3x Instâncias RDS PostgreSQL (Multi-AZ opcional em prod)                      │
│      ├── ElastiCache Cluster (Redis 7.1)                                               │
│      ├── DynamoDB Table (ToggleMasterAnalytics com TTL e PITR)                         │
│      ├── Fila SQS (events + Dead Letter Queue DLQ)                                     │
│      └── 5x Repositórios ECR (Lifecycle policy de retenção)                            │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Infraestrutura como Código (Terraform)

A infraestrutura foi organizada em módulos independentes e altamente coesos dentro do diretório `terraform/modules/`:

```
terraform/
├── main.tf                    # Orquestrador geral dos módulos
├── variables.tf               # Definição e tipagem das variáveis
├── outputs.tf                 # Exportação de endpoints para K8s e GitOps
├── backend.tf                 # Configuração do remote state em S3
├── providers.tf               # Provedores AWS, Kubernetes, Helm e Random
├── versions.tf                # Travamento de versões (Terraform >= 1.5, AWS ~> 5.0)
├── data.tf                    # Data sources (LabRole, Caller Identity, AZs)
├── terraform.tfvars.example   # Exemplo documentado de parametrização
└── modules/
    ├── networking/            # VPC, Subnets Públicas/Privadas, IGW, NAT Gateway, Routes
    ├── eks/                   # Cluster EKS e Managed Node Groups (suporte a LabRole)
    ├── rds/                   # 3 instâncias RDS PostgreSQL dedicadas + Security Groups
    ├── elasticache/           # Cluster Redis 7.1 com Parameter Group otimizado
    ├── dynamodb/              # Tabela ToggleMasterAnalytics com TTL e PITR
    ├── sqs/                   # Fila principal de mensageria + Dead Letter Queue (DLQ)
    └── ecr/                   # 5 repositórios de contêineres com Lifecycle Policies
```

### Decisão de Arquitetura: Compatibilidade com AWS Academy (Opção A) vs Conta Pessoal (Opção B)

O projeto implementa abstração nativa para permitir execução tanto no ambiente restrito do **AWS Academy** quanto em **contas pessoais**:
* **AWS Academy (Opção A):** A criação de IAM Roles e Policies é bloqueada por SCPs da AWS. Por isso, definimos a flag `use_lab_role = true`. O Terraform busca automaticamente a role gerenciada através de um data source e a vincula tanto ao Control Plane do EKS quanto aos Node Groups:
  ```hcl
  data "aws_iam_role" "lab_role" {
    count = var.use_lab_role ? 1 : 0
    name  = "LabRole"
  }
  ```
* **Conta Pessoal (Opção B):** Ao definir `use_lab_role = false`, o código aceita um ARN customizado ou pode ser estendido para provisionar roles com privilégio mínimo (*least privilege*).

### Remote State com S3 e Locking Nativo (`use_lockfile`)

Para atender à exigência de estado compartilhado remoto sem depender de criação de tabelas DynamoDB (que podem sofrer restrições de IAM no Academy), utilizamos a funcionalidade de locking nativo do Terraform:
```hcl
terraform {
  backend "s3" {
    bucket       = "togglemaster-terraform-state"
    key          = "togglemaster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### Isolamento de Bancos e Mensageria
* **RDS PostgreSQL:** Cada microsserviço com domínio relacional (`auth`, `flags`, `targeting`) possui sua própria instância `db.t3.micro` isolada na VPC privada, garantindo autonomia de dados.
* **ElastiCache Redis:** Configurado com política de despejo `allkeys-lru` em Parameter Group customizado, evitando que o cache estoure a memória em picos de requisições.
* **DynamoDB:** Tabela noSQL `ToggleMasterAnalytics` provisionada em modo `PAY_PER_REQUEST` para otimização de custo, com *Point-In-Time Recovery (PITR)* e *Time-To-Live (TTL)* configurados.
* **SQS com DLQ:** Fila de eventos conectada a uma Dead Letter Queue (`events-dlq`) com política de redrive acionada após 3 falhas de processamento (`maxReceiveCount = 3`).

---

## 2. Pipeline de Integração Contínua (CI) & DevSecOps

Cada um dos 5 microsserviços possui um workflow dedicado no GitHub Actions que dispara automaticamente a cada **Pull Request** e **Push na branch `main`**. A arquitetura foi padronizada através de workflows reusáveis:
* `_reusable-go-ci.yml`: Governa os serviços em Golang (`auth-service` e `evaluation-service`).
* `_reusable-python-ci.yml`: Governa os serviços em Python (`flag-service`, `targeting-service`, `analytics-service`).

### Matriz de Estágios de Segurança (DevSecOps)

| Estágio | Ferramentas | Escopo e Objetivo | Regra de Bloqueio |
| :--- | :--- | :--- | :--- |
| **1. Build & Test** | Go Toolchain / Pytest | Compila binários e executa testes unitários com relatórios de cobertura. | Falha se os testes quebrarem. |
| **2. Linter / Static** | `golangci-lint`, `flake8`, `pylint` | Garante padrões de qualidade, complexidade ciclomática e boas práticas. | Falha em erros de sintaxe e violações graves. |
| **3. SAST** | `gosec` (Go) / `bandit` (Python) | Análise estática do código-fonte em busca de falhas como injeção SQL, uso de criptografia fraca, hardcoded keys. | Reporta issues no log e SARIF. |
| **4. SCA** | `Trivy` (modo `fs`) | Software Composition Analysis varrendo manifestos de dependências (`go.mod`, `requirements.txt`). | **BLOQUEIO IMEDIATO** em vulnerabilidade **CRITICAL** (`exit-code: 1`). |
| **5. Container Scan** | `Trivy` (modo `image`) | Varre as camadas da imagem Docker recém-construída em busca de CVEs de pacotes de SO. | **BLOQUEIO IMEDIATO** em vulnerabilidade **CRITICAL** (`exit-code: 1`). |
| **6. Docker Push** | AWS ECR Login Action | Autenticação e envio da imagem tagueada para o repositório ECR correspondente. | Apenas após aprovação de todos os gates. |
| **7. Update GitOps** | GitHub Script / Git CLI | Atualiza a tag da imagem no arquivo `deployment.yaml` do serviço e commita na `main`. | Executado automaticamente após push. |

### Regra de Bloqueio (Hard Gate)

A proteção contra vulnerabilidades críticas é garantida nos passos de SCA e Container Scan através da flag de saída do Trivy:
```yaml
- name: Run Trivy (SCA - Dependencies)
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: ${{ inputs.service_path }}
    format: 'table'
    exit-code: '1'          # Interrompe o pipeline com código de erro 1
    severity: 'CRITICAL'    # Filtra vulnerabilidades de severidade crítica
    ignore-unfixed: true
```
Caso uma biblioteca contenha CVE crítica conhecida, o pipeline é cancelado, impedindo a geração e publicação de artefatos inseguros.

### Autenticação Segura sem Senhas Estáticas (AWS OIDC)

Para comunicação entre o GitHub Actions e a AWS, foi adotada federação de identidade via **OpenID Connect (OIDC)**. O runner assume a role temporária sem necessidade de cadastrar `AWS_ACCESS_KEY_ID` ou `AWS_SECRET_ACCESS_KEY` estáticas nos segredos do repositório, mitigando riscos de vazamento de credenciais de longa duração.

---

## 3. Entrega Contínua (CD) & GitOps com ArgoCD

Na Fase 3, o pipeline de CI nunca aplica manifestos diretamente no cluster Kubernetes via `kubectl`. Em seu lugar, adota-se a arquitetura GitOps:

1. **Repositório GitOps (`gitops/`):**
   * `gitops/argocd/applications.yaml`: Configuração das aplicações no padrão *App of Apps*.
   * `gitops/base/`: Contém o `namespace.yaml`, `configmap.yaml`, `secrets.yaml` e o `ingress.yaml`.
   * `gitops/apps/<serviço>/deployment.yaml`: Contém os manifestos de Deployment e Service de cada microsserviço.
2. **Atualização Automática de Tags:**
   * Quando um push na branch `main` passa por todos os gates de segurança do CI, a imagem é publicada no ECR com a tag `v1.0.0-<commit_sha>`.
   * O job final `update-gitops` localiza o manifesto `gitops/apps/<serviço>/deployment.yaml`, substitui a versão da imagem pela nova tag e realiza o commit/push no Git.
3. **Sincronização e Reconciliação (ArgoCD):**
   * O ArgoCD detecta a alteração no Git e reconciled o estado desejado (*Desired State*) com o estado real (*Actual State*) no cluster EKS.
   * As opções `prune: true` e `selfHeal: true` garantem que recursos excluídos do Git sejam removidos do cluster e que modificações manuais no Kubernetes sejam automaticamente desfeitas, garantindo conformidade total com o repositório.
4. **Roteamento Unificado (Ingress Controller):**
   * O manifesto `gitops/base/ingress.yaml` expõe os 5 serviços via NGINX Ingress Controller com anotações de *rewrite-target*, permitindo acesso através de uma única URL pública externa.

---

## 4. Passo a Passo Completo para Executar e Testar

### 4.1 Validação do Terraform (IaC)

```bash
# 1. Navegue até o diretório do Terraform
cd terraform

# 2. Inicialize o Terraform com o backend
terraform init

# 3. Valide a sintaxe e a integridade dos módulos
terraform validate
# Saída esperada: Success! The configuration is valid.

# 4. Gere o plano de execução
terraform plan

# 5. Aplique a infraestrutura na AWS (quando for executar a validação em nuvem)
terraform apply -auto-approve
```

### 4.2 Configuração do Cluster e ArgoCD

```bash
# 1. Conecte o kubectl ao cluster provisionado
aws eks update-kubeconfig --region us-east-1 --name togglemaster-prod-eks

# 2. Instale o ArgoCD no cluster
cd gitops/argocd
chmod +x install.sh
./install.sh

# 3. Abra o encaminhamento de porta da UI do ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 4. Recupere a senha do usuário admin (em outro terminal)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
# Acesse https://localhost:8080 (Login: admin)
```

### 4.3 Teste da Esteira DevSecOps (Simulação de Bloqueio e Correção)

Para demonstrar o funcionamento dos gates de segurança (obrigatório para o vídeo de entrega):

1. **Injetando Vulnerabilidade:**
   * Edite o arquivo `services/flag-service/requirements.txt`.
   * Adicione uma versão com vulnerabilidade crítica conhecida:
     ```text
     requests==2.25.0
     ```
   * Faça o commit e push:
     ```bash
     git checkout -b test-security-fail
     git add services/flag-service/requirements.txt
     git commit -m "test: inject critical vulnerable dependency"
     git push origin test-security-fail
     ```
   * Abra um Pull Request e observe a esteira **CI - Flag Service**: o job **Security Scan** falhará no estágio do Trivy acusando CVE crítica, bloqueando o avanço para build e publicação da imagem.
2. **Corrigindo a Vulnerabilidade:**
   * Remova a linha `requests==2.25.0` de `services/flag-service/requirements.txt`.
   * Faça o commit e push da correção.
   * A esteira executará todos os estágios com sucesso, liberando a criação da imagem e a atualização no GitOps.

### 4.4 Teste da Sincronização GitOps

1. Ao realizar o merge de um Pull Request na `main`, o job `update-gitops` atualiza o arquivo `gitops/apps/flag-service/deployment.yaml` com o hash do commit.
2. Na UI do ArgoCD, observe a aplicação `flag-service` mudar para o status *OutOfSync* e, em segundos, transicionar para *Synced* e *Healthy*, realizando o rolling update dos pods no cluster EKS sem qualquer intervenção humana.

### 4.5 Destruição Segura da Infraestrutura (Economia de Créditos)

Para evitar consumo de saldo no AWS Academy:
1. No repositório GitHub, acesse a aba **Actions** → selecione o workflow **Terraform**.
2. Clique em **Run workflow** → selecione a ação **destroy** → digite `DESTROY` no campo de texto de confirmação → clique em **Run workflow**.
3. O pipeline executará o `terraform destroy -auto-approve`, desprovisionando todos os recursos na AWS de forma limpa e segura.

---

## 5. Desafios Enfrentados e Soluções Adotadas

Durante o desenvolvimento da Fase 3, diversos obstáculos técnicos e limitações de plataforma foram enfrentados e solucionados:

### 1. Restrições Estritas de IAM no AWS Academy
* **Desafio:** No AWS Academy, comandos como `aws_iam_role` ou `aws_iam_policy` geram erros imediatos de `AccessDenied`.
* **Solução:** Implementamos um mecanismo condicional no Terraform (`var.use_lab_role`). Quando ativo, busca via data source a role pré-existente `LabRole` e a injeta como parâmetro para o cluster EKS e os Managed Node Groups.

### 2. Remote State do Terraform sem Permissão de Criar Tabela DynamoDB para Lock
* **Desafio:** A prática tradicional de IaC exige uma tabela DynamoDB dedicada para lock do `terraform.tfstate`. Porém, a criação dessa tabela esbarrava em restrições de permissão de IAM do laboratório.
* **Solução:** Adotamos o recurso nativo `use_lockfile = true` introduzido no Terraform 1.10+. O Terraform cria um arquivo de lock temporário `.tflock` diretamente dentro do bucket S3, garantindo exclusão mútua contra execuções simultâneas sem a necessidade de recursos auxiliares.

### 3. Eliminação de Chaves Estáticas no CI/CD (AWS OIDC)
* **Desafio:** Inserir Access Keys estáticas nos segredos do repositório é uma má prática de segurança e inviabilizaria a rotação frequente exigida pelas sessões do AWS Academy.
* **Solução:** Configuramos federação OIDC entre o GitHub Actions e a AWS com a action oficial `aws-actions/configure-aws-credentials@v4`, permitindo que os runners autentiquem via tokens temporários vinculados à branch `main`.

### 4. Identificação e Correção do Runtime do Evaluation Service
* **Desafio:** O repositório herdava uma configuração de pipeline que classificava o `evaluation-service` como Python (chamando o workflow `_reusable-python-ci.yml`), fazendo com que o CI tentasse instalar `requirements.txt` inexistente e quebrasse a esteira.
* **Solução:** Identificamos que o serviço é implementado em **Golang** (`evaluator.go`, `main.go`, `sqs.go`). Criamos o workflow reusável `_reusable-go-ci.yml` integrando `golangci-lint`, `gosec`, testes unitários em Go e Trivy, padronizando tanto o `auth-service` quanto o `evaluation-service`.

### 5. Incompatibilidades de Sintaxe no Provedor AWS v5
* **Desafio:** Durante a validação estrita do Terraform (`terraform validate`), surgiram erros de sintaxe nos blocos de segurança do Redis/RDS (`security_group_id` invés de `security_groups`) e no recurso `aws_sqs_queue` (`dynamic "redrive_policy"` invés do atributo `redrive_policy` serializado em JSON).
* **Solução:** Adequamos o HCL para as convenções do AWS Provider v5.x: atualizamos a lista de security groups para `security_groups = [ingress.value]` e serializamos o redrive policy via `jsonencode()` condicional.

### 6. Roteamento Multisserviço e Rewrite Target no Ingress Controller
* **Desafio:** Ao expor múltiplos microsserviços sob um único Load Balancer, as requisições em caminhos como `/auth/health` ou `/evaluation/evaluate` chegavam às aplicações com o prefixo completo do path, gerando respostas HTTP 404.
* **Solução:** Criamos o manifesto `gitops/base/ingress.yaml` aplicando anotações do NGINX Ingress Controller com suporte a regex (`nginx.ingress.kubernetes.io/use-regex: "true"`) e captura de subrotas (`nginx.ingress.kubernetes.io/rewrite-target: /$2`), normalizando as requisições antes de entregá-las aos pods.

---

## 6. Estimativa de Custos AWS

A estimativa mensal de custos para o ambiente de homologação e produção foi dimensionada considerando a região `us-east-1`:

| Recurso AWS | Configuração / Tipo de Instância | Quantidade | Custo Unitário / Hora | Custo Estimado Mensal |
| :--- | :--- | :---: | :--- | :--- |
| **Amazon EKS** | Control Plane gerenciado | 1 cluster | $0.10 / hora | ~$73.00 |
| **Amazon EC2 (Node Groups)** | `t3.medium` (2 vCPU, 4GB RAM) | 2 instâncias | $0.0416 / hora / nó | ~$60.00 |
| **Amazon RDS (PostgreSQL)** | `db.t3.micro` (Single-AZ, 20GB GP3) | 3 instâncias | $0.017 / hora / db | ~$38.00 |
| **Amazon ElastiCache** | Redis `cache.t3.micro` | 1 nó | $0.017 / hora | ~$12.50 |
| **NAT Gateway** | Networking de subnets privadas | 1 gateway | $0.045 / hora + dados | ~$35.00 |
| **Amazon SQS + DynamoDB** | On-Demand (Free Tier / Pay per request) | - | Sob demanda | ~$2.00 |
| **Amazon ECR + Amazon S3** | Armazenamento de imagens e tfstate | 5 repos + 1 bucket | $0.10 / GB | ~$5.00 |
| **TOTAL GERAL ESTIMADO** | | | | **~$225.50 / mês** |

> **Boas Práticas de Economia no Laboratório:**
> 1. Manter instâncias RDS em modo Single-AZ durante a fase de desenvolvimento.
> 2. Utilizar o workflow automatizado de **Destroy** (`terraform.yml`) via GitHub Actions sempre que finalizar sessões de teste e gravação, zerando cobranças ociosas de EKS e NAT Gateway.

---

## 7. Próximos Passos (Melhorias Futuras)

Para uma evolução voltada a cenários de missão crítica empresarial (*Enterprise-ready*), mapeamos os seguintes incrementos:

* **Autoscaling Orientado a Eventos com KEDA:** Configurar *ScaledObjects* do KEDA para o `analytics-service` baseados na métrica `ApproximateNumberOfMessages` da fila SQS, permitindo inclusive escala até zero (*scale-to-zero*) quando a fila estiver vazia.
* **External Secrets Operator (ESO):** Eliminar a necessidade de segredos estáticos no GitOps através da integração do Kubernetes Secrets diretamente com o AWS Secrets Manager com rotação automatizada de credenciais.
* **Entrega Progressiva com Argo Rollouts:** Implementar estratégias de deploy Canary e Blue-Green com análise automática de métricas do Prometheus para rollbacks instantâneos em caso de aumento na taxa de erro HTTP 5xx.
* **Policy as Code:** Integrar Open Policy Agent (OPA Gatekeeper) no cluster e Checkov no pipeline de Terraform para impedir deploys que não cumpram normas de conformidade (CIS Benchmarks).

---

## 8. Referências Técnicas

* [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
* [Aqua Security Trivy Documentation](https://aquasecurity.github.io/trivy/)
* [ArgoCD - Declarative GitOps for Kubernetes](https://argo-cd.readthedocs.io/)
* [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
