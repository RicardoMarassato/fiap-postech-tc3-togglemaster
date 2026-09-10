# Guia do ToggleMaster V3: De Júnior para Júnior 🚀
> Um walkthrough visual, descomplicado e prático sobre Infraestrutura como Código (Terraform), DevSecOps (GitHub Actions) e GitOps (ArgoCD).

---

## 🧭 O Que Você Vai Aprender Aqui?

1. [O Que é o ToggleMaster e Qual Era o Problema?](#1-o-que-é-o-togglemaster-e-qual-era-o-problema)
2. [O Princípio: "Se não está no código, não existe"](#2-o-princípio-se-não-está-no-código-não-existe)
3. [Pilar 1: Infraestrutura como Código (Terraform)](#3-pilar-1-infraestrutura-como-código-terraform)
4. [Pilar 2: Esteira DevSecOps (GitHub Actions)](#4-pilar-2-esteira-devsecops-github-actions)
5. [Pilar 3: Entrega Contínua e GitOps (ArgoCD)](#5-pilar-3-entrega-contínua-e-gitops-argocd)
6. [O Ciclo de Vida de Uma Mudança de Código (End-to-End)](#6-o-ciclo-de-vida-de-uma-mudança-de-código-end-to-end)
7. [Como os 5 Microsserviços Conversam Entre Si](#7-como-os-5-microsserviços-conversam-entre-si)
8. [O "Pulo do Gato": Bugs e Desafios Reais que Corrigimos](#8-o-pulo-do-gato-bugs-e-desafios-reais-que-corrigimos)
9. [Glossário de Sobrevivência DevOps](#9-glossário-de-sobrevivência-devops)

---

## 1. O Que é o ToggleMaster e Qual Era o Problema?

O **ToggleMaster** é um sistema corporativo de **Feature Flags** (chaves que ativam ou desativam funcionalidades de um aplicativo em tempo real sem precisar reiniciar o app nem fazer novo deploy). 

Imagine que você criou um botão "Pagar com Pix" no seu app:
* **Com Feature Flag:** Você ativa o botão para 10% dos usuários. Se der erro, desativa em 1 segundo no painel.
* **Sem Feature Flag:** Você sobe a versão para 100% dos usuários. Se quebrar, precisa fazer rollback às pressas e torcer para o deploy não demorar.

### A História: Da Fase 2 para a Fase 3

* **Na Fase 2:** O time dividiu o sistema antigo em **5 microsserviços** e subiu no Kubernetes (AWS EKS). Funcionou, mas o modo de operação era um **caos silencioso**:
  - Os recursos da AWS foram criados clicando no console gráfico da AWS (se o datacenter caísse, levaria dias clicando para recriar tudo).
  - Cada desenvolvedor rodava `kubectl apply` do seu próprio notebook (se o colega sobrescrevesse seu arquivo, seu deploy sumia).
  - Se alguém subisse uma biblioteca insegura, ela ia direto para produção.
* **Na Fase 3:** A diretoria decretou: **"Chega de cliques manuais! Se não está no código, não existe."**

---

## 2. O Princípio: "Se não está no código, não existe"

Esse lema resume a filosofia da automação moderna:

```
    MUNDO ANTIGO (Manual / Fase 2)             MUNDO MODERNO (Automatizado / Fase 3)
   ┌───────────────────────────────┐           ┌───────────────────────────────────┐
   │ Dev clica na console AWS      │           │ Arquivos .tf (Terraform)          │
   │ Dev roda kubectl apply local  │    VS     │ Workflows de CI/CD (Segurança)    │
   │ Dev copia senha no Slack      │           │ GitOps com ArgoCD (Sincronização) │
   └───────────────────────────────┘           └───────────────────────────────────┘
         ❌ Erros humanos                            ✅ 100% Auditável e Replicável
         ❌ Sem rastreabilidade                      ✅ Segurança "Shift-Left"
         ❌ Impossível recriar rápido                ✅ Recuperação em Minutos
```

Tudo agora vive dentro do Git:
1. A infraestrutura vive em arquivos `.tf` (**Terraform**).
2. As regras de teste e segurança vivem em `.yml` (**GitHub Actions**).
3. Os manifestos do Kubernetes vivem na pasta `gitops/` gerenciada pelo **ArgoCD**.

---

## 3. Pilar 1: Infraestrutura como Código (Terraform)

### O que o Terraform faz?
Pense no Terraform como a **"planta e orçamento de uma casa"**: em vez de você ligar para a pedreira, para a loja de cimento e para o eletricista um por um, você escreve a planta em arquivos de texto. O Terraform lê a planta, olha o que já existe no terreno (a nuvem AWS) e constrói exatamente o que falta.

### Como a Infraestrutura foi Desenhada:

```
                          ┌─────────────────────────────────────────┐
                          │          AWS VPC (10.0.0.0/16)          │
                          │                                         │
 ┌──────────────────────┐ │  ┌───────────────────────────────────┐  │
 │  INTERNET / CLIENTES │─┼─▶│     Subnets Públicas (com NAT)    │  │
 └──────────────────────┘ │  └─────────────────┬─────────────────┘  │
                          │                    │                    │
                          │  ┌─────────────────▼─────────────────┐  │
                          │  │          Subnets Privadas         │  │
                          │  │                                   │  │
                          │  │  ┌─────────────────────────────┐  │  │
                          │  │  │     Cluster Kubernetes      │  │  │
                          │  │  │          (AWS EKS)          │  │  │
                          │  │  │  [auth] [flag] [target]     │  │  │
                          │  │  │  [evaluation] [analytics]   │  │  │
                          │  │  └──────┬───────┬───────┬──────┘  │  │
                          │  │         │       │       │         │  │
                          │  │         ▼       ▼       ▼         │  │
                          │  │     ┌──────┐ ┌─────┐ ┌──────┐     │  │
                          │  │     │3x RDS│ │Redis│ │ SQS  │     │  │
                          │  │     │Postg.│ │Cache│ │Fila  │     │  │
                          │  │     └──────┘ └─────┘ └──┬───┘     │  │
                          │  │                         │         │  │
                          │  │                         ▼         │  │
                          │  │                    ┌─────────┐    │  │
                          │  │                    │DynamoDB │    │  │
                          │  │                    │Analytics│    │  │
                          │  │                    └─────────┘    │  │
                          │  └───────────────────────────────────┘  │
                          └─────────────────────────────────────────┘
```

### O que cada componente faz:
* **VPC e Subnets:** Isola a rede. Criamos subnets públicas (para o Load Balancer e NAT Gateway) e subnets privadas (onde rodam os servidores e bancos de dados, sem IP público, para ninguém invadir direto da internet).
* **Cluster EKS:** O Kubernetes gerenciado pela AWS onde rodam os contêineres Docker dos nossos serviços.
* **3x RDS PostgreSQL:** 3 bancos separados (`auth_db`, `flags_db`, `targeting_db`). Cada serviço tem seu próprio banco para não haver acoplamento.
* **ElastiCache Redis:** Um banco de cache ultrarrápido em memória RAM. Usado pelo `evaluation-service` para responder em milissegundos se uma flag está ativa ou não.
* **Fila SQS:** Uma esteira de mensagens assíncronas. Quando alguém avalia uma flag, o serviço joga um bilhete no SQS e responde imediatamente ao cliente, sem fazê-lo esperar a gravação dos relatórios.
* **DynamoDB:** Um banco NoSQL que recebe os eventos da fila SQS para relatórios e telemetria.
* **5 Repositórios ECR:** O "Docker Hub" privado da AWS onde guardamos as imagens compiladas dos serviços.

### O Desafio da "LabRole" no AWS Academy:
> **Atenção:** Em contas da faculdade (AWS Academy), alunos **não têm permissão** de criar regras de acesso (IAM Roles). 
> **Nossa Solução:** Configuramos o Terraform para não criar roles novas. Ele faz uma busca (*data source*) pela role existente chamada `LabRole` e a empresta para o EKS e os nós!

### O "Lock" do Estado no S3:
Quando duas pessoas rodam Terraform ao mesmo tempo, elas podem corromper a infraestrutura. Para resolver isso, guardamos o arquivo de estado (`terraform.tfstate`) em um Bucket S3 da AWS e ativamos a opção nativa `use_lockfile = true` do Terraform 1.10+. Quando alguém inicia um apply, o Terraform "tranca" o arquivo e ninguém consegue sobrescrever!

---

## 4. Pilar 2: Esteira DevSecOps (GitHub Actions)

### O que significa "DevSecOps" e "Shift-Left"?
No passado, a segurança só era checada quando o sistema já estava em produção. Se achassem uma falha, o prejuízo já estava feito.
**Shift-Left** significa "puxar a segurança para a esquerda na linha do tempo", ou seja, testar vulnerabilidades no exato momento em que o programador digita o código e abre um Pull Request!

### O Fluxo do Pipeline (Estágio por Estágio):

```
 [Dev abre PR ou dá Push na Main]
               │
               ▼
 ┌──────────────────────────┐
 │ 1. BUILD & TEST          │  -> Compila o código e roda testes unitários.
 │    (go test / pytest)    │  -> Garante que nada básico quebrou.
 └─────────────┬────────────┘
               │ Passou ✅
               ▼
 ┌──────────────────────────┐
 │ 2. LINTER / ANÁLISE      │  -> golangci-lint (Go) e flake8/pylint (Python).
 │    ESTÁTICA              │  -> Verifica indentação, padrões e más práticas.
 └─────────────┬────────────┘
               │ Passou ✅
               ▼
 ┌──────────────────────────┐
 │ 3. SECURITY SCAN         │
 │  * SAST (gosec / bandit) │  -> Analisa o código-fonte em busca de brechas.
 │  * SCA (Trivy fs mode)   │  -> Varre os arquivos go.mod / requirements.txt.
 └─────────────┬────────────┘
               │
               ├── ❌ Achou vulnerabilidade CRÍTICA? -> 🛑 PIPELINE BLOQUEADO!
               │                                      (A imagem NÃO é gerada)
               │ Passou ✅
               ▼
 ┌──────────────────────────┐
 │ 4. DOCKER BUILD & SCAN   │  -> Constrói a imagem Docker.
 │    (Trivy image scan)    │  -> Varre o sistema operacional do contêiner.
 └─────────────┬────────────┘
               │
               ├── ❌ Achou vulnerabilidade CRÍTICA? -> 🛑 PIPELINE BLOQUEADO!
               │ Passou ✅
               ▼
 ┌──────────────────────────┐
 │ 5. PUSH PARA O ECR       │  -> Faz login seguro na AWS via OIDC (sem senhas salvas!).
 │    (v1.0.0-<commit_sha>) │  -> Envia a imagem com uma etiqueta imutável.
 └─────────────┬────────────┘
               │ Passou ✅
               ▼
 ┌──────────────────────────┐
 │ 6. UPDATE GITOPS         │  -> Atualiza a tag da imagem no arquivo
 │    (deployment.yaml)     │     gitops/apps/<servico>/deployment.yaml e commita!
 └──────────────────────────┘
```

### O que são SAST e SCA?
* **SAST (Static Application Security Testing):** O robô lê o seu código fonte linha por linha, como um revisor de texto. Ele avisa: *"Ei, você concatenou uma string direto no SQL, isso permite SQL Injection!"*. Usamos **gosec** para Go e **bandit** para Python.
* **SCA (Software Composition Analysis):** O robô analisa as bibliotecas externas que você instalou (ex: via `pip` ou `go get`). Usamos o **Trivy** para avisar: *"Essa versão do requests que você importou tem uma vulnerabilidade crítica conhecida mundialmente"*.

### A Regra de Ouro: "Gate de Bloqueio"
Se o Trivy encontrar qualquer vulnerabilidade com severidade **CRITICAL**, configuramos `exit-code: 1`. Isso significa que o GitHub Actions aborta a execução na hora com uma cruz vermelha. A imagem Docker **nunca** é criada e o deploy é impedido de acontecer!

---

## 5. Pilar 3: Entrega Contínua e GitOps (ArgoCD)

### O que é GitOps?
No modelo tradicional, o GitHub Actions se conectava no Kubernetes via SSH ou credencial administrativa e executava:
```bash
kubectl apply -f deployment.yaml  # ❌ Não faça isso em produção!
```
Isso é perigoso porque seu CI precisa de credenciais totais de administrador do cluster, e se alguém rodar um comando manual no terminal do Kubernetes, o CI não sabe.

No **GitOps**, a lógica se inverte:
1. **O Git é a Única Fonte da Verdade:** Tudo o que deve rodar no cluster está escrito em manifestos YAML no repositório.
2. **O ArgoCD é o "Vigia":** Ele roda **dentro** do Kubernetes. Ele fica o tempo todo comparando:
   * *"O que está escrito no Git?"* (Estado Desejado)
   * *"O que está rodando nos pods agora?"* (Estado Real)
3. **Reconciliação Automática:** Se você alterar a tag da imagem no Git, o ArgoCD detecta a mudança e faz o download da imagem nova nos pods sem você encostar no terminal!

```
               COMO FUNCIONA O FLUXO GITOPS NA PRÁTICA:

 ┌─────────────────────────┐
 │ 1. CI finaliza com      │
 │    sucesso e pusha nova │
 │    imagem no ECR        │
 └────────────┬────────────┘
              │
              ▼
 ┌────────────────────────────────────────────────────────┐
 │ 2. O CI commita no arquivo:                            │
 │    gitops/apps/flag-service/deployment.yaml            │
 │    (mudando image: ...:v1.0.0-old para v1.0.0-new)     │
 └────────────────────────────┬───────────────────────────┘
                              │
                              ▼
 ┌────────────────────────────────────────────────────────┐
 │ 3. ArgoCD detecta o commit no repositório Git          │
 │    Status: "OutOfSync"                                 │
 └────────────────────────────┬───────────────────────────┘
                              │ Auto-Sync (Self-Heal)
                              ▼
 ┌────────────────────────────────────────────────────────┐
 │ 4. ArgoCD atualiza os Pods no cluster EKS              │
 │    Status: "Synced & Healthy"                          │
 └────────────────────────────────────────────────────────┘
```

### E se alguém alterar um pod na mão via kubectl?
O ArgoCD tem a opção `selfHeal: true`. Se um desenvolvedor rebelde entrar no cluster e alterar a réplica de 2 para 10 manualmente, em menos de 10 segundos o ArgoCD percebe a discrepância com o Git e **desfaz** a alteração manual, voltando para o que está no código!

---

## 6. O Ciclo de Vida de Uma Mudança de Código (End-to-End)

Vamos ver o caminho que uma linha de código percorre desde a máquina do desenvolvedor até o usuário final:

```
 [1. Dev altera código no VS Code]
            │
            ▼
 [2. git push origin feat/nova-flag]
            │
            ▼
 [3. GitHub Actions dispara o CI]
            ├── Compila e roda testes unitários
            ├── Roda golangci-lint / flake8
            ├── Faz SAST (gosec / bandit)
            └── Faz SCA com Trivy (dependências)
            │
            ▼
 [4. Dev abre Pull Request e equipe aprova]
            │
            ▼
 [5. Merge na branch "main"]
            ├── Constrói a imagem Docker
            ├── Roda Container Scan no SO da imagem
            ├── Push no Amazon ECR (tag: v1.0.0-a1b2c3d)
            └── Atualiza gitops/.../deployment.yaml
            │
            ▼
 [6. ArgoCD detecta a alteração no Git]
            │
            ▼
 [7. ArgoCD baixa a nova imagem e faz Rolling Update no EKS]
            │
            ▼
 [8. Usuário final utiliza a nova funcionalidade sem downtime!]
```

---

## 7. Como os 5 Microsserviços Conversam Entre Si

Para entender por que dividimos em 5 serviços e como eles se comunicam:

```
                       REQUISIÇÃO DE UM APLICATIVO
                                    │
                                    ▼
                     ┌──────────────────────────────┐
                     │ NGINX Ingress Controller     │
                     │ (Load Balancer da AWS)       │
                     └──────────────┬───────────────┘
                                    │
           ┌────────────────────────┴────────────────────────┐
           ▼                                                 ▼
┌───────────────────────┐                         ┌───────────────────────┐
│     auth-service      │                         │  evaluation-service   │
│ (Emite e valida keys) │                         │   (Caminho Crítico)   │
└──────────┬────────────┘                         └──────────┬────────────┘
           │                                                 │
           ▼                                                 │
     [( auth_db )]                                           │
                                         ┌───────────────────┴───────────────────┐
                                         │                                       │
                                         ▼                                       ▼
                              ┌────────────────────┐                  ┌────────────────────┐
                              │  ElastiCache Redis │                  │   Fila AWS SQS     │
                              │ (Cache em RAM: 30s)│                  │ (Mensagem de Log)  │
                              └────────────────────┘                  └──────────┬─────────┘
                                                                                 │
                                                                                 ▼
                                                                      ┌────────────────────┐
                                                                      │ analytics-service  │
                                                                      │ (Worker Assíncrono)│
                                                                      └──────────┬─────────┘
                                                                                 │
                                                                                 ▼
                                                                          [( DynamoDB )]
```

### Por que essa divisão é genial?
1. **O cliente nunca espera:** O `evaluation-service` consulta o Redis primeiro. A resposta sai em ~2 milissegundos.
2. **O banco principal não engargala:** Ele não precisa consultar o PostgreSQL em toda requisição.
3. **Auditoria assíncrona:** A gravação de que a flag foi usada é despachada para o SQS. O `analytics-service` processa isso em segundo plano e grava no DynamoDB com calma.

---

## 8. O "Pulo do Gato": Bugs e Desafios Reais que Corrigimos

Durante o desenvolvimento deste desafio, encontramos armadilhas clássicas que acontecem no dia a dia de um time sênior. Saber explicá-las vai impressionar qualquer entrevistador:

### 1. O Bug do Evaluation Service (Go vs Python)
* **O Problema:** O pipeline de CI antigo usava o arquivo `_reusable-python-ci.yml` para o `evaluation-service`. O CI tentava rodar `pip install -r requirements.txt`, mas o serviço foi escrito em **Go** (`evaluator.go`, `main.go`). A esteira quebrava imediatamente!
* **O Que Fizemos:** Criamos o workflow reusável `_reusable-go-ci.yml` e configuramos o `evaluation-service` e o `auth-service` para usarem Go 1.21/1.22, executando `golangci-lint`, `gosec` e testes nativos de Go.

### 2. O Erro de Sintaxe do Terraform com o Provider AWS v5
* **O Problema:** O código usava `security_group_id` dentro do bloco `ingress` de Security Groups e usava `dynamic "redrive_policy"` no SQS. Essas duas sintaxes pertencem a versões antigas do Terraform e faziam o comando `terraform validate` falhar.
* **O Que Fizemos:** Atualizamos para a sintaxe do AWS Provider v5:
  - Mudamos para `security_groups = [ingress.value]`.
  - Mudamos a política de fila morta para o atributo JSON `redrive_policy = jsonencode(...)`.
  - O `terraform validate` passou com **"Success! The configuration is valid"**.

### 3. As URLs de Repositório do ArgoCD
* **O Problema:** O arquivo `applications.yaml` do ArgoCD estava apontando para `https://github.com/SEU_USUARIO/...`. Se aplicássemos no cluster, o ArgoCD nunca conseguiria clonar os manifestos.
* **O Que Fizemos:** Atualizamos todas as URLs para o repositório oficial do Ricardo Marassato (`https://github.com/RicardoMarassato/fiap-postech-tc3-togglemaster.git`).

### 4. O Rewrite Target no Ingress Controller
* **O Problema:** Quando o Ingress Controller recebia uma chamada em `http://meu-alb/auth/health`, ele repassava `/auth/health` para o serviço. Como o app esperava `/health`, dava erro HTTP 404.
* **O Que Fizemos:** Criamos o `gitops/base/ingress.yaml` usando a anotação `nginx.ingress.kubernetes.io/rewrite-target: /$2` com regex `path: /auth(/|$)(.*)`. Assim, o Ingress arranca o prefixo `/auth` antes de entregar para o pod!

### 5. O Mistério do Security Group dos Nós do EKS (Timeout no RDS e Redis)
* **O Problema:** O RDS PostgreSQL e o ElastiCache Redis foram configurados para aceitar conexões vindas do Security Group `eks_nodes`. Porém, ao tentar conectar da aplicação, dava timeout! Ao inspecionar os nós EC2 criados pelo EKS Managed Node Group, descobrimos que o EKS anexa automaticamente o Security Group primário do cluster (`cluster_primary_security_group_id`), e não o SG customizado criado avulso.
* **O Que Fizemos:** Exportamos o `cluster_primary_security_group_id` no módulo do EKS e o adicionamos na lista `allowed_security_group_ids` do RDS e do Redis. A porta 5432 e 6379 abriram instantaneamente para os pods!

### 6. Caracteres Especiais em Senhas de Banco (Quebra de URL RFC 3986)
* **O Problema:** O Terraform gerou senhas fortes contendo caracteres como `#`, `[`, `]`, `<`, `>`. Quando colocamos a senha diretamente na URL `postgresql://user:pass#123@host/db`, o caractere `#` foi interpretado como o início do fragmento da URL pelos drivers do Go e Python, quebrando a conexão.
* **O Que Fizemos:** Codificamos os caracteres especiais via URL-encoding (`%23` para `#`, `%5B` para `[`, etc.), normalizando as strings de conexão do banco.

### 7. O Poder do GitOps: Por que Edições Manuais Sumiam?
* **O Problema:** Quando tentávamos rodar `kubectl apply` para testar os segredos temporariamente, em menos de 1 minuto o ArgoCD desfazia tudo e voltava para o valor antigo `HOST`.
* **O Que Fizemos:** Essa é a essência do GitOps! O ArgoCD opera com reconciliação ativa (*self-healing*). A única forma válida de alterar algo em produção é fazendo `git commit` e `git push origin main`. Assim que comitamos o `gitops/base/secrets.yaml`, o ArgoCD sincronizou e todas as 5 aplicações ficaram **Synced & Healthy**!

### 8. Atualização do Kubernetes 1.31 e PostgreSQL 18.3
* **O Problema:** A versão 1.29 do Kubernetes foi descontinuada na AWS EKS, gerando erro `400 InvalidParameterException: unsupported Kubernetes version 1.29`.
* **O Que Fizemos:** Atualizamos a versão do cluster para **1.31** e atualizamos o motor do RDS para **PostgreSQL 18.3** com parameter group `postgres18`, garantindo conformidade com as versões vigentes da AWS.

---

## 9. Glossário de Sobrevivência DevOps

* **IaC (Infrastructure as Code):** Descrever servidores, redes e bancos através de arquivos de texto versionáveis (ex: Terraform).
* **State (tfstate):** O mapa mental do Terraform. Um arquivo JSON onde ele anota o ID de cada recurso que já criou na AWS.
* **DevSecOps:** A prática de integrar verificações de segurança automáticas em todas as etapas do ciclo de desenvolvimento de software.
* **SAST:** Teste estático de segurança. O scanner analisa o código-fonte antes dele ser compilado.
* **SCA:** Análise de composição de software. O scanner verifica se as bibliotecas de terceiros possuem vulnerabilidades (CVEs) conhecidas.
* **GitOps:** Gerenciamento declarativo de infraestrutura e aplicações onde o Git é a única fonte da verdade e agentes no cluster reconciliam as mudanças.
* **ArgoCD:** Ferramenta declarativa de GitOps para Kubernetes que monitora repositórios Git e sincroniza os manifestos com o cluster.
* **OIDC (OpenID Connect):** Protocolo de autenticação que permite ao GitHub Actions conversar com a AWS sem precisar de senhas estáticas salvas no repositório.
* **EKS (Elastic Kubernetes Service):** Serviço gerenciado de Kubernetes da Amazon Web Services.
* **DLQ (Dead Letter Queue):** Uma fila de "mensagens mortas". Se uma mensagem da fila SQS falhar 3 vezes consecutivas, ela é enviada para a DLQ para não travar a fila principal e permitir investigação.
