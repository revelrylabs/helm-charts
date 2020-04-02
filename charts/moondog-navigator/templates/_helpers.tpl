{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "moondog-navigator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "moondog-navigator.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "moondog-navigator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "moondog-navigator.labels" -}}
app.kubernetes.io/name: {{ include "moondog-navigator.name" . }}
helm.sh/chart: {{ include "moondog-navigator.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "moondog-navigator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "moondog-navigator.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the env secret to use
*/}}
{{- define "moondog-navigator.envSecretName" -}}
{{ include "moondog-navigator.fullname" . }}-env-secret
{{- end -}}

{{/*
Create the name of the env configmap to use
*/}}
{{- define "moondog-navigator.envConfigMapName" -}}
{{ include "moondog-navigator.fullname" . }}-env-config
{{- end -}}

{{/*
Create the name of the image pull secret to use
*/}}
{{- define "moondog-navigator.imagePullSecretName" -}}
{{ include "moondog-navigator.fullname" . }}-pull-secret
{{- end -}}

{{/*
Create the imagePullSecret to use as the docker image is in a private repo
*/}}
{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.imageCredentials.registry (printf "%s:%s" .Values.imageCredentials.username .Values.imageCredentials.password | b64enc) | b64enc }}
{{- end }}
