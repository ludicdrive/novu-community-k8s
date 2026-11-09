# Novu Helm Chart

A Helm chart for [Novu](https://novu.co/) - Open-source notification infrastructure.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.x

## Installation

### Step 1: Generate and Create External Secrets (Required)

**Before installing**, create the required secrets externally. The chart will NOT overwrite existing secrets.

```bash
# Navigate to chart directory
cd novu

# Generate secure random secrets
export MONGO_PASSWORD=$(openssl rand -base64 32)
export JWT_SECRET=$(openssl rand -base64 32)
export STORE_ENCRYPTION_KEY=$(openssl rand -base64 32)
export NOVU_SECRET_KEY=$(openssl rand -base64 32)

# Create MongoDB secret (replace <namespace> with your namespace)
kubectl create secret generic novu-mongodb-secret \
  --from-literal=username=novu \
  --from-literal=password=$MONGO_PASSWORD \
  -n <namespace>

# Create application secrets
kubectl create secret generic novu-secrets \
  --from-literal=jwt-secret=$JWT_SECRET \
  --from-literal=store-encryption-key=$STORE_ENCRYPTION_KEY \
  --from-literal=novu-secret-key=$NOVU_SECRET_KEY \
  -n <namespace>

# Optional: AWS credentials (if using S3 storage)
kubectl create secret generic novu-secrets \
  --from-literal=aws-access-key-id=<your-aws-key> \
  --from-literal=aws-secret-access-key=<your-aws-secret> \
  -n <namespace>

# Optional: Sentry DSN (for error tracking)
kubectl create secret generic novu-secrets \
  --from-literal=sentry-dsn=<your-sentry-dsn> \
  -n <namespace>

# Optional: New Relic License Key (for monitoring)
kubectl create secret generic novu-secrets \
  --from-literal=newrelic-license-key=<your-newrelic-key> \
  -n <namespace>
```

### Step 2: Create MongoDB Secret (if not created above)

If you want to manage the MongoDB secret separately:

```bash
kubectl create secret generic novu-mongodb-secret \
  --from-literal=username=novu \
  --from-literal=password=<your-secure-mongo-password> \
  -n <namespace>
```

### Step 3: Install with Default Values

```bash
helm install novu ./novu -n <namespace>
```

### Step 4: Install with Custom Values (Optional)

If you need to customize service configurations:

```bash
helm install novu ./novu \
  -f values.yaml \
  -n <namespace>
```

### Step 5: Verify Installation

```bash
# Check pods status
kubectl get pods -l app.kubernetes.io/name=novu -n <namespace>

# Check services
kubectl get svc -n <namespace>

# If using ingress, check ingress resources
kubectl get ingress -n <namespace>
```

## Configuration

The following tables report the common parameters used in this chart.

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.mongodb.username` | MongoDB admin username (must match pre-created secret) | `novu` |
| `global.redis.host` | Redis host | `redis` |
| `global.redis.port` | Redis port | `6379` |
| `global.apiPort` | API service port | `3000` |
| `global.workerPort` | Worker service port | `3004` |
| `global.wsPort` | WebSocket service port | `3001` |
| `global.disableUserRegistration` | Disable public `/auth/register` (invite-only onboarding) | `false` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `redis.enabled` | Enable Redis service | `true` |
| `mongodb.enabled` | Enable MongoDB service | `true` |
| `api.enabled` | Enable API service | `true` |
| `worker.enabled` | Enable Worker service | `true` |
| `ws.enabled` | Enable WebSocket service | `true` |
| `dashboard.enabled` | Enable Dashboard service | `true` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable Ingress resource | `false` |
| `ingress.host` | Hostname for ingress (e.g., novu.example.com) | `` (empty) |
| `ingress.annotations` | Ingress annotations (Traefik-specific) | `{}` |
| `ingress.tlsSecretName` | TLS secret name for HTTPS | `` (empty) |

The Ingress routes traffic to:
- `/api` → API service (port 3000)
- `/ws` → WebSocket service (port 3001)
- `/` → Dashboard service (port 4000)

`global.apiContextPath` and `global.wsContextPath` must match these paths
(default: `/api` and `/ws`).

### User Registration

There is no built-in "approve signup" flow in self-hosted Novu. Public
registration creates a new user and a new, isolated organization.

To make onboarding invite-only:

1. Create the first admin account via `/auth/sign-up`.
2. Set `global.disableUserRegistration: "true"` and upgrade.
3. Invite users from the dashboard (Settings → Team/Members → Invite).

Invite emails are sent through a Novu workflow and require a configured
`NOVU_API_KEY` plus an email integration. Without those, the invite is still
created: read the token from the `members` collection (`invite.token`) and
share `https://<dashboard-url>/auth/invitation/<token>` manually.

## Usage

### Environment Variables

All sensitive configuration is injected via Kubernetes Secrets. The chart references these secrets in the deployment configurations.

#### Required Secrets (Pre-created externally)

1. **MongoDB Secret** (`novu-mongodb-secret`)
   - `username`: MongoDB admin username (default: `novu`)
   - `password`: MongoDB admin password

2. **Application Secrets** (`novu-secrets`)
   - `jwt-secret`: JWT signing secret (minimum 32 characters)
   - `store-encryption-key`: Encryption key for sensitive data storage (minimum 32 characters)
   - `novu-secret-key`: Novu application secret key (minimum 32 characters)

#### Optional Secrets

- `aws-access-key-id`: AWS Access Key ID (for S3 storage)
- `aws-secret-access-key`: AWS Secret Access Key (for S3 storage)
- `sentry-dsn`: Sentry DSN for error tracking
- `newrelic-license-key`: New Relic license key for monitoring

See the "Create External Secrets First" section above for detailed instructions on generating and creating these secrets.

### Important Security Notes

**NEVER commit secrets to version control!** The chart is designed so that:
1. Secrets are created externally using `kubectl create secret`
2. The chart references existing secrets (never creates them with values.yaml)
3. `pre-secrets.yaml` only creates secrets if they don't already exist
4. On upgrades, the chart will never overwrite pre-created secrets

### Upgrading

To upgrade the release:

```bash
helm upgrade novu ./novu -n <namespace>
```

**Important**: The chart will NOT overwrite pre-created secrets. If you need to change secret values, you must delete and recreate them:

```bash
# Delete existing secrets
kubectl delete secret novu-mongodb-secret -n <namespace>
kubectl delete secret novu-secrets -n <namespace>

# Recreate with new values
kubectl create secret generic novu-mongodb-secret \
  --from-literal=username=novu \
  --from-literal=password=<new-password> \
  -n <namespace>

kubectl create secret generic novu-secrets \
  --from-literal=jwt-secret=<new-jwt-secret> \
  --from-literal=store-encryption-key=<new-encryption-key> \
  --from-literal=novu-secret-key=<new-novu-secret> \
  -n <namespace>

# Upgrade the release
helm upgrade novu ./novu -n <namespace>
```

## Uninstalling

To uninstall/delete the `novu` deployment:

```bash
helm uninstall novu
```

## License

This chart is licensed under the MIT License.
