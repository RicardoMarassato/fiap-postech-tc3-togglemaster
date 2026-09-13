# 🎬 Roteiro de Gravação Oficial - Tech Challenge Fase 3

**Projeto:** ToggleMaster (IaC, DevSecOps & GitOps)  
**Aluno:** Ricardo Marassato  
**RM:** 370358  
**Tempo estimado:** 12 a 15 minutos (Limite máximo: 20 minutos)  

---

## 📋 Checklist Pré-Gravação

- [ ] **Resolução:** Gravação em 1080p (Full HD).
- [ ] **Zoom/Fonte:** Zoom de 125% a 150% no navegador (GitHub e ArgoCD) e fonte ampliada no terminal e VS Code (14-16pt).
- [ ] **ArgoCD Ativo:** Terminal com port-forward rodando:
  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  ```
- [ ] **Abas pré-abertas no Navegador:**
  1. `https://localhost:8080` (ArgoCD logado: `admin` / `CcRvSF0gZ4AOifxn`).
  2. Repositório no GitHub: `https://github.com/RicardoMarassato/fiap-postech-tc3-togglemaster`.
  3. Aba de **Actions** no GitHub.
  4. Pull Request de teste de segurança (se já criado).
- [ ] **VS Code aberto:** Projeto `fiap-postech-tc3-togglemaster` com as pastas `terraform/`, `.github/workflows/` e `gitops/` visíveis.

---

## 🎙️ Abertura: Identificação e Contexto (1 minuto)

### 🖥️ O que mostrar na tela:
- Página inicial do repositório no GitHub (`RicardoMarassato/fiap-postech-tc3-togglemaster`).
- Dê scroll suave até o diagrama de arquitetura no `README.md`.

### 🗣️ O que falar:
> *"Olá, professores e avaliadores! Meu nome é Ricardo Marassato, RM 370358, e hoje apresento a entrega da Fase 3 do Tech Challenge da pós-graduação em DevOps da FIAP.*
>
> *Na Fase 2, construímos a arquitetura de 5 microsserviços do ToggleMaster (Auth, Flag, Targeting, Evaluation e Analytics). Porém, a operação sofria com deploys manuais via `kubectl apply`, falta de rastreabilidade, credenciais expostas e ausência de gates de segurança no pipeline.*
>
> *Nesta Fase 3, atendemos à diretriz da DevOps Solutions Inc.: 'Se não está no código, não existe'. Implementamos:*
> 1. *Infraestrutura 100% como Código (IaC) com Terraform modular e Remote State no S3.*
> 2. *Pipeline de CI com DevSecOps abrangendo SAST, SCA e Container Scanning com bloqueio estrito de vulnerabilidades críticas.*
> 3. *Entrega Contínua orientada a GitOps com ArgoCD, garantindo o Git como fonte única da verdade (Single Source of Truth).*
> 
> *Vamos conferir cada um desses pilares!"*

---

## 🏗️ Ato 1: Infraestrutura como Código - Terraform (3 a 4 minutos)

### 🖥️ O que mostrar na tela:
1. No VS Code, abra a pasta `terraform/` e mostre a estrutura modular:
   - `modules/networking`, `modules/eks`, `modules/rds`, `modules/elasticache`, `modules/dynamodb`, `modules/sqs`, `modules/ecr`.
2. Abra o arquivo `terraform/backend.tf` (destaque o S3 e o State Locking).
3. Abra o arquivo `terraform/main.tf` (destaque a chamada limpa dos módulos).
4. Abra o terminal e execute os comandos para comprovar os recursos rodando na AWS:
   ```bash
   kubectl get nodes -o wide
   aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass]" --output table
   ```

