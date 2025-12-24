# How to Add KUBE_CONFIG Secret to GitHub

## Step 1: Generate the Secret Value

On your Kubernetes server (where kubectl is configured), run:

### On Linux/Mac:
```bash
cat /etc/kubernetes/admin.conf | base64 -w 0
```

### On Windows (PowerShell):
```powershell
Get-Content C:\path\to\kubeconfig -Raw | [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($_))
```

### Alternative (if you have kubectl config):
```bash
kubectl config view --flatten | base64 -w 0
```

Or if you have kubeconfig in a different location:
```bash
cat ~/.kube/config | base64 -w 0
```

This will output a long base64 string - **copy the entire output**.

## Step 2: Add Secret to GitHub

### For Each Repository:

1. Go to your GitHub repository:
   - `https://github.com/hostlyma/gatewayms`
   - `https://github.com/hostlyma/hostly-web`
   - `https://github.com/hostlyma/hostly-react-front`

2. Click **Settings** (top right, in the repository menu)

3. In the left sidebar, click **Secrets and variables** → **Actions**

4. Click **New repository secret**

5. Fill in:
   - **Name**: `KUBE_CONFIG`
   - **Secret**: Paste the entire base64 string you copied from Step 1

6. Click **Add secret**

## Step 3: Verify

After adding the secret, you should see `KUBE_CONFIG` listed in your secrets.

## Important Notes

- ✅ The secret name must be exactly `KUBE_CONFIG` (case-sensitive)
- ✅ Add it to **all three repositories** (gatewayms, hostly-web, hostly-react-front)
- ✅ The base64 string should be very long (thousands of characters)
- ✅ Never commit the kubeconfig file to your repository
- ✅ The secret is encrypted by GitHub and only accessible in workflows

## Testing

After adding the secret, the next time you push to `main` branch, the workflow will:
1. Read the `KUBE_CONFIG` secret
2. Decode it to create the kubeconfig file
3. Use it to connect to your Kubernetes cluster

## Troubleshooting

### Secret Not Found Error
- Make sure the secret name is exactly `KUBE_CONFIG`
- Verify it was added to the correct repository
- Check that Actions secrets are enabled for the repository

### Connection Still Fails
- Verify the kubeconfig file is valid: `kubectl config view --kubeconfig=/etc/kubernetes/admin.conf`
- Make sure the server IP/URL in kubeconfig is accessible from GitHub Actions runners
- Check if your cluster requires authentication beyond the kubeconfig

### Base64 Encoding Issues
- On Mac/Linux: Use `base64 -w 0` (no line breaks) or `base64 | tr -d '\n'`
- On Windows: Use PowerShell `[Convert]::ToBase64String()` method
- The output should be one continuous string with no spaces or line breaks

---

**Quick Command Summary:**
```bash
# Generate secret value
cat /etc/kubernetes/admin.conf | base64 -w 0

# Then add it as KUBE_CONFIG secret in each GitHub repository
```


