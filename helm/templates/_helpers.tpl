{{/*
Expand the name of the chart.
*/}}
{{- define "novu.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "novu.fullname" -}}
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
{{- define "novu.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "novu.labels" -}}
helm.sh/chart: {{ include "novu.chart" . }}
{{ include "novu.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "novu.selectorLabels" -}}
app.kubernetes.io/name: {{ include "novu.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Normalize a URL context path: ensure a single leading slash and no trailing slash.
An empty value stays empty.
*/}}
{{- define "novu.normalizeContextPath" -}}
{{- $path := . | default "" | toString -}}
{{- if $path -}}
{{- if not (hasPrefix "/" $path) -}}
{{- $path = printf "/%s" $path -}}
{{- end -}}
{{- $path = trimSuffix "/" $path -}}
{{- end -}}
{{- $path -}}
{{- end }}

{{/*
Render a context path for a *_CONTEXT_PATH environment variable.

Novu's getContextPath() appends a trailing slash to each configured path and
builds the API route prefix as `/${CONTEXT_PATH}v1`. The API enables URI
versioning with that prefix, which does not normalize a leading slash, so
passing `/api` produces the broken route `//api/v1/...`. Passing `api` (no
leading or trailing slashes) produces the expected `/api/v1/...` route.
*/}}
{{- define "novu.contextPathEnv" -}}
{{- $path := . | default "" | toString -}}
{{- $path = trimPrefix "/" $path -}}
{{- $path = trimSuffix "/" $path -}}
{{- $path -}}
{{- end }}

{{/*
Hostname of the MongoDB service.
*/}}
{{- define "novu.mongodb.host" -}}
{{- if .Values.mongodb.enabled -}}
{{- printf "%s-mongodb" (include "novu.fullname" .) -}}
{{- else -}}
{{- .Values.global.mongodb.host | default "mongodb" -}}
{{- end -}}
{{- end }}

{{/*
Hostname of the Redis service.
*/}}
{{- define "novu.redis.host" -}}
{{- if .Values.redis.enabled -}}
{{- printf "%s-redis" (include "novu.fullname" .) -}}
{{- else -}}
{{- .Values.global.redis.host | default "redis" -}}
{{- end -}}
{{- end }}

{{/*
MongoDB connection string. When no explicit URL is configured it is composed
from the credentials in the MongoDB secret at container runtime.
*/}}
{{- define "novu.mongoUrl" -}}
{{- if .Values.global.mongoUrl -}}
{{- .Values.global.mongoUrl -}}
{{- else -}}
{{- $credentials := "" -}}
{{- if .Values.mongodb.enabled -}}
{{- $credentials = "mongodb://$(MONGO_USERNAME):$(MONGO_PASSWORD)@" -}}
{{- else -}}
{{- $credentials = "mongodb://" -}}
{{- end -}}
{{- printf "%s%s:27017/%s?authSource=admin" $credentials (include "novu.mongodb.host" .) (.Values.global.mongodb.database | default "novu") -}}
{{- end -}}
{{- end }}

{{/*
Internal URL of the API service.
*/}}
{{- define "novu.apiUrl" -}}
{{- $contextPath := include "novu.normalizeContextPath" .Values.global.apiContextPath -}}
{{- printf "http://%s-api.%s.svc.cluster.local:%v%s" (include "novu.fullname" .) .Release.Namespace .Values.global.apiPort $contextPath -}}
{{- end }}

{{/*
Health check paths.
*/}}
{{- define "novu.api.healthPath" -}}
{{- $contextPath := include "novu.normalizeContextPath" .Values.global.apiContextPath -}}
{{- printf "%s/v1/health-check" $contextPath -}}
{{- end }}

{{- define "novu.ws.healthPath" -}}
{{- $contextPath := include "novu.normalizeContextPath" .Values.global.wsContextPath -}}
{{- printf "%s/v1/health-check" $contextPath -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "novu.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "novu.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
