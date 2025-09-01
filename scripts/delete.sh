#!/bin/bash
# delete.sh
# Script para eliminar todos los recursos en Kubernetes automáticamente

echo "Eliminar todos los recursos en el Namespace"
kubectl delete namespace my-app

echo "Eliminar Persistent Volume"
kubectl delete PersistentVolume my-volume

echo "Operacion exitosa"