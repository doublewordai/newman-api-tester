# Newman API Tester Helm Chart

A generic Kubernetes Helm chart for running periodic API tests using Newman (Postman CLI) with support for base64-encoded file uploads and multipart form data.

## Features

- 🕐 **Scheduled Testing**: Run API tests periodically using Kubernetes CronJobs
- 📦 **Multiple Input Sources**: Support for ConfigMaps, URLs, or inline configurations
- 📤 **File Upload Support**: Handle base64-encoded files and multipart/form-data requests
- 🔧 **Highly Configurable**: Extensive configuration options through values.yaml
- 📊 **Multiple Reporters**: Support for CLI, JSON, HTML, JUnit, and other Newman reporters
- 🔐 **Secure**: Built-in security contexts and support for secrets management
- 🎯 **Generic**: Works with any API - just provide your Postman collection

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- A Postman collection (exported as JSON)

## Installation

### Add the Helm repository (if published)
```bash
helm repo add newman-tester https://your-repo-url
helm repo update
```

### Install from local directory
```bash
helm install my-api-tests ./newman-api-tester
```

### Install with custom values
```bash
helm install my-api-tests ./newman-api-tester -f custom-values.yaml
```

## Configuration Examples

### Example 1: Basic API Testing with URL-based Collection

```yaml
# basic-values.yaml
cronjob:
  enabled: true
  schedule: "*/30 * * * *"  # Run every 30 minutes

postman:
  collection:
    url: "https://api.getpostman.com/collections/YOUR_COLLECTION_ID?apikey=YOUR_API_KEY"
  environment:
    url: "https://api.getpostman.com/environments/YOUR_ENV_ID?apikey=YOUR_API_KEY"

newman:
  options:
    iteration-count: "3"
    delay-request: "1000"
```

### Example 2: Testing with Base64-Encoded File Uploads

```yaml
# file-upload-values.yaml
cronjob:
  enabled: true
  schedule: "0 */6 * * *"  # Run every 6 hours

postman:
  collection:
    inline: |
      {
        "info": {
          "name": "File Upload Test",
          "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
        },
        "item": [
          {
            "name": "Upload Image",
            "request": {
              "method": "POST",
              "url": "{{base_url}}/api/upload",
              "body": {
                "mode": "formdata",
                "formdata": [
                  {
                    "key": "file",
                    "type": "file",
                    "src": "test-image.png"
                  },
                  {
                    "key": "description",
                    "value": "Test image upload",
                    "type": "text"
                  }
                ]
              }
            }
          }
        ]
      }
  
  # Upload files that will be available for the tests
  uploadFiles:
    - name: "test-image.png"
      base64Encoded: true
      content: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
    - name: "document.pdf"
      base64Encoded: true
      content: "JVBERi0xLjQKJeLjz9MKNCAwIG9iago8PC9UeXBlL1hPYmplY3Q..."

env:
  base_url: "https://api.example.com"
```

### Example 3: Data-Driven Testing with CSV

```yaml
# data-driven-values.yaml
postman:
  collection:
    configMap: "my-collection"  # Pre-existing ConfigMap
  
  dataFiles:
    - name: "users.csv"
      content: |
        username,password,expected_status
        admin,admin123,200
        user1,pass123,200
        invalid,wrong,401
        locked,locked123,403

newman:
  options:
    iteration-data: "users.csv"
  reporters:
    - cli
    - json
    - junit
```

### Example 4: Complex Testing with Multiple Files

```yaml
# complex-values.yaml
cronjob:
  schedule: "0 2 * * *"  # Run daily at 2 AM

postman:
  collection:
    inline: |
      {{ .Files.Get "collection.json" | indent 6 }}
  
  environment:
    inline: |
      {
        "name": "Production",
        "values": [
          {"key": "api_url", "value": "https://api.prod.example.com"},
          {"key": "api_version", "value": "v2"}
        ]
      }
  
  uploadFiles:
    # Binary file from base64
    - name: "profile.jpg"
      base64Encoded: true
      content: "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAg..."
    
    # Text file
    - name: "config.json"
      content: |
        {
          "setting1": "value1",
          "setting2": "value2"
        }
    
    # File from URL
    - name: "template.docx"
      url: "https://example.com/files/template.docx"

# Use secrets for sensitive data
envFrom:
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: api-secrets
        key: api-key
  - name: CLIENT_SECRET
    valueFrom:
      secretKeyRef:
        name: api-secrets
        key: client-secret

newman:
  options:
    insecure: "true"  # Skip SSL verification
    timeout: "300000"  # 5 minutes timeout
  reporters:
    - cli
    - json
    - html
    - junit

results:
  enabled: true
  upload:
    enabled: true
    endpoint: "https://test-results.example.com/api/upload"
    headers:
      Authorization: "Bearer webhook-token"
      Content-Type: "application/json"
```

