# PVC Troubleshooting Guide

## Problem: "pod has unbound immediate PersistentVolumeClaims"

This error occurs when a PersistentVolumeClaim (PVC) cannot be bound to a PersistentVolume (PV) because:
1. No default StorageClass exists in the cluster
2. The specified StorageClass doesn't exist
3. The StorageClass cannot provision volumes (insufficient resources, misconfiguration)

## Quick Diagnosis

Run the diagnostic script:
```bash
chmod +x gatewayms/k8s/diagnose-pvc.sh
./gatewayms/k8s/diagnose-pvc.sh
```

Or manually check:
```bash
# Check available StorageClasses
kubectl get storageclass

# Check which StorageClass is default (look for "default" annotation)
kubectl get storageclass -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}'

# Check PVC status
kubectl get pvc

# Check PVC details
kubectl describe pvc postgres-pvc

# Check pod events
kubectl describe pod <postgres-pod-name>
```

## Solutions

### Solution 1: Use Default StorageClass (Recommended)

If your cluster has a default StorageClass, the PVC should work automatically. The PVC files are configured to use the default by omitting the `storageClassName` field.

**Check if default exists:**
```bash
kubectl get storageclass -o json | grep -A 5 "is-default-class"
```

### Solution 2: Set a StorageClass as Default

If you have a StorageClass but it's not set as default:

```bash
# Replace <storage-class-name> with your StorageClass name
kubectl patch storageclass <storage-class-name> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```

### Solution 3: Specify StorageClass in PVC

If you can't set a default, edit the PVC file to specify a StorageClass:

**Edit `gatewayms/k8s/postgres/postgres-pvc.yaml`:**
```yaml
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: <your-storage-class-name>  # Uncomment and set
```

Common StorageClass names by platform:
- **GKE (Google)**: `standard` or `premium-rwo`
- **EKS (AWS)**: `gp2` or `gp3`
- **AKS (Azure)**: `default` or `managed-premium`
- **k3d/kind**: `local-path`
- **minikube**: `standard` (enable with `minikube addons enable default-storageclass`)

### Solution 4: Install Local Path Provisioner (Local Clusters)

For local development clusters (k3d, kind, minikube):

**Minikube:**
```bash
minikube addons enable default-storageclass
minikube addons enable storage-provisioner
```

**k3d/kind:**
Usually comes with local-path-provisioner. If not:
```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```

**Using our provided StorageClass:**
```bash
kubectl apply -f gatewayms/k8s/storageclass-local-path.yaml
```

### Solution 5: Create Manual PersistentVolume (Advanced)

If dynamic provisioning isn't available, create a PV manually:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/postgres
  # Or use other volume types: nfs, awsElasticBlockStore, etc.
```

Then update the PVC to use this PV by matching labels or using `volumeName`.

## Verification

After applying fixes:

```bash
# 1. Check PVC is bound
kubectl get pvc
# Should show STATUS: Bound

# 2. Check pod is running
kubectl get pods -l app=postgres
# Should show STATUS: Running

# 3. Verify volume is mounted
kubectl describe pod <postgres-pod-name> | grep -A 5 "Mounts:"
```

## Common Issues

### Issue: PVC stuck in "Pending"
**Cause**: No StorageClass available or StorageClass cannot provision
**Fix**: Check StorageClass exists and can provision volumes

### Issue: "no persistent volumes available"
**Cause**: No PVs match the PVC requirements
**Fix**: Ensure StorageClass can dynamically provision, or create manual PV

### Issue: "volumeBindingMode: WaitForFirstConsumer"
**Cause**: StorageClass waits for pod to be scheduled before binding
**Fix**: This is normal - the PVC will bind when the pod is created

## Additional Resources

- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

