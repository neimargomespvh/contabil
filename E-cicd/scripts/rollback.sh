#!/usr/bin/env bash
set -euo pipefail
: "${ECS_CLUSTER:=contabil-cluster}"
: "${ECS_SERVICE:=contabil-api}"
: "${PREVIOUS_TASK_DEF:?informe PREVIOUS_TASK_DEF}"
aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --task-definition "$PREVIOUS_TASK_DEF"
aws ecs wait services-stable --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE"
echo "↩️  Rollback concluído"
