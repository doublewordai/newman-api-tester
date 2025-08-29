#!/bin/bash

# Newman API Tester Helm Chart Installation Script

set -e

CHART_NAME="newman-api-tester"
NAMESPACE="${NAMESPACE:-default}"
RELEASE_NAME="${RELEASE_NAME:-api-tests}"
VALUES_FILE="${VALUES_FILE:-}"

echo "╔════════════════════════════════════════════╗"
echo "║     Newman API Tester Installation         ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    echo "   Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    echo "   Visit: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check Kubernetes connectivity
echo "🔍 Checking Kubernetes cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi
echo "✅ Connected to Kubernetes cluster"

# Create namespace if it doesn't exist
if [ "$NAMESPACE" != "default" ]; then
    echo "📦 Creating namespace '$NAMESPACE' if it doesn't exist..."
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
fi

# Install or upgrade the chart
echo ""
echo "📊 Installing Newman API Tester..."
echo "   Release Name: $RELEASE_NAME"
echo "   Namespace: $NAMESPACE"

if [ -n "$VALUES_FILE" ]; then
    echo "   Values File: $VALUES_FILE"
    helm upgrade --install "$RELEASE_NAME" . \
        --namespace "$NAMESPACE" \
        --values "$VALUES_FILE" \
        --create-namespace
else
    echo "   Using default values"
    helm upgrade --install "$RELEASE_NAME" . \
        --namespace "$NAMESPACE" \
        --create-namespace
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Check the CronJob status:"
echo "      kubectl get cronjob -n $NAMESPACE"
echo ""
echo "   2. View the CronJob details:"
echo "      kubectl describe cronjob $RELEASE_NAME-$CHART_NAME -n $NAMESPACE"
echo ""
echo "   3. Manually trigger a test run:"
echo "      kubectl create job --from=cronjob/$RELEASE_NAME-$CHART_NAME manual-test-\$(date +%s) -n $NAMESPACE"
echo ""
echo "   4. View logs from the last job:"
echo "      kubectl logs -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME --tail=100"
echo ""
echo "   5. To uninstall:"
echo "      helm uninstall $RELEASE_NAME -n $NAMESPACE"
echo ""
echo "📚 For more information, see the README.md file"