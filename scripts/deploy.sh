#!/bin/bash
# deploy.sh
# Script para desplegar todos los recursos en Kubernetes automáticamente

echo "Iniciando minikube..."
minikube start

echo "Creando namespace..."
kubectl apply -f namespace/namespace_app.yaml

echo "Aplicando PersistentVolume y PersistentVolumeClaim..."
kubectl apply -f volumes/volume_app.yaml
kubectl apply -f volumes/pvc.yaml

echo "Aplicando ConfigMaps y Secrets..."
kubectl apply -f configMap/config_map_deployment_db.yaml
kubectl apply -f configMap/config_map_nginx.yaml
kubectl apply -f secrets/secret_deployment_db.yaml

echo "Desplegando la base de datos..."
kubectl apply -f deployments/bd_deployment.yaml
kubectl apply -f services/clusterip_deployment_db.yaml

echo "Desplegando backend..."
kubectl apply -f deployments/backend_deployment.yaml
kubectl apply -f services/clusterip_deployment_backend.yaml

echo "Desplegando frontend..."
kubectl apply -f deployments/frontend_deployment.yaml
kubectl apply -f services/nodeport_deployment_frontend.yaml

echo "Despliegue completado."