### 🗣️ O que falar:
> *"Começando pela Infraestrutura como Código. Desenvolvemos uma arquitetura modular em Terraform, totalmente desacoplada e reutilizável:*
>
> - *No `backend.tf`, configuramos o **Remote State no Amazon S3** com **State Locking**, impedindo que execuções concorrentes corrompam o estado da infraestrutura.*
> - *Como utilizamos uma conta pessoal da AWS (Opção B do desafio), criamos todas as **IAM Roles e Policies pelo Terraform**, seguindo o princípio de menor privilégio para o cluster EKS e os Worker Nodes.*
> - *A infraestrutura provisionada contempla:*
>   - *VPC completa com subnets públicas e privadas em duas Zonas de Disponibilidade (`us-east-1a` e `us-east-1b`), com Internet Gateway e NAT Gateway.*
>   - *Cluster **Amazon EKS 1.31** com Managed Node Group.*
>   - *Camada de persistência relacional com **3 instâncias RDS PostgreSQL** (`auth_db`, `flags_db`, `targeting_db`).*
>   - *Cluster **ElastiCache Redis 7.1** para cache em memória das flags avaliadas.*
>   - *Tabela **DynamoDB** (`ToggleMasterAnalytics`) no modelo On-Demand para eventos de telemetria.*
>   - *Mensageria assíncrona com **Fila SQS e Dead Letter Queue (DLQ)**.*
>   - *E os 5 repositórios no **Amazon ECR** para os containers.*
>
> *(Aponte para o terminal)*: *Aqui no terminal podemos validar: o EKS está ativo com os nós saudáveis e Ready, e as 3 instâncias de banco e o Redis estão operacionais na AWS."*

---

## 🔒 Ato 2: CI/CD com DevSecOps e Demonstração do Gate (4 a 5 minutos)

> ⚠️ **Momento-chave da avaliação! Demonstre o pipeline falhando e depois passando.**

### 🖥️ O que mostrar na tela:
1. No VS Code, abra a pasta `.github/workflows/` e o arquivo `_reusable-python-ci.yml`.
2. Destaque os 5 jobs:
   - `build-and-test`
   - `lint` (flake8, pylint, black)
   - `security-scan` (Bandit SAST + Trivy SCA com `exit-code: 1` e `severity: CRITICAL`)
   - `docker-build-push` (Trivy Container Scan + Push ECR)
   - `update-gitops` (sed automático no `deployment.yaml`)
3. Abra a aba **Pull Requests** ou **Actions** no GitHub.
4. Mostre a execução do PR com falha de segurança provocada pelo pacote `pyyaml==5.1`.
5. Abra os logs do Trivy mostrando o `CRITICAL` detectado.
6. Mostre o commit de correção e a Action passando 100% verde.

### 🗣️ O que falar:
> *"Agora vamos para a esteira de Integração Contínua com DevSecOps. Criamos workflows reutilizáveis (`_reusable-python-ci.yml` e `_reusable-go-ci.yml`) que padronizam a governança de engenharia para todos os 5 microsserviços.*
>
> *Cada Pull Request ou Push dispara os seguintes estágios:*
> 1. *`Build & Unit Test`: Compilação e execução de testes unitários com relatório de cobertura.*
> 2. *`Lint & Static Analysis`: Verificação estática de código com flake8, pylint e black para Python, e golangci-lint para Go.*
> 3. *`Security Scan (Shift-Left)`: Aqui aplicamos duas frentes essenciais de segurança antes do build:*
>    - *SAST (Static Application Security Testing) usando Bandit para auditar o código-fonte contra más práticas.*
>    - *SCA (Software Composition Analysis) usando Trivy para inspecionar dependências terceiras no `requirements.txt`.*
>    - *E a nossa **Regra de Bloqueio (Security Gate)**: se o Trivy detectar qualquer vulnerabilidade com severidade `CRITICAL`, ele retorna exit-code 1 e bloqueia o pipeline imediatamente.*
>
> *Para demonstrar o funcionamento na prática, abri um Pull Request adicionando a dependência `pyyaml==5.1`, que possui a vulnerabilidade crítica `CVE-2019-20477` de Execução Remota de Código (RCE).*
>
> *(Mostre o PR no GitHub)*: *Vejam o resultado: o build e o linter passaram, mas o step de Security Scan falhou e bloqueou o Pull Request! Abrindo os logs do Trivy, vemos a detecção explícita da CVE Crítica.*
>
> *(Mostre a correção)*: *Em seguida, removi a dependência vulnerável. O pipeline reexecutou automaticamente, o Trivy atestou 0 vulnerabilidades críticas e o pipeline ficou 100% verde, autorizando o avanço!"*

---

## 🚀 Ato 3: Docker Build & GitOps com ArgoCD (3 a 4 minutos)

### 🖥️ O que mostrar na tela:
1. No VS Code, mostre as linhas 236 a 276 do `_reusable-python-ci.yml` (Job `update-gitops` atualizando o `deployment.yaml` com `sed`).
2. Mude para a aba do navegador no **ArgoCD UI** (`https://localhost:8080`).
3. Mostre os cards das 5 aplicações sincronizadas: `auth-service`, `flag-service`, `targeting-service`, `evaluation-service`, `analytics-service`.
4. Clique em uma aplicação (ex: `flag-service`):
   - Mostre a árvore de Pods verdes (**Synced / Healthy**).
   - Clique no Pod e abra a aba **SUMMARY** (mostre a imagem oficial puxada do ECR).
   - Clique no botão **APP DETAILS → HISTORY AND ROLLBACK** (mostre a lista de revisões vinculadas aos hashes do Git).
