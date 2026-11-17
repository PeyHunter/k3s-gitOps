{{- define "incidental.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "incidental.fullname" -}}
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

{{- define "incidental.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "incidental.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "incidental.selectorLabels" -}}
app.kubernetes.io/name: {{ include "incidental.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "incidental.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- if .Values.image.registry -}}
{{ printf "%s/%s:%s" .Values.image.registry .Values.image.repository $tag }}
{{- else -}}
{{ printf "%s:%s" .Values.image.repository $tag }}
{{- end -}}
{{- end -}}

{{- define "incidental.databaseSecretName" -}}
{{- if .Values.database.cnpg.enabled -}}
{{ include "incidental.fullname" . }}-db-app
{{- else -}}
{{- required "set database.existingSecret (or enable database.cnpg)" .Values.database.existingSecret -}}
{{- end -}}
{{- end -}}
