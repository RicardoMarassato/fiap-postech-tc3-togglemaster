#!/bin/bash
# =============================================================================
# Build e Push inicial de imagens para o AWS ECR
# =============================================================================
set -e

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --region "${REGION}" --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "=== Autenticando Docker no Amazon ECR (${REGISTRY}) ==="
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${REGISTRY}"

SERVICES=("auth-service" "flag-service" "targeting-service" "evaluation-service" "analytics-service")

for SERVICE in "${SERVICES[@]}"; do
  echo ""
  echo "=== [${SERVICE}] Construindo imagem Docker ==="
  docker build --network=host -t "${REGISTRY}/togglemaster/${SERVICE}:latest" "../services/${SERVICE}"
  
  echo "=== [${SERVICE}] Enviando para o ECR ==="
  docker push "${REGISTRY}/togglemaster/${SERVICE}:latest"
done

echo ""
echo "=== Sucesso! Todas as 5 imagens foram enviadas para o ECR. ==="