## Creating Kubernetes Secrets for Sensitive Data

```bash
# Create secret for API credentials
kubectl create secret generic api-secrets \
  --from-literal=api-key=your-api-key \
  --from-literal=client-secret=your-client-secret

# Create secret with file
kubectl create secret generic test-files \
  --from-file=private-key.pem=/path/to/private-key.pem
```

## Using with Existing ConfigMaps

```bash
# Create ConfigMap from Postman collection
kubectl create configmap my-collection \
  --from-file=collection.json=/path/to/collection.json

# Create ConfigMap from environment
kubectl create configmap my-environment \
  --from-file=environment.json=/path/to/environment.json
```

Then reference in values:
```yaml
postman:
  collection:
    configMap: "my-collection"
    filename: "collection.json"
  environment:
    configMap: "my-environment"
    filename: "environment.json"
```

## Monitoring and Debugging

### View CronJob status
```bash
kubectl get cronjobs
kubectl describe cronjob my-api-tests-newman-api-tester
```

### View job history
```bash
kubectl get jobs --selector=app.kubernetes.io/instance=my-api-tests
```

### View logs from the last job
```bash
# Get the most recent job
JOB=$(kubectl get jobs --selector=app.kubernetes.io/instance=my-api-tests --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')

# View logs
kubectl logs job/$JOB
```

### Debug a failed job
```bash
# Get pod from failed job
POD=$(kubectl get pods --selector=job-name=$JOB -o jsonpath='{.items[0].metadata.name}')

# Describe pod for events
kubectl describe pod $POD

# View logs with previous container (if it crashed)
kubectl logs $POD --previous
```

## Advanced Configuration

### Custom Newman Docker Image

If you need additional tools or reporters, build a custom image:

```dockerfile
FROM postman/newman:alpine
RUN npm install -g newman-reporter-htmlextra newman-reporter-slack
```

Then use in values:
```yaml
image:
  repository: your-registry/custom-newman
  tag: latest
```

### Running One-Time Tests

To run tests immediately without waiting for the schedule:

```bash
# Create a job from the cronjob
kubectl create job --from=cronjob/my-api-tests-newman-api-tester manual-test-$(date +%s)
```

### Parallel Testing

Run multiple test suites in parallel:

```bash
# Install multiple releases with different configurations
helm install suite1-tests ./newman-api-tester -f suite1-values.yaml
helm install suite2-tests ./newman-api-tester -f suite2-values.yaml
helm install suite3-tests ./newman-api-tester -f suite3-values.yaml
```

## Parameters

See [values.yaml](values.yaml) for the full list of configurable parameters.

Key parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cronjob.enabled` | Enable CronJob | `true` |
| `cronjob.schedule` | Cron schedule | `"0 * * * *"` |
| `postman.collection.url` | URL to download collection | `""` |
| `postman.environment.url` | URL to download environment | `""` |
| `postman.uploadFiles` | Files for multipart uploads | `[]` |
| `newman.options` | Newman CLI options | `{}` |
| `newman.reporters` | Newman reporters to use | `["cli", "json"]` |

## Troubleshooting

### Collection Not Found
- Ensure the collection file is in the same directory as specified
- Check ConfigMap is created and mounted correctly
- Verify URLs are accessible from the cluster

### File Upload Fails
- Ensure files are properly base64 encoded
- Check file size limits in ConfigMaps (1MB limit)
- Verify the collection references the correct filename

### CronJob Not Running
- Check the schedule format is valid
- Verify RBAC permissions if using ServiceAccount
- Check resource limits and node capacity

## License

MIT

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.