5. Mostre no terminal que todos os pods estão rodando saudáveis:
   ```bash
   kubectl get pods -n togglemaster
   ```

### 🗣️ O que falar:
> *"Com a aprovação na esteira de segurança e merge na branch `main`, entram em ação os dois últimos jobs do pipeline:*
>
> - *`Docker Build & Push`: Compila o container, executa um **Container Scan com Trivy** na imagem e publica no Amazon ECR com uma tag imutável baseada no commit hash (ex: `v1.0.0-SHA`).*
> - *`Update GitOps`: Em vez de permitir que o CI execute comandos imperativos no cluster com credenciais administrativas, o pipeline atualiza declarativamente o arquivo `deployment.yaml` na pasta `gitops/` e faz commit automático.*
>
> *(Mude para a tela do ArgoCD)*: *E aqui temos o coração do GitOps: o **ArgoCD**.*
>
> - *Utilizamos o pattern **App of Apps** (`applications.yaml`), onde o ArgoCD gerencia a aplicação pai `togglemaster` e os 5 microsserviços.*
> - *O ArgoCD monitora continuamente o repositório Git. Quando o bot do CI comita a nova tag da imagem, o ArgoCD detecta o 'drift' (diferença entre o estado desejado no Git e o estado atual no cluster) e dispara um **Rolling Update** automático, garantindo zero downtime.*
> - *Como podem ver na interface:*
>   - *Todas as 5 aplicações estão com status **Synced** e **Healthy**.*
>   - *Clicando no Pod de `flag-service`, vemos a imagem oficial puxada diretamente do nosso ECR autenticado.*
>   - *Na aba de **Histórico**, temos a rastreabilidade completa de todas as versões deployadas com autor, timestamp e hash do Git, permitindo rollback com 1 clique se necessário.*
> - *Além disso, os dados sensíveis como URLs dos bancos RDS e Redis são gerenciados de forma centralizada através de Secrets do Kubernetes, eliminando credenciais em texto plano."*

---

## 💰 Ato 4: FinOps e Conclusão (1 a 2 minutos)

### 🖥️ O que mostrar na tela:
1. Mostre o arquivo `terraform/terraform.tfvars` no VS Code.
2. Mostre o terminal com os pods e serviços ativos.
3. Volte para a página principal do repositório no GitHub.

### 🗣️ O que falar:
> *"Para finalizar, um aspecto fundamental em engenharia de nuvem moderna: **FinOps e Governança de Custos**.*
>
> *Para viabilizar este ambiente complexo com o menor custo possível na AWS:*
> - *Configuramos os nós do EKS com `t3.small` On-Demand, respeitando a cota da conta e limites de Free Tier.*
> - *Utilizamos instâncias `db.t3.micro` para os 3 bancos RDS PostgreSQL e `cache.t3.micro` para o Redis (elegíveis ao Free Tier).*
> - *Desativamos backups redundantes e métricas pagas do CloudWatch Logs para evitar custos de ingestão desnecessários.*
> - *E mantivemos a tabela DynamoDB em modo `PAY_PER_REQUEST`, gerando custo zero enquanto ociosa.*
>
> *E cumprindo as boas práticas de ciclo de vida, assim que finalizarmos esta demonstração, executamos o comando `terraform destroy` para zerar qualquer consumo de recursos da nuvem.*
>
> *Com isso, cobrimos 100% dos requisitos da Fase 3: IaC com Terraform, DevSecOps com SAST/SCA/Gates no GitHub Actions, e GitOps com ArgoCD e EKS na AWS.*
>
> *Muito obrigado e fico à disposição para dúvidas!"*

---

## 📌 Guia Rápido de Comandos para a Apresentação

```bash
# 1. Checar nós do EKS
kubectl get nodes -o wide

# 2. Checar pods do ToggleMaster
kubectl get pods -n togglemaster

# 3. Checar status das aplicações no ArgoCD via CLI
kubectl get applications -n argocd

# 4. Iniciar port-forward do ArgoCD (se cair a conexão)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 5. Obter senha do ArgoCD
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# 6. Destruir infraestrutura após a gravação
cd terraform
terraform destroy
```
