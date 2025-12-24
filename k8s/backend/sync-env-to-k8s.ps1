# PowerShell script to sync .env file to Kubernetes ConfigMap and Secret
# Usage: .\sync-env-to-k8s.ps1 -EnvFile "..\..\Hostly-web\.env"

param(
    [string]$EnvFile = "..\..\Hostly-web\.env"
)

Write-Host "=== Syncing .env to Kubernetes Config ===" -ForegroundColor Cyan

if (-not (Test-Path $EnvFile)) {
    Write-Host "Error: .env file not found at: $EnvFile" -ForegroundColor Red
    exit 1
}

# Read .env file
$envContent = Get-Content $EnvFile

# Define which vars go to ConfigMap (non-sensitive) vs Secret (sensitive)
$configMapVars = @(
    "APP_NAME", "APP_ENV", "APP_DEBUG", "APP_URL",
    "DB_CONNECTION", "DB_DATABASE", "DB_HOST", "DB_PORT",
    "SESSION_DRIVER", "SESSION_LIFETIME", "CACHE_DRIVER", "QUEUE_CONNECTION",
    "LOG_CHANNEL", "LOG_LEVEL",
    "MAIL_MAILER", "MAIL_HOST", "MAIL_PORT", "MAIL_ENCRYPTION", "MAIL_FROM_ADDRESS", "MAIL_FROM_NAME",
    "FILESYSTEM_DISK", "AWS_DEFAULT_REGION", "REDIS_HOST", "REDIS_PORT",
    "HOSPITABLE_BASE_URL", "HOSPITABLE_CONNECT_BASE_URL", "CHANNEX_BASE_URL", "TTLOCK_BASE_URL",
    "CASHIER_CURRENCY", "CASHIER_CURRENCY_LOCALE", "FRONTEND_URL",
    "PREMIUM_PRODUCT_ID", "PREMIUM_STARTER_PRICE_ID", "PREMIUM_PRO_PRICE_ID", "PREMIUM_BUSINESS_PRICE_ID", "FREE_PRODUCT_ID"
)

$secretVars = @(
    "APP_KEY", "DB_USERNAME", "DB_PASSWORD",
    "MAIL_USERNAME", "MAIL_PASSWORD",
    "HOSPITABLE_API_KEY", "HOSPITABLE_API_SECRET", "HOSPITABLE_TOKEN", "HOSPITABLE_WEBHOOK_SECRET",
    "CHANNEX_API_KEY",
    "GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REDIRECT_URI",
    "TUYA_CLIENT_ID", "TUYA_CLIENT_SECRET",
    "TTLOCK_CLIENT_ID", "TTLOCK_CLIENT_SECRET",
    "STRIPE_KEY", "STRIPE_SECRET", "STRIPE_WEBHOOK_SECRET",
    "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_BUCKET",
    "DATA_ENCRYPTION_KEY", "JWT_SECRET", "RESEND_KEY", "POSTMARK_TOKEN"
)

$configMapData = @{}
$secretData = @{}

foreach ($line in $envContent) {
    # Skip comments and empty lines
    if ($line -match '^\s*#' -or $line -match '^\s*$') {
        continue
    }
    
    # Parse KEY=VALUE
    if ($line -match '^([^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Remove quotes if present
        $value = $value -replace '^["''](.*)["'']$', '$1'
        
        if ($configMapVars -contains $key) {
            $configMapData[$key] = $value
        } elseif ($secretVars -contains $key) {
            $secretData[$key] = $value
        }
    }
}

Write-Host "`nFound $($configMapData.Count) ConfigMap variables" -ForegroundColor Green
Write-Host "Found $($secretData.Count) Secret variables" -ForegroundColor Green

# Generate ConfigMap YAML
$configMapYaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: hostly-web-config
  labels:
    app: hostly-web
data:
"@

foreach ($key in $configMapData.Keys | Sort-Object) {
    $value = $configMapData[$key]
    $configMapYaml += "`n  $key`: `"$value`""
}

# Generate Secret YAML
$secretYaml = @"
apiVersion: v1
kind: Secret
metadata:
  name: hostly-web-secret
  labels:
    app: hostly-web
type: Opaque
stringData:
"@

foreach ($key in $secretData.Keys | Sort-Object) {
    $value = $secretData[$key]
    $secretYaml += "`n  $key`: `"$value`""
}

# Write files
$configMapYaml | Out-File -FilePath "configmap.yaml" -Encoding utf8
$secretYaml | Out-File -FilePath "secret.yaml" -Encoding utf8

Write-Host "`n✅ Generated configmap.yaml and secret.yaml" -ForegroundColor Green
Write-Host "`n⚠️  Review the files before applying to Kubernetes!" -ForegroundColor Yellow
Write-Host "`nTo apply: kubectl apply -f configmap.yaml && kubectl apply -f secret.yaml" -ForegroundColor Cyan

