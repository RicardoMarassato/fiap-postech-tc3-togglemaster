#!/bin/bash
# =============================================================================
# Script para instalar ArgoCD no cluster EKS
# =============================================================================

set -e

echo "=== Instalando ArgoCD ==="

# Criar namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Aguardando pods do ArgoCD ficarem prontos..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Obter senha inicial do admin
echo ""
echo "=== ArgoCD instalado com sucesso! ==="
echo ""
echo "Para obter a senha inicial do admin:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "Para acessar a UI do ArgoCD (port-forward):"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "Acesse: https://localhost:8080"
echo "Usuário: admin"
echo ""

# Aplicar as Applications do ToggleMaster
echo "Aplicando configurações do ToggleMaster..."
kubectl apply -f applications.yaml

echo ""
echo "=== Setup completo! ==="
echo "O ArgoCD irá sincronizar automaticamente os 5 microsserviços."
