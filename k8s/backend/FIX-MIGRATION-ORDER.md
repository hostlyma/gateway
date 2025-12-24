# Fix Migration Order Issue

## Problem

The migration `2025_01_15_000000_create_smartlockdevice_table` runs before `2025_02_11_084946_create_properties_table`, but it tries to create a foreign key constraint referencing the `properties` table which doesn't exist yet.

## Solution Options

### Option 1: Quick Fix - Run Migrations in Correct Order (Temporary)

Since the migration file is already in the Docker image, you can work around this by:

1. **Skip the problematic migration temporarily:**
   ```bash
   # Mark it as run without actually running it
   kubectl exec -it deployment/hostly-backend -- php artisan migrate:status
   
   # Manually insert migration record (skip smartlockdevice for now)
   kubectl exec -it deployment/hostly-backend -- php artisan tinker
   # Then in tinker:
   DB::table('migrations')->insert([
       'migration' => '2025_01_15_000000_create_smartlockdevice_table',
       'batch' => 1
   ]);
   ```

2. **Run properties migration first:**
   ```bash
   kubectl exec -it deployment/hostly-backend -- php artisan migrate --path=database/migrations/2025_02_11_084946_create_properties_table.php
   ```

3. **Then manually create smartlockdevice table:**
   ```bash
   kubectl exec -it deployment/hostly-backend -- php artisan tinker
   # Then run:
   Schema::create('smartlockdevice', function (Blueprint $table) {
       $table->id();
       $table->string('lock_id')->unique();
       $table->string('lock_alias');
       $table->string('lock_name');
       $table->string('lock_mac')->nullable();
       $table->integer('electric_quantity')->nullable();
       $table->unsignedBigInteger('property_id');
       $table->string('nickname');
       $table->enum('integration', ['begtech', 'tuya']);
       $table->enum('status', ['active', 'inactive', 'not-connected'])->default('active');
       $table->integer('battery')->nullable();
       $table->boolean('has_issue')->default(false);
       $table->unsignedBigInteger('user_id');
       $table->timestamps();
       $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
       $table->index(['user_id', 'integration']);
       $table->index(['property_id']);
   });
   
   // Add property_id foreign key after properties table exists
   Schema::table('smartlockdevice', function (Blueprint $table) {
       $table->foreign('property_id')->references('id')->on('properties')->onDelete('cascade');
   });
   ```

### Option 2: Fix Migration File (Permanent Solution)

I've updated the migration file to:
1. Create the table without the `property_id` foreign key constraint initially
2. Check if `properties` table exists before adding the constraint
3. Add the constraint later if the table exists

**However**, this requires rebuilding the Docker image. The fix is in:
- `Hostly-web/database/migrations/2025_01_15_000000_create_smartlockdevice_table.php`

### Option 3: Create Separate Migration for Foreign Key

Create a new migration that runs after properties table is created:

```bash
# Create new migration
php artisan make:migration add_property_foreign_key_to_smartlockdevice_table
```

Then in that migration:
```php
public function up(): void
{
    if (Schema::hasTable('smartlockdevice') && Schema::hasTable('properties')) {
        Schema::table('smartlockdevice', function (Blueprint $table) {
            // Check if foreign key already exists
            $foreignKeys = DB::select("
                SELECT constraint_name 
                FROM information_schema.table_constraints 
                WHERE table_name = 'smartlockdevice' 
                AND constraint_type = 'FOREIGN KEY'
                AND constraint_name LIKE '%property_id%'
            ");
            
            if (empty($foreignKeys)) {
                $table->foreign('property_id')->references('id')->on('properties')->onDelete('cascade');
            }
        });
    }
}
```

## Recommended Quick Fix (No Rebuild Needed)

Run this in your pod:

```bash
# 1. Create smartlockdevice table without foreign key
kubectl exec -it deployment/hostly-backend -- php artisan tinker << 'EOF'
Schema::create('smartlockdevice', function ($table) {
    $table->id();
    $table->string('lock_id')->unique();
    $table->string('lock_alias');
    $table->string('lock_name');
    $table->string('lock_mac')->nullable();
    $table->integer('electric_quantity')->nullable();
    $table->unsignedBigInteger('property_id');
    $table->string('nickname');
    $table->enum('integration', ['begtech', 'tuya']);
    $table->enum('status', ['active', 'inactive', 'not-connected'])->default('active');
    $table->integer('battery')->nullable();
    $table->boolean('has_issue')->default(false);
    $table->unsignedBigInteger('user_id');
    $table->timestamps();
    $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
    $table->index(['user_id', 'integration']);
    $table->index(['property_id']);
});

// Mark migration as run
DB::table('migrations')->insert([
    'migration' => '2025_01_15_000000_create_smartlockdevice_table',
    'batch' => 1
]);
EOF

# 2. Run remaining migrations (properties will be created)
kubectl exec -it deployment/hostly-backend -- php artisan migrate --force

# 3. Add property_id foreign key constraint
kubectl exec -it deployment/hostly-backend -- php artisan tinker << 'EOF'
Schema::table('smartlockdevice', function ($table) {
    $table->foreign('property_id')->references('id')->on('properties')->onDelete('cascade');
});
EOF
```

## After Fix

Once migrations complete successfully, you can continue with normal operations.

