# ToggleMaster - GitOps

Manifestos Kubernetes gerenciados pelo ArgoCD para deploy contínuo dos microsserviços.

## Estrutura

```
gitops/
├── argocd/
│   ├── applications.yaml   # Configuração das apps no ArgoCD
│   └── install.sh          # Script de instalação do ArgoCD
├── base/
│   ├── namespace.yaml      # Namespace togglemaster
│   ├── configmap.yaml      # ConfigMaps compartilhados
│   └── secrets.yaml        # Templates de secrets (usar External Secrets em prod)
└── apps/
    ├── auth-service/
    │   └── deployment.yaml
    ├── flag-service/
    │   └── deployment.yaml
    ├── targeting-service/
    │   └── deployment.yaml
    ├── evaluation-service/
    │   └── deployment.yaml
    └── analytics-service/
        └── deployment.yaml
```

## Fluxo GitOps

1. **CI Pipeline** builda e pusha imagem para ECR com tag `v1.0.0-<commit>`
2. **CI Pipeline** atualiza o `deployment.yaml` do serviço com a nova tag
3. **ArgoCD** detecta a mudança no repo e sincroniza automaticamente
4. **Kubernetes** faz rolling update do deployment

## Setup

### 1. Instalar ArgoCD

```bash
cd gitops/argocd
chmod +x install.sh
./install.sh
```

### 2. Acessar UI do ArgoCD

```bash
# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Obter senha
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Acesse: https://localhost:8080

### 3. Configurar repositório

No ArgoCD, adicione o repositório:
- **Repository URL**: `https://github.com/SEU_USUARIO/fiap-postech-tc3-togglemaster.git`
- **Path**: `gitops/`

### 4. Aplicar Applications

```bash
kubectl apply -f gitops/argocd/applications.yaml
```

## Secrets

Para produção, use **External Secrets Operator** para sincronizar secrets do AWS Secrets Manager:

```bash
# Instalar External Secrets
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
```

Depois, crie `SecretStore` e `ExternalSecret` para cada secret.

## Atualizando manualmente uma imagem

Se precisar atualizar manualmente (não recomendado em prod):

```bash
# Editar deployment
kubectl set image deployment/auth-service \
  auth-service=ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/togglemaster/auth-service:v1.0.0-abc1234 \
  -n togglemaster
```

O ArgoCD detectará que o cluster está "OutOfSync" com o repo.

## Rollback

No ArgoCD UI, clique em "History" e selecione uma versão anterior para fazer rollback.

Ou via CLI:

```bash
argocd app rollback auth-service
```
