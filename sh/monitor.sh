#!/bin/bash
# Monitoring script for Triton Inference Server

set -e

ENDPOINT="${ENDPOINT:-http://localhost:8000}"
MODEL_NAME="${MODEL_NAME:-qwen3_8b}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

check_health() {
    log "Checking server health..."
    if curl -s -f "${ENDPOINT}/v2/health/ready" > /dev/null; then
        log "✓ Server is healthy"
        return 0
    else
        log "✗ Server is not healthy"
        return 1
    fi
}

check_model() {
    log "Checking model status..."
    if curl -s -f "${ENDPOINT}/v2/models/${MODEL_NAME}/ready" > /dev/null; then
        log "✓ Model '${MODEL_NAME}' is ready"
        return 0
    else
        log "✗ Model '${MODEL_NAME}' is not ready"
        return 1
    fi
}

get_metrics() {
    log "Fetching metrics..."
    curl -s "${ENDPOINT}:8002/metrics" | grep -E "(nv_inference|nv_gpu|request)" | head -20
}

get_model_info() {
    log "Fetching model information..."
    curl -s "${ENDPOINT}/v2/models/${MODEL_NAME}" | python3 -m json.tool 2>/dev/null || curl -s "${ENDPOINT}/v2/models/${MODEL_NAME}"
}

main() {
    log "=========================================="
    log "Triton Inference Server Monitor"
    log "=========================================="
    log "Endpoint: ${ENDPOINT}"
    log "Model: ${MODEL_NAME}"
    log "=========================================="
    
    if check_health; then
        check_model
        echo ""
        get_model_info
        echo ""
        get_metrics
    else
        log "Server is not accessible. Exiting."
        exit 1
    fi
}

main "$@"

