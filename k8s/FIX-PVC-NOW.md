# Quick Fix for PVC Issue - Execute These Commands

Your cluster has no StorageClasses, so we need to create a manual PersistentVolume.

## Step 1: Create the StorageClass (optional, but recommended)

```bash
kubectl apply -f gatewayms/k8s/storageclass-hostpath.yaml
```

## Step 2: Create a Manual PersistentVolume

**IMPORTANT**: First, edit `gatewayms/k8s/postgres/postgres-pv.yaml` and update the `path` field to a directory on your node (e.g., `/data/postgres` or `/mnt/postgres`).

Then apply it:
```bash
kubectl apply -f gatewayms/k8s/postgres/postgres-pv.yaml
```

## Step 3: Delete and Recreate the PVC

```bash
# Delete the existing pending PVC
kubectl delete pvc postgres-pvc

# Recreate it with the updated configuration
kubectl apply -f gatewayms/k8s/postgres/postgres-pvc.yaml
```

## Step 4: Verify

```bash
# Check PV is available
kubectl get pv

# Check PVC is bound
kubectl get pvc

# Check pod starts
kubectl get pods -l app=postgres
```

## Alternative: Install Local Path Provisioner (Better for Production)

If you want dynamic provisioning (automatic volume creation), install local-path-provisioner:

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```

Then update the PVC to use `local-path` instead of `hostpath`.

