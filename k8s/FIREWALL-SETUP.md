# Firewall Setup for PostgreSQL NodePort Access

If you can't connect to PostgreSQL from pgAdmin, you may need to open the firewall port.

## Check Current Firewall Status

```bash
# Check if ufw is active
ufw status

# Or check iptables
iptables -L -n | grep 30432
```

## Open Port 30432 (NodePort)

### Option 1: Using UFW (Ubuntu Firewall)

```bash
# Allow NodePort range (30000-32767) or specific port
sudo ufw allow 30432/tcp

# Or allow the entire NodePort range
sudo ufw allow 30000:32767/tcp

# Verify
sudo ufw status
```

### Option 2: Using iptables

```bash
# Allow specific port
sudo iptables -A INPUT -p tcp --dport 30432 -j ACCEPT

# Save rules (Ubuntu/Debian)
sudo netfilter-persistent save
# Or
sudo iptables-save > /etc/iptables/rules.v4
```

### Option 3: Cloud Provider Firewall

If your server is on a cloud provider (AWS, GCP, Azure, DigitalOcean, etc.), you also need to open the port in their firewall/security group:

- **AWS**: Security Groups → Add inbound rule for port 30432
- **GCP**: VPC Firewall Rules → Allow TCP:30432
- **Azure**: Network Security Group → Add inbound rule
- **DigitalOcean**: Firewall → Add inbound rule for port 30432

## Test Connection

After opening the firewall, test from your local machine:

```bash
# Test if port is open (replace with your node IP)
telnet 46.224.158.32 30432

# Or using nc (netcat)
nc -zv 46.224.158.32 30432

# Or using psql from your local machine (if installed)
psql -h 46.224.158.32 -p 30432 -U hostly_user -d hostly
```

## Security Recommendation

For better security, restrict access to specific IPs:

```bash
# Allow only your IP (replace YOUR_IP with your actual IP)
sudo ufw allow from YOUR_IP to any port 30432 proto tcp

# Or using iptables
sudo iptables -A INPUT -p tcp -s YOUR_IP --dport 30432 -j ACCEPT
```

## Verify PostgreSQL is Listening

```bash
# On the k8s-node, check if PostgreSQL is accessible
kubectl exec -it deployment/postgres -- pg_isready -U hostly_user -d hostly

# Check service endpoints
kubectl get endpoints postgres-service
```

