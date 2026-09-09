# ToggleMaster V3 🚀

> FIAP Postech - DevOps & Cloud Architecture (Tech Challenge - Fase 3)

O **ToggleMaster V3** representa a evolução definitiva da arquitetura de microsserviços para o modelo **"Se não está no código, não existe"**. Toda a infraestrutura na AWS é provisionada como código (**Terraform**), os deploys são governados por esteiras completas de **DevSecOps (GitHub Actions)** com gates automáticos de segurança, e a entrega contínua é orquestrada via **GitOps com ArgoCD** no Kubernetes (EKS).

---

## 📋 Informações de Entrega

* **Aluno:** Ricardo Marassato
* **RM:** 370358
* **Discord:** marassato7700
* **Repositório do GitHub:** [fiap-postech-tc3-togglemaster](https://github.com/RicardoMarassato/fiap-postech-tc3-togglemaster)
* **Link do Vídeo de Demonstração:** [Vídeo de Demonstração (YouTube / Google Drive)](https://drive.google.com/) *(Preencher com o link da gravação)*
* **Documentação Técnica Completa:** [Ricardo-Marassato-readme-tech-phase-3.md](Ricardo-Marassato-readme-tech-phase-3.md)
* **Guia Didático da Arquitetura:** [GUIA_DIDATICO_JUNIOR.md](GUIA_DIDATICO_JUNIOR.md)

---

## 🛠️ Tecnologias Utilizadas

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS EKS](https://img.shields.io/badge/AWS_EKS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Go](https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)
![DynamoDB](https://img.shields.io/badge/DynamoDB-4053D6?style=for-the-badge&logo=amazon-dynamodb&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-Security-blue?style=for-the-badge&logo=aquasec&logoColor=white)

---

## 🧩 Arquitetura da Solução & Pilares da Fase 3

O ecossistema integra os 5 microsserviços do ToggleMaster provisionados em nuvem através de práticas modernas de engenharia DevOps:

1. **Infraestrutura como Código (Terraform Modular):**
   * **Networking:** VPC com Subnets Públicas e Privadas, Internet Gateway, NAT Gateway e Route Tables.
   * **Cluster EKS:** Kubernetes gerenciado com Node Groups privados, integrado nativamente à `LabRole` (AWS Academy) ou roles customizadas.
   * **Bancos de Dados:** 3 instâncias independentes de RDS PostgreSQL (`auth_db`, `flags_db`, `targeting_db`), 1 cluster ElastiCache Redis 7.1 e 1 tabela DynamoDB (`ToggleMasterAnalytics`).
   * **Mensageria & Repositórios:** 1 fila SQS com Dead Letter Queue (DLQ) e 5 repositórios no AWS ECR com políticas de ciclo de vida.
   * **Remote State:** Estado do Terraform armazenado em Bucket S3 com locking nativo (`use_lockfile`).

2. **Pipeline DevSecOps (CI no GitHub Actions):**
   * **Build & Unit Test:** Compilação e execução de testes unitários com geração de relatórios de cobertura.
   * **Linter / Static Analysis:** Análise estática com `golangci-lint` (Go) e `flake8`/`pylint` (Python).
   * **SAST & SCA:** Análise de vulnerabilidades em código com `gosec`/`bandit` e auditoria de dependências com `Trivy` (fs mode).
   * **Container Security & ECR:** Varredura da imagem Docker com `Trivy` e publicação no ECR tagueada com o commit SHA (`v1.0.0-<hash>`).
   * **Gate de Bloqueio:** Falha imediata do pipeline caso seja identificada vulnerabilidade **CRÍTICA**.

3. **Entrega Contínua & GitOps (CD com ArgoCD):**
   * **Repositório GitOps:** Manifestos organizados em padrão *App of Apps* (`gitops/argocd/applications.yaml`).
   * **Atualização Automática:** Ao fim do CI, o manifesto `deployment.yaml` é atualizado no Git com a nova tag de imagem gerada.
   * **Sincronização Contínua:** ArgoCD detecta a alteração no repositório e sincroniza automaticamente os pods no EKS (*self-healing* e *pruning* habilitados).
   * **Ingress Controller:** Roteamento unificado via NGINX Ingress Controller com rewrite target para todos os 5 serviços.

---

## ⚡ Como Rodar e Testar

### 1. Rodando Localmente (Docker Compose)
Para desenvolvimento local com bancos e serviços integrados:
```bash
cd services
cp .env.example .env
docker compose up -d --build
```

### 2. Provisionando a Infraestrutura na AWS (Terraform)
```bash
# 1. Criar o bucket de remote state no S3
aws s3 mb s3://togglemaster-terraform-state --region us-east-1

# 2. Inicializar e aplicar o Terraform
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Configurando kubectl e ArgoCD
```bash
# Atualizar kubeconfig
aws eks update-kubeconfig --region us-east-1 --name togglemaster-prod-eks

# Instalar o ArgoCD e aplicar as Applications do GitOps
cd gitops/argocd
chmod +x install.sh
./install.sh

# Acessar a UI do ArgoCD via port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Senha inicial do admin:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### 4. Testando a Regra de Bloqueio por Vulnerabilidade (DevSecOps)
Para validar o gate de segurança do pipeline CI:
1. Adicione uma dependência vulnerável conhecida no arquivo de dependências (ex: `requests==2.25.0` em `services/flag-service/requirements.txt`).
2. Faça commit e push para o repositório.
3. Observe o workflow do GitHub Actions falhar no passo de SCA do Trivy.
4. Reverta a alteração e envie o commit: o pipeline passará com sucesso e liberará o push para o ECR.

### 5. Destruindo a Infraestrutura (Economia de Créditos)
Para evitar custos desnecessários no AWS Academy:
* Execute o workflow **Terraform** no GitHub Actions selecionando a opção **destroy** e digitando `DESTROY` no campo de confirmação, ou execute localmente `terraform destroy -auto-approve`.

### 💡 Dica de Produtividade: Clonando os Repositórios da Organização
Para clonar todos os 5 repositórios originais dos microsserviços via GitHub CLI:
```bash
python helpers/git-cloner.py
```

---

## 📖 Relatório Técnico Completo de Entrega

Toda a fundamentação técnica, arquitetura de rede, matriz DevSecOps, decisões de design para AWS Academy, desafios enfrentados, estimativa detalhada de custos e próximos passos estão documentados no relatório oficial:

👉 **[Documentação Técnica de Entrega - Fase 3](Ricardo-Marassato-readme-tech-phase-3.md)**
