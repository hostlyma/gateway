#!/bin/bash
# Diagnostic script for PVC issues

echo "=== Kubernetes PVC Diagnostic Script ==="
echo ""

echo "1. Checking StorageClasses available in cluster:"
echo "-----------------------------------------------"
kubectl get storageclass
echo ""

echo "2. Checking for default StorageClass:"
echo "-------------------------------------"
kubectl get storageclass -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}' | grep -E "true|default"
if [ $? -ne 0 ]; then
    echo "⚠️  WARNING: No default StorageClass found!"
    echo "   You need to either:"
    echo "   1. Set a StorageClass as default: kubectl patch storageclass <name> -p '{\"metadata\": {\"annotations\": {\"storageclass.kubernetes.io/is-default-class\": \"true\"}}}'"
    echo "   2. Or specify storageClassName in your PVC files"
fi
echo ""

echo "3. Checking PVC status:"
echo "----------------------"
kubectl get pvc
echo ""

echo "4. Checking PVC details (if exists):"
echo "------------------------------------"
kubectl describe pvc postgres-pvc 2>/dev/null || echo "PVC 'postgres-pvc' not found"
echo ""

echo "5. Checking pod status:"
echo "----------------------"
kubectl get pods -l app=postgres
echo ""

echo "6. Checking pod events (if postgres pod exists):"
echo "-----------------------------------------------"
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    kubectl describe pod $POD_NAME | grep -A 10 "Events:"
else
    echo "No postgres pod found"
fi
echo ""

echo "=== Diagnostic Complete ==="
echo ""
echo "Common solutions:"
echo "1. If no default StorageClass: Set one or specify storageClassName in PVC"
echo "2. If PVC is Pending: Check if StorageClass can provision volumes"
echo "3. If using local cluster (minikube/k3d): Install local-path provisioner"

