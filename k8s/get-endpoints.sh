#!/bin/bash
# Get service endpoints after deployment

set -e

NAMESPACE="${NAMESPACE:-triton-inference}"

echo "=========================================="
echo "Service Endpoints"
echo "=========================================="
echo ""

# Get service IPs
echo "LoadBalancer Services:"
kubectl get svc -n "$NAMESPACE" -o wide | grep LoadBalancer || echo "No LoadBalancer services found"
echo ""

# Get specific IPs
TRITON_IP=$(kubectl get service triton-qwen3-8b -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
OPENWEBUI_IP=$(kubectl get service openwebui -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
PROMETHEUS_IP=$(kubectl get service prometheus -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TRITON INFERENCE SERVER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  HTTP:    http://$TRITON_IP:8000"
echo "  gRPC:    $TRITON_IP:8001"
echo "  Metrics: http://$TRITON_IP:8002/metrics"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OPENWEBUI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Web UI:  http://$OPENWEBUI_IP"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROMETHEUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Metrics UI: http://$PROMETHEUS_IP:9090"
echo ""

# Get Ingress IPs if deployed
INGRESS_COUNT=$(kubectl get ingress -n "$NAMESPACE" 2>/dev/null | wc -l || echo "0")
if [ "$INGRESS_COUNT" -gt 1 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "INGRESS ENDPOINTS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  kubectl get ingress -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name,ADDRESS:.status.loadBalancer.ingress[0].ip 2>/dev/null || echo "No ingress found"
  echo ""
fi

echo "=========================================="
echo "To check status:"
echo "  kubectl get svc -n $NAMESPACE"
echo "  kubectl get ingress -n $NAMESPACE"
echo "=========================================="

