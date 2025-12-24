#!/bin/bash
# Complete fix script - run this on your k8s-node server
# Make sure all files are in the same directory structure

set -e

echo "=========================================="
echo "Fixing PVC Issue - Step by Step"
echo "=========================================="
echo ""

# Step 1: Create StorageClass
echo "Step 1/5: Creating StorageClass..."
kubectl apply -f storageclass-hostpath.yaml
echo "✓ StorageClass created"
kubectl get storageclass
echo ""

# Step 2: Create PersistentVolume
echo "Step 2/5: Creating PersistentVolume..."
kubectl apply -f postgres/postgres-pv.yaml
echo "✓ PersistentVolume created"
kubectl get pv
echo ""

# Step 3: Delete old PVC
echo "Step 3/5: Deleting old pending PVC..."
kubectl delete pvc postgres-pvc --ignore-not-found=true
echo "✓ Old PVC deleted"
echo ""

# Step 4: Create new PVC
echo "Step 4/5: Creating new PVC..."
kubectl apply -f postgres/postgres-pvc.yaml
echo "✓ New PVC created"
echo ""

# Step 5: Wait and verify
echo "Step 5/5: Waiting for binding and verifying..."
sleep 3
echo ""
echo "=== PVC Status ==="
kubectl get pvc
echo ""
echo "=== PV Status ==="
kubectl get pv
echo ""
echo "=== Pod Status ==="
kubectl get pods -l app=postgres
echo ""

echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "If PVC shows 'Bound' and pod shows 'Running', you're all set!"
echo "If not, check with: kubectl describe pvc postgres-pvc"

