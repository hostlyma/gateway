# How to Connect PostgreSQL in pgAdmin

Complete guide for adding your PostgreSQL database to pgAdmin.

## Quick Connection Guide

### Step-by-Step Instructions

1. **Open pgAdmin** in your browser:
   ```
   http://46.224.158.32:30433
   ```

2. **Login** with your credentials (from `secret.yaml`)

3. **Add PostgreSQL Server:**
   - Right-click **"Servers"** in left sidebar
   - Click **"Create"** → **"Server..."**

4. **Fill in the Connection Details:**

   **General Tab:**
   - Name: `Hostly PostgreSQL`

   **Connection Tab:**
   - Host name/address: `postgres-service`
   - Port: `5432`
   - Maintenance database: `postgres`
   - Username: `hostly_user`
   - Password: `Diamantine@2`
   - ☑ Save password

5. **Click "Save"**

## Connection Details

### Current PostgreSQL Credentials

These are from your `postgres-secret.yaml`:

- **Host**: `postgres-service` (internal) or `46.224.158.32:30432` (external)
- **Port**: `5432`
- **Database**: `postgres` (default, always exists)
- **Username**: `hostly_user`
- **Password**: `Diamantine@2`

### Why Use `postgres-service`?

Since pgAdmin is running in the same Kubernetes cluster as PostgreSQL, you should use the **service name** (`postgres-service`) instead of an IP address. This is the recommended way in Kubernetes.

## Available Databases

After connecting, you can:

1. **See existing databases:**
   - Expand "Hostly PostgreSQL" → "Databases"
   - You'll see: `postgres` (always exists)

2. **Create new databases:**
   - Right-click "Databases" → "Create" → "Database..."
   - Name: `hostly`, `laravel`, or any name you need

3. **Run SQL queries:**
   - Right-click on a database → "Query Tool"
   - Write and execute SQL

## Common Tasks

### Create a Database

```sql
CREATE DATABASE hostly;
```

Or via pgAdmin:
- Right-click "Databases" → "Create" → "Database..."
- Name: `hostly`
- Owner: `hostly_user`
- Click "Save"

### List All Databases

```sql
\l
```

### Connect to a Specific Database

In pgAdmin, just expand the database in the left sidebar.

### Run Migrations

After creating your database, you can run Laravel migrations:

```bash
kubectl exec -it deployment/hostly-web -- php artisan migrate
```

## Troubleshooting

### "Server doesn't listen"

**Problem**: Can't connect to PostgreSQL

**Solutions**:
1. Check PostgreSQL is running:
   ```bash
   kubectl get pods -l app=postgres
   ```

2. Verify service exists:
   ```bash
   kubectl get svc postgres-service
   ```

3. Test connection:
   ```bash
   kubectl run test-psql --rm -i --restart=Never --image=postgres:15-alpine -- psql -h postgres-service -U hostly_user -d postgres
   ```

### "Authentication failed"

**Problem**: Wrong username or password

**Solutions**:
1. Verify credentials:
   ```bash
   kubectl get secret postgres-secret -o yaml
   ```

2. Decode password:
   ```bash
   kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
   ```

### "Database does not exist"

**Problem**: Trying to connect to a database that doesn't exist

**Solutions**:
1. Connect to `postgres` database first (always exists)
2. Create your database:
   ```sql
   CREATE DATABASE your_database_name;
   ```

## Visual Guide

```
pgAdmin Interface:
┌─────────────────────────────────┐
│ Servers (right-click here)      │
│   └─ Hostly PostgreSQL          │
│      ├─ Databases               │
│      │  ├─ postgres             │
│      │  ├─ hostly (if created)  │
│      │  └─ laravel (if created) │
│      ├─ Login/Group Roles        │
│      └─ Tablespaces             │
└─────────────────────────────────┘
```

## Next Steps

After connecting:

1. ✅ Create your application databases
2. ✅ Run migrations to set up schema
3. ✅ Start using pgAdmin to manage your databases
4. ✅ Create backups, run queries, manage users, etc.

## Security Reminder

⚠️ **Important**: 
- Change default passwords in production
- Use strong passwords
- Consider restricting access via firewall
- Use SSL/TLS for production connections

