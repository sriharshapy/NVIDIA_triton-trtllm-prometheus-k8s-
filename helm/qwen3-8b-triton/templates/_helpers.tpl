{{/*
Expand the name of the chart.
*/}}
{{- define "qwen3-8b-triton.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "qwen3-8b-triton.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "qwen3-8b-triton.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "qwen3-8b-triton.labels" -}}
helm.sh/chart: {{ include "qwen3-8b-triton.chart" . }}
{{ include "qwen3-8b-triton.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "qwen3-8b-triton.selectorLabels" -}}
app.kubernetes.io/name: {{ include "qwen3-8b-triton.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Triton labels
*/}}
{{- define "qwen3-8b-triton.triton.labels" -}}
{{ include "qwen3-8b-triton.labels" . }}
app: {{ .Values.global.appName }}
component: triton-server
{{- end }}

{{/*
Triton selector labels
*/}}
{{- define "qwen3-8b-triton.triton.selectorLabels" -}}
app: {{ .Values.global.appName }}
component: triton-server
{{- end }}

{{/*
OpenWebUI labels
*/}}
{{- define "qwen3-8b-triton.openwebui.labels" -}}
{{ include "qwen3-8b-triton.labels" . }}
app: openwebui
component: web-ui
{{- end }}

{{/*
OpenWebUI selector labels
*/}}
{{- define "qwen3-8b-triton.openwebui.selectorLabels" -}}
app: openwebui
component: web-ui
{{- end }}

{{/*
Prometheus labels
*/}}
{{- define "qwen3-8b-triton.prometheus.labels" -}}
{{ include "qwen3-8b-triton.labels" . }}
app: prometheus
component: monitoring
{{- end }}

{{/*
Prometheus selector labels
*/}}
{{- define "qwen3-8b-triton.prometheus.selectorLabels" -}}
app: prometheus
component: monitoring
{{- end }}

{{/*
Namespace
*/}}
{{- define "qwen3-8b-triton.namespace" -}}
{{- .Values.namespace.name | default .Values.global.namespace }}
{{- end }}

