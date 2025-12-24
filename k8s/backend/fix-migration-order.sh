#!/bin/bash
# Fix migration order issue - smartlockdevice needs properties table to exist first

echo "=== Fixing Migration Order ==="
echo ""

POD_NAME=$(kubectl get pods -l app=hostly-backend -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ Error: Backend pod not found"
    exit 1
fi

echo "Backend pod: $POD_NAME"
echo ""

echo "Option 1: Rename migration file (recommended)"
echo "The smartlockdevice migration (2025_01_15) runs before properties (2025_02_11)"
echo "We need to rename it to run after properties table is created"
echo ""
echo "Option 2: Modify migration to add foreign key constraint separately"
echo ""

read -p "Choose option (1 or 2): " OPTION

if [ "$OPTION" = "1" ]; then
    echo ""
    echo "Renaming migration file in the pod..."
    echo "New name should be after 2025_02_11, e.g., 2025_02_11_084947"
    echo ""
    echo "⚠️  This requires rebuilding the Docker image with the renamed migration file"
    echo "Or you can manually rename it in the codebase and rebuild"
    
elif [ "$OPTION" = "2" ]; then
    echo ""
    echo "Modifying migration to create table first, then add foreign key constraint..."
    echo ""
    echo "This requires editing the migration file to:"
    echo "1. Create table without foreign key constraint"
    echo "2. Add foreign key constraint in a separate step after properties table exists"
    echo ""
    echo "⚠️  This also requires rebuilding the Docker image"
fi

echo ""
echo "=== Quick Fix: Skip the problematic migration for now ==="
echo ""
echo "You can temporarily skip this migration and run others:"
echo ""
echo "kubectl exec -it $POD_NAME -- php artisan migrate --path=database/migrations/2025_02_11_084946_create_properties_table.php"
echo ""
echo "Then manually create the foreign key constraint later"

