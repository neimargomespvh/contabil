#!/usr/bin/env bash
set -euo pipefail
: "${AWS_REGION:=sa-east-1}"
: "${ECR_REPO:=contabil-api}"
: "${ECS_CLUSTER:=contabil-cluster}"
: "${ECS_SERVICE:=contabil-api}"
: "${TAG:=$(git describe --tags --always)}"
echo "🚀 Deploy $TAG"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPO"
docker build -t "$ECR_REPO:$TAG" . && docker tag "$ECR_REPO:$TAG" "$ECR_REPO:latest"
docker push "$ECR_REPO:$TAG" && docker push "$ECR_REPO:latest"
aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --force-new-deployment
aws ecs wait services-stable --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE"
echo "✅ Deploy concluído"
