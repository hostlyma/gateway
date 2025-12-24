# Accessing PostgreSQL from pgAdmin

Your PostgreSQL database is running in Kubernetes. Here are several ways to access it from pgAdmin.

## Database Connection Details

From your `postgres-secret.yaml`:
- **Host**: See options below
- **Port**: `5432` (or NodePort if using NodePort service)
- **Database**: `hostly`
- **Username**: `hostly_user`
- **Password**: `Diamantine@2`

---

## Option 1: Port Forwarding (Easiest - Recommended for Development)

This creates a temporary tunnel from your local machine to the PostgreSQL pod.

### Steps:

1. **On your local machine**, run:
   ```bash
   kubectl port-forward service/postgres-service 5432:5432
   ```
   
   Or if you want to forward directly to the pod:
   ```bash
   # First, get the pod name
   kubectl get pods -l app=postgres
   
   # Then port forward (replace <pod-name> with actual pod name)
   kubectl port-forward <pod-name> 5432:5432
   ```

2. **Keep the terminal open** - the port forward runs in the foreground

3. **In pgAdmin**, connect with:
   - **Host**: `localhost` or `127.0.0.1`
   - **Port**: `5432`
   - **Database**: `hostly`
   - **Username**: `hostly_user`
   - **Password**: `Diamantine@2`

### Background Port Forwarding (Optional):

To run port forwarding in the background:
```bash
kubectl port-forward service/postgres-service 5432:5432 &
```

To stop it later:
```bash
# Find the process
ps aux | grep port-forward

# Kill it
kill <process-id>
```

---

## Option 2: NodePort Service (Permanent External Access)

This exposes PostgreSQL on a port accessible from outside the cluster.

### Steps:

1. **On your k8s-node server**, apply the NodePort service:
   ```bash
   kubectl apply -f postgres/postgres-service-nodeport.yaml
   ```

2. **Get your node's IP address**:
   ```bash
   kubectl get nodes -o wide
   # Or
   hostname -I
   ```

3. **Get the NodePort** (should be 30432):
   ```bash
   kubectl get svc postgres-service
   ```
   Look for the port in the format `30432:5432/TCP`

4. **In pgAdmin**, connect with:
   - **Host**: `<your-node-ip>` (the IP of your k8s-node)
   - **Port**: `30432` (the NodePort)
   - **Database**: `hostly`
   - **Username**: `hostly_user`
   - **Password**: `Diamantine@2`

### Security Note:
⚠️ **Warning**: NodePort exposes PostgreSQL to the internet. Make sure:
- Your firewall only allows trusted IPs
- Use strong passwords
- Consider using SSL/TLS connections

---

## Option 3: LoadBalancer Service (Cloud Providers)

If you're using a cloud provider (AWS, GCP, Azure), you can use LoadBalancer.

### Steps:

1. **Create a LoadBalancer service** (see `postgres-service-loadbalancer.yaml`)

2. **Apply it**:
   ```bash
   kubectl apply -f postgres/postgres-service-loadbalancer.yaml
   ```

3. **Get the external IP**:
   ```bash
   kubectl get svc postgres-service
   ```
   Wait for `EXTERNAL-IP` to be assigned

4. **In pgAdmin**, connect with:
   - **Host**: `<external-ip>` from the service
   - **Port**: `5432`
   - **Database**: `hostly`
   - **Username**: `hostly_user`
   - **Password**: `Diamantine@2`

---

## Option 4: SSH Tunnel (Secure Alternative)

If you have SSH access to your k8s-node, you can create an SSH tunnel.

### Steps:

1. **On your local machine**, create SSH tunnel:
   ```bash
   ssh -L 5432:localhost:5432 root@<k8s-node-ip>
   ```
   
   Or in a separate terminal:
   ```bash
   ssh -L 5432:postgres-service:5432 root@<k8s-node-ip> -N
   ```

2. **In pgAdmin**, connect with:
   - **Host**: `localhost`
   - **Port**: `5432`
   - **Database**: `hostly`
   - **Username**: `hostly_user`
   - **Password**: `Diamantine@2`

---

## Quick Test Connection

Test the connection from command line:

```bash
# Using port forwarding
kubectl port-forward service/postgres-service 5432:5432 &
psql -h localhost -p 5432 -U hostly_user -d hostly

# Or using NodePort (replace <node-ip> and <nodeport>)
psql -h <node-ip> -p <nodeport> -U hostly_user -d hostly
```

---

## Troubleshooting

### Connection Refused
- Check if PostgreSQL pod is running: `kubectl get pods -l app=postgres`
- Check service exists: `kubectl get svc postgres-service`
- Check port forward is active: `kubectl port-forward` should be running

### Authentication Failed
- Verify credentials in secret: `kubectl get secret postgres-secret -o yaml`
- Check pod logs: `kubectl logs -l app=postgres`

### Can't Connect from Outside
- If using NodePort, check firewall rules
- Verify NodePort is in range 30000-32767
- Check if service is actually NodePort: `kubectl get svc postgres-service`

---

## Recommended Approach

- **Development**: Use **Port Forwarding** (Option 1) - simple and secure
- **Production**: Use **NodePort with firewall rules** (Option 2) or **LoadBalancer** (Option 3)
- **Most Secure**: Use **SSH Tunnel** (Option 4) combined with port forwarding

