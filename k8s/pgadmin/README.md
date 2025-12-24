# pgAdmin4 Web Deployment

pgAdmin4 deployed as a web application in Kubernetes - access it via your browser!

## Quick Start

1. **Deploy pgAdmin:**
   ```bash
   kubectl apply -f gatewayms/k8s/pgadmin/
   ```

2. **Wait for pod to be ready:**
   ```bash
   kubectl wait --for=condition=ready pod -l app=pgadmin --timeout=120s
   ```

3. **Access pgAdmin in your browser:**
   ```
   http://46.224.158.32:30433
   ```

4. **Login credentials:**
   - **Email**: Set in `secret.yaml` (default: `admin@hostly.com`)
   - **Password**: Set in `secret.yaml` (default: `ChangeMe123!`)
   
   **To change credentials**, edit `gatewayms/k8s/pgadmin/secret.yaml` and reapply:
   ```bash
   kubectl apply -f gatewayms/k8s/pgadmin/secret.yaml
   kubectl rollout restart deployment/pgadmin
   ```

## Adding PostgreSQL Server in pgAdmin

Once logged into pgAdmin, follow these steps:

### Step 1: Create New Server

1. In the left sidebar, right-click on **"Servers"**
2. Select **"Create"** → **"Server..."**

### Step 2: General Tab

Fill in the **General** tab:
- **Name**: `Hostly PostgreSQL` (or any name you prefer)
- **Server group**: `Servers` (default)
- **Comments**: (optional) Add any notes

### Step 3: Connection Tab

Fill in the **Connection** tab with these details:

- **Host name/address**: `postgres-service`
  - ✅ **Use `postgres-service`** - This is the Kubernetes service name
  - Since pgAdmin is running in the same cluster as PostgreSQL, use the service name (works with ClusterIP, NodePort, or LoadBalancer)
  - The service name resolves to the correct IP automatically within the cluster

- **Port**: `5432`
  - Always use port 5432 (the service port, not NodePort if using NodePort)

- **Maintenance database**: `postgres`
  - This is the default database that always exists
  - You can also use `hostly` or `laravel` if you've created them

- **Username**: `hostly_user`

- **Password**: `Diamantine@2`
  - ☑ **Check "Save password"** so you don't have to enter it every time

- **Save password**: ☑ Check this box

**Note**: Since your PostgreSQL service is `ClusterIP` (internal only), pgAdmin in the same cluster can connect using `postgres-service`. If you need external access, you would need to change the service to NodePort or LoadBalancer.

### Step 4: Advanced Tab (Optional)

- **DB restriction**: Leave empty (to see all databases)
- Or specify: `hostly,laravel` to only show specific databases

### Step 5: Save

Click **"Save"** button at the bottom

### Step 6: Verify Connection

After saving, pgAdmin will try to connect. You should see:
- ✅ Green checkmark or "Connected" status
- The server appears in the left sidebar under "Servers"
- You can expand it to see databases, tables, etc.

### Troubleshooting Connection Issues

If connection fails:

1. **Check if PostgreSQL is running:**
   ```bash
   kubectl get pods -l app=postgres
   ```

2. **Test connection from inside cluster:**
   ```bash
   kubectl run test-psql --rm -i --restart=Never --image=postgres:15-alpine -- psql -h postgres-service -U hostly_user -d postgres
   ```

3. **Verify credentials:**
   ```bash
   kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_USER}' | base64 -d
   kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
   ```

4. **Check if database exists:**
   ```bash
   POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
   kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -c "\l"
   ```

### Connection Details Summary

**For pgAdmin running in Kubernetes (same cluster) - CURRENT SETUP:**
- Host: `postgres-service` ✅ (Use this - works with ClusterIP service)
- Port: `5432`
- Database: `postgres`
- Username: `hostly_user`
- Password: `Diamantine@2`

**Note**: Your PostgreSQL service is `ClusterIP` (internal only), which is perfect for pgAdmin running in the same cluster. The service name `postgres-service` will resolve correctly.

**If you need external access** (pgAdmin outside Kubernetes), you would need to:
1. Change PostgreSQL service to NodePort: `kubectl apply -f gatewayms/k8s/postgres/postgres-service-nodeport.yaml`
2. Then use: Host `46.224.158.32`, Port `30432`

## Access from Outside Kubernetes

If you want to access pgAdmin from outside the cluster, the NodePort service exposes it on port `30433`.

**Make sure to open the firewall:**
```bash
sudo ufw allow 30433/tcp
```

## Security Notes

⚠️ **Important**: 
- Change the default password in `secret.yaml` before deploying to production
- Consider restricting access via firewall rules
- Use HTTPS in production (add Ingress with TLS)

## Troubleshooting

```bash
# Check pgAdmin pod status
kubectl get pods -l app=pgadmin

# Check pgAdmin logs
kubectl logs -f deployment/pgadmin

# Check service
kubectl get svc pgadmin-service

# Access pgAdmin shell (if needed)
kubectl exec -it deployment/pgadmin -- /bin/bash
```

