#!/bin/bash
# Quick fix script for PVC issue on bare-metal Kubernetes cluster

set -e

echo "=== Fixing PVC Issue ==="
echo ""

echo "Step 1: Creating StorageClass..."
kubectl apply -f storageclass-hostpath.yaml
echo "✓ StorageClass created"
echo ""

echo "Step 2: Creating PersistentVolume..."
echo "⚠️  Make sure to edit postgres-pv.yaml and set the 'path' field to a directory on your node"
read -p "Press Enter to continue after editing postgres-pv.yaml..."
kubectl apply -f postgres/postgres-pv.yaml
echo "✓ PersistentVolume created"
echo ""

echo "Step 3: Deleting old PVC..."
kubectl delete pvc postgres-pvc --ignore-not-found=true
echo "✓ Old PVC deleted"
echo ""

echo "Step 4: Creating new PVC..."
kubectl apply -f postgres/postgres-pvc.yaml
echo "✓ New PVC created"
echo ""

echo "Step 5: Waiting for PVC to bind..."
sleep 5
kubectl get pvc postgres-pvc
echo ""

echo "Step 6: Checking pod status..."
kubectl get pods -l app=postgres
echo ""

echo "=== Done ==="
echo ""
echo "Verify with:"
echo "  kubectl get pv"
echo "  kubectl get pvc"
echo "  kubectl get pods -l app=postgres"

