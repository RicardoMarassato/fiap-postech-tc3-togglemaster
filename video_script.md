# Roteiro do Vídeo - Tech Challenge Fase 3

**Tempo estimado:** 10-15 minutos

---

## Parte 1: Introdução (1-2 min)

**O que falar:**
- "Olá, sou Ricardo Marassato, RM 370358"
- "Vou apresentar a entrega da Fase 3 do Tech Challenge: IaC, CI/CD com DevSecOps e GitOps"
- "O projeto é o ToggleMaster, um sistema de feature flags que evoluímos da Fase 2"

**O que mostrar:**
- README.md no GitHub (scroll rápido pela estrutura)
- Diagrama de arquitetura no README

---

## Parte 2: Infraestrutura como Código - Terraform (3-4 min)

**O que falar:**
- "Toda a infraestrutura foi codificada em Terraform, organizada em 7 módulos"
- "Networking, EKS, RDS, ElastiCache, DynamoDB, SQS e ECR"
- "Por limitação do AWS Academy, usamos a LabRole existente via data source"

**O que mostrar:**
1. Estrutura de pastas `terraform/`
2. Abrir `main.tf` - mostrar os módulos sendo chamados
3. Abrir `modules/eks/main.tf` - mostrar uso do LabRole
4. Abrir `backend.tf` - mostrar remote state com S3

**Demonstração (se der tempo/créditos):**
```bash
cd terraform
terraform init
terraform plan
# Mostrar o output do plan (não precisa aplicar se não tiver créditos)
```

---

## Parte 3: Pipeline CI/CD com DevSecOps (4-5 min)

**O que falar:**
- "Cada microsserviço tem um pipeline com estágios de segurança"
- "SAST com gosec para Go e bandit para Python"
- "SCA e Container Scan com Trivy"
- "Se encontrar vulnerabilidade CRITICAL, o pipeline bloqueia"

**O que mostrar:**
1. Pasta `.github/workflows/`
2. Abrir `ci-auth-service.yml` - explicar os jobs (build, lint, security, push)
3. Abrir `_reusable-python-ci.yml` - mostrar workflow reutilizável
4. GitHub Actions - mostrar uma execução passada (se tiver)

**Demonstração do bloqueio por vulnerabilidade:**
1. Editar `services/flag-service/requirements.txt`
2. Adicionar uma dependência vulnerável: `requests==2.25.0`
3. Commit e push
4. Mostrar o pipeline falhando no Trivy
5. Reverter a mudança
6. Mostrar o pipeline passando

> **Dica:** Prepare esse commit antes de gravar para não perder tempo.

---

## Parte 4: GitOps com ArgoCD (2-3 min)

**O que falar:**
- "O deploy não é feito pelo CI diretamente no cluster"
- "Usamos GitOps: o CI atualiza a tag da imagem no repositório"
- "O ArgoCD monitora o repositório e sincroniza automaticamente"

**O que mostrar:**
1. Pasta `gitops/` - estrutura
2. Abrir `gitops/apps/flag-service/deployment.yaml` - mostrar a tag da imagem
3. Abrir `gitops/argocd/applications.yaml` - mostrar configuração das apps
4. ArgoCD UI (se tiver cluster rodando):
   - Mostrar as 5 aplicações
   - Mostrar o sync automático

---

## Parte 5: Pipeline de Destroy (1 min)

**O que falar:**
- "Para economizar créditos, criei um pipeline de destroy com trigger manual"
- "Exige confirmação digitando DESTROY para evitar acidentes"

**O que mostrar:**
1. GitHub Actions → Terraform → Run workflow
2. Mostrar o dropdown com opção "destroy"
3. Mostrar o campo de confirmação
4. (Não precisa executar, só mostrar que existe)

---

## Parte 6: Encerramento (1 min)

**O que falar:**
- "Resumindo: toda infraestrutura como código, pipelines com gates de segurança, e GitOps para deploys"
- "O código está no repositório: github.com/RicardoMarassato/fiap-postech-tc3-togglemaster"
- "Obrigado!"

---

## Checklist Pré-Gravação

- [ ] AWS Academy logado (se for fazer terraform plan)
- [ ] Repositório GitHub público
- [ ] Preparar o commit com vulnerabilidade (requests==2.25.0) em uma branch separada
- [ ] Ter o ArgoCD rodando (opcional, se tiver créditos)
- [ ] VS Code ou editor aberto com os arquivos principais
- [ ] Fechar abas/apps desnecessárias

---

## Dicas de Gravação

1. **Resolução:** 1080p mínimo para o código ser legível
2. **Fonte:** Aumentar tamanho da fonte no terminal e editor (14-16pt)
3. **Zoom:** Dar zoom no navegador (125-150%) ao mostrar GitHub
4. **Fala:** Pausar entre as seções, não precisa correr
5. **Erros:** Se algo der errado, explicar o que aconteceu (demonstra conhecimento)

---

## Comandos Úteis para a Demo

```bash
# Terraform
cd terraform
terraform init
terraform plan
terraform apply  # só se tiver créditos

# kubectl (se tiver cluster)
aws eks update-kubeconfig --region us-east-1 --name togglemaster-dev-eks
kubectl get pods -n togglemaster

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
