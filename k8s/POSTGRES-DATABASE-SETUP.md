# PostgreSQL Database Setup Guide

Since you're creating databases via migrations, here's how to set up your PostgreSQL instance.

## Current Configuration

- **PostgreSQL User**: `hostly_user`
- **PostgreSQL Password**: `Diamantine@2`
- **Default Database**: `postgres` (always exists)
- **Target Database**: Will be created via migrations

## The Issue

When PostgreSQL detects an existing data directory, it skips initialization. This means:
- The `POSTGRES_DB` environment variable is ignored
- The database specified in `POSTGRES_DB` may not exist
- You need to create databases manually or via migrations

## Solution Options

### Option 1: Connect to Default 'postgres' Database (Recommended)

Your applications can connect to the default `postgres` database initially, then create their own databases via migrations.

**Update your backend ConfigMap** to use `postgres` as the initial database:

```yaml
DB_DATABASE: "postgres"  # Connect to default database first
```

Then in your migrations, create the actual database if needed.

### Option 2: Manually Create Databases

Run the helper script to create databases:

```bash
chmod +x gatewayms/k8s/postgres/create-database.sh
./gatewayms/k8s/postgres/create-database.sh
```

Or manually:

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Create hostly database
kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -c "CREATE DATABASE hostly;"

# Create laravel database (for backend)
kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -c "CREATE DATABASE laravel;"
```

### Option 3: Fresh Start (Clear Data Directory)

If you want PostgreSQL to initialize fresh with the `POSTGRES_DB` database:

⚠️ **WARNING**: This will delete all existing data!

```bash
# Delete the PVC and PV
kubectl delete pvc postgres-pvc
kubectl delete pv postgres-pv

# Delete the deployment
kubectl delete deployment postgres

# Recreate everything (PostgreSQL will initialize fresh)
kubectl apply -f gatewayms/k8s/postgres/
```

## For pgAdmin Connection

When connecting from pgAdmin:

1. **Initial Connection**: Connect to the `postgres` database (always exists)
   - Host: `46.224.158.32`
   - Port: `30432`
   - Database: `postgres`
   - Username: `hostly_user`
   - Password: `Diamantine@2`

2. **After connecting**, you can:
   - Create new databases via SQL: `CREATE DATABASE your_database_name;`
   - Or let your migrations create them

## Health Checks

The health checks now use the `postgres` database (which always exists), so they won't fail even if your application databases don't exist yet.

## Running Migrations

Once your database exists, run migrations:

```bash
# For Laravel backend
kubectl exec -it deployment/hostly-web -- php artisan migrate

# Or if you need to specify the database
kubectl exec -it deployment/hostly-web -- php artisan migrate --database=pgsql
```

## Verify Setup

```bash
# List all databases
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -c "\l"

# Check connection
kubectl exec -it $POD_NAME -- psql -U hostly_user -d postgres -c "SELECT version();"
```

## Recommended Approach

Since you're using migrations:

1. **Keep health checks using `postgres` database** (already fixed)
2. **Connect applications to `postgres` database initially**
3. **Let migrations create and manage your application databases**
4. **Or manually create the database first**, then run migrations

This way, PostgreSQL is ready to accept connections, and your migrations handle database creation.

