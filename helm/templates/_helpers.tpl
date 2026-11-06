{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "novu.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.api.image ) "global" .Values.global) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "novu.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return true if cert-manager required annotations for TLS signed certificates are set in the Ingress annotations
Ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
*/}}
{{- define "novu.ingress.certManagerRequest" -}}
{{ if or (hasKey . "cert-manager.io/cluster-issuer") (hasKey . "cert-manager.io/issuer") }}
    {{- true -}}
{{- end -}}
{{- end -}}


{{/*
Compile all warnings into a single message.
*/}}
{{- define "novu.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "novu.validateValues.foo" .) -}}
{{- $messages := append $messages (include "novu.validateValues.bar" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}



{{/*
Return the proper api image name
*/}}
{{- define "novu-api.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.api.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "novu-api.volumePermissions.image" -}}
{{- include "common.images.image" ( dict "imageRoot" "global" .Values.global ) -}}
{{- end -}}


{{/*
Return the proper worker image name
*/}}
{{- define "novu-worker.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.worker.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "novu-worker.volumePermissions.image" -}}
{{- include "common.images.image" ( dict "imageRoot" "global" .Values.global ) -}}
{{- end -}}


{{/*
Return the proper ws image name
*/}}
{{- define "novu-ws.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.ws.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "novu-ws.volumePermissions.image" -}}
{{- include "common.images.image" ( dict "imageRoot" "global" .Values.global ) -}}
{{- end -}}

{{/*
Return the proper web image name
*/}}
{{- define "novu-web.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.web.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "novu-web.volumePermissions.image" -}}
{{- include "common.images.image" ( dict "imageRoot" "global" .Values.global ) -}}
{{- end -}}

{{/*
Return Redis(TM) fullname
*/}}
{{- define "novu.redis.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "redis" "chartValues" .Values.redis "context" $) -}}
{{- end -}}

{{/*
Create a default fully qualified Redis(TM) name.
*/}}
{{- define "novu.redis.host" -}}
{{- if and .Values.redis .Values.redis.enabled -}}
    {{- printf "%s-master" (include "novu.redis.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- print .Values.externalRedis.host -}}
{{- end -}}
{{- end -}}

{{/*
Return Redis(TM) port
*/}}
{{- define "novu.redis.port" -}}
{{- if and .Values.redis .Values.redis.enabled -}}
    {{- print .Values.redis.master.service.ports.redis -}}
{{- else -}}
    {{- print .Values.externalRedis.port  -}}
{{- end -}}
{{- end -}}


{{/*
Return if Redis(TM) authentication is enabled
*/}}
{{- define "novu.redis.auth.enabled" -}}
{{- if and .Values.redis .Values.redis.enabled -}}
    {{- if .Values.redis.auth.enabled -}}
        {{- true -}}
    {{- end -}}
{{- else if or .Values.externalRedis.password .Values.externalRedis.existingSecret -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis(TM) Secret Name
*/}}
{{- define "novu.redis.secretName" -}}
{{- if and .Values.redis .Values.redis.enabled -}}
    {{- print (include "novu.redis.fullname" .) "-password" -}}
{{- else if .Values.externalRedis.existingSecret -}}
    {{- print .Values.externalRedis.existingSecret -}}
{{- else -}}
    {{- printf "%s-externalredis" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Retrieve key of the Redis(TM) secret
*/}}
{{- define "novu.redis.passwordKey" -}}
{{- if and .Values.redis .Values.redis.enabled -}}
    {{- print "redis-password" -}}
{{- else -}}
    {{- if .Values.externalRedis.existingSecret -}}
        {{- if .Values.externalRedis.existingSecretPasswordKey -}}
            {{- printf "%s" .Values.externalRedis.existingSecretPasswordKey -}}
        {{- else -}}
            {{- print "redis-password" -}}
        {{- end -}}
    {{- else -}}
        {{- print "redis-password" -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return MongoDB fullname
*/}}
{{- define "novu.mongodb.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "mongodb" "chartValues" .Values.mongodb "context" $) -}}
{{- end -}}

{{/*
Return mongodb host
*/}}
{{- define "novu.mongodb.host" -}}
{{- if and .Values.mongodb .Values.mongodb.enabled -}}
    {{- include "novu.mongodb.fullname" . -}}
{{- else -}}
    {{- print .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Return mongodb port
*/}}
{{- define "novu.mongodb.port" -}}
{{- if and .Values.mongodb .Values.mongodb.enabled -}}
    {{/* We are using the headless service so we need to use the container port */}}
    {{- print .Values.mongodb.service.ports.mongodb -}}
{{- else -}}
    {{- print .Values.externalDatabase.port -}}
{{- end -}}
{{- end -}}

{{/*
Return mongodb username
*/}}
{{- define "novu.mongodb.username" -}}
{{- if and .Values.mongodb .Values.mongodb.enabled -}}
    {{- print (index .Values.mongodb.auth.usernames 0) -}}
{{- else -}}
    {{- print .Values.externalDatabase.username -}}
{{- end -}}
{{- end -}}

{{/*
Return mongodb password
*/}}
{{- define "novu.mongodb.password" -}}
{{- if and .Values.mongodb .Values.mongodb.enabled -}}
    {{- print (index .Values.mongodb.auth.passwords 0) -}}
{{- else -}}
    {{- print .Values.externalDatabase.password -}}
{{- end -}}
{{- end -}}

{{/*
Return mongodb database
*/}}
{{- define "novu.mongodb.database" -}}
{{- if and .Values.mongodb .Values.mongodb.enabled -}}
    {{- print (index .Values.mongodb.auth.databases 0) -}}
{{- else -}}
    {{- print .Values.externalDatabase.database  -}}
{{- end -}}
{{- end -}}


{{/*
Return mongodb secretName
*/}}
{{- define "novu.mongodb.secretName" -}}
{{- if and (not .Values.externalDatabase.existingSecret) (not (and .Values.mongodb .Values.mongodb.auth.existingSecret)) }}
    {{- printf "%s-url-mongodb" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.externalDatabase.existingSecret -}}
    {{- printf "%s" .Values.externalDatabase.existingSecret -}}
{{- else if and .Values.mongodb .Values.mongodb.auth.existingSecret -}}
    {{- printf "%s" .Values.mongodb.auth.existingSecret -}}
{{- end -}}
{{- end -}}


{{/*
Return s3 fullname
*/}}
{{- define "novu.s3.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "localstack" "chartValues" .Values.localstack "context" $) -}}
{{- end -}}


{{/*
Return s3 bucket name
*/}}
{{- define "novu.s3.bucketName" -}}
{{- if .Values.localstack.enabled -}}
    {{- printf "novu-local" -}}
{{- else -}}
    {{- print .Values.externalS3.bucketName  -}}
{{- end -}}
{{- end -}}

{{/*
Return s3 endpoint
*/}}
{{- define "novu.s3.endpoint" -}}
{{- if .Values.localstack.enabled -}}
    {{-  printf "http://%s:%d" (include "novu.s3.fullname" .)  .Values.localstack.service.edgeService.targetPort -}}
{{- else -}}
    {{- print .Values.externalS3.endpoint  -}}
{{- end -}}
{{- end -}}

{{/*
Return s3 secretKey
*/}}
{{- define "novu.s3.region" -}}
{{- if .Values.localstack.enabled -}}
     {{- printf "us-east-1" -}}
{{- else -}}
    {{- print .Values.externalS3.region  -}}
{{- end -}}
{{- end -}}

{{/*
Return the MongoDB Secret Name
*/}}
{{- define "novu.s3.secretName" -}}
{{- if .Values.localstack.enabled }}
    {{- printf "%s" (include "novu.s3.fullname" .) -}}
{{- else if .Values.externalS3.existingSecret -}}
    {{- printf "%s" .Values.externalS3.existingSecret -}}
{{- else -}}
    {{- printf "%s-externals3" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Local reimplementation of bitnami/common functions so the chart has no external
bitnami dependency.
*/}}

{{- define "common.names.name" -}}
{{- $ctx := . -}}
{{- if hasKey . "context" -}}
{{- $ctx = .context -}}
{{- end -}}
{{- default $ctx.Chart.Name $ctx.Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.names.chart" -}}
{{- $ctx := . -}}
{{- if hasKey . "context" -}}
{{- $ctx = .context -}}
{{- end -}}
{{- printf "%s-%s" $ctx.Chart.Name $ctx.Chart.Version | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.names.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $releaseName := regexReplaceAll "(-?[^a-z\\d\\-])+-?" (lower .Release.Name) "-" -}}
{{- if contains $name $releaseName -}}
{{- $releaseName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $releaseName $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "common.names.dependency.fullname" -}}
{{- if .chartValues.fullnameOverride -}}
{{- .chartValues.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .chartName .chartValues.nameOverride -}}
{{- if contains $name .context.Release.Name -}}
{{- .context.Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .context.Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "common.names.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.labels.value" -}}
{{- regexReplaceAll "[^A-Za-z0-9]+$" (. | toString | replace "+" "_" | trunc 63) "" -}}
{{- end -}}

{{- define "common.labels.standard" -}}
{{- $ctx := . -}}
{{- if hasKey . "context" -}}
{{- $ctx = .context -}}
{{- end -}}
app.kubernetes.io/name: {{ include "common.names.name" $ctx }}
helm.sh/chart: {{ include "common.names.chart" $ctx }}
app.kubernetes.io/instance: {{ $ctx.Release.Name }}
app.kubernetes.io/managed-by: {{ $ctx.Release.Service }}
{{- with $ctx.Chart.AppVersion }}
app.kubernetes.io/version: {{ include "common.labels.value" . | quote }}
{{- end -}}
{{- end -}}

{{- define "common.labels.matchLabels" -}}
{{- $ctx := . -}}
{{- if hasKey . "context" -}}
{{- $ctx = .context -}}
{{- end -}}
app.kubernetes.io/name: {{ include "common.names.name" $ctx }}
app.kubernetes.io/instance: {{ $ctx.Release.Name }}
{{- end -}}

{{- define "common.images.image" -}}
{{- $registryName := default .imageRoot.registry ((.global).imageRegistry) -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | toString -}}
{{- if not .imageRoot.tag }}
  {{- $termination = .Chart.AppVersion | toString -}}
{{- end -}}
{{- if .imageRoot.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .imageRoot.digest | toString -}}
{{- end -}}
{{- if $registryName }}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end -}}

{{- define "common.images.pullSecrets" -}}
  {{- $pullSecrets := list }}
  {{- range ((.global).imagePullSecrets) -}}
    {{- if kindIs "map" . -}}
      {{- $pullSecrets = append $pullSecrets .name -}}
    {{- else -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}
  {{- range .images -}}
    {{- range .pullSecrets -}}
      {{- if kindIs "map" . -}}
        {{- $pullSecrets = append $pullSecrets .name -}}
      {{- else -}}
        {{- $pullSecrets = append $pullSecrets . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if (not (empty $pullSecrets)) -}}
imagePullSecrets:
    {{- range $pullSecrets | uniq }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "common.tplvalues.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
  {{- if .scope }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) }}
  {{- else }}
    {{- tpl $value .context }}
  {{- end }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end -}}

{{- define "common.affinities.topologyKey" -}}
{{ .topologyKey | default "kubernetes.io/hostname" -}}
{{- end -}}

{{- define "common.affinities.nodes.soft" -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - preference:
      matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
    weight: 1
{{- end -}}

{{- define "common.affinities.nodes.hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
{{- end -}}

{{- define "common.affinities.nodes" -}}
  {{- if eq .type "soft" }}
    {{- include "common.affinities.nodes.soft" . -}}
  {{- else if eq .type "hard" }}
    {{- include "common.affinities.nodes.hard" . -}}
  {{- end -}}
{{- end -}}

{{- define "common.affinities.pods.soft" -}}
{{- $component := default "" .component -}}
{{- $customLabels := default (dict) .customLabels -}}
{{- $extraMatchLabels := default (dict) .extraMatchLabels -}}
{{- $extraPodAffinityTerms := default (list) .extraPodAffinityTerms -}}
{{- $extraNamespaces := default (list) .extraNamespaces -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - podAffinityTerm:
      labelSelector:
        matchLabels: {{- (include "common.labels.matchLabels" ( dict "customLabels" $customLabels "context" .context )) | nindent 10 }}
          {{- if not (empty $component) }}
          {{ printf "app.kubernetes.io/component: %s" $component }}
          {{- end }}
          {{- range $key, $value := $extraMatchLabels }}
          {{ $key }}: {{ $value | quote }}
          {{- end }}
      {{- if $extraNamespaces }}
      namespaces:
        - {{ .context.Release.Namespace }}
        {{- with $extraNamespaces }}
        {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
        {{- end }}
      {{- end }}
      topologyKey: {{ include "common.affinities.topologyKey" (dict "topologyKey" .topologyKey) }}
    weight: 1
  {{- range $extraPodAffinityTerms }}
  - podAffinityTerm:
      labelSelector:
        matchLabels: {{- (include "common.labels.matchLabels" ( dict "customLabels" $customLabels "context" $.context )) | nindent 10 }}
          {{- if not (empty $component) }}
          {{ printf "app.kubernetes.io/component: %s" $component }}
          {{- end }}
          {{- range $key, $value := .extraMatchLabels }}
          {{ $key }}: {{ $value | quote }}
          {{- end }}
      {{- if .namespaces }}
      namespaces:
        - {{ $.context.Release.Namespace }}
        {{- with .namespaces }}
        {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
        {{- end }}
      {{- end }}
      topologyKey: {{ include "common.affinities.topologyKey" (dict "topologyKey" .topologyKey) }}
    weight: {{ .weight | default 1 -}}
  {{- end -}}
{{- end -}}

{{- define "common.affinities.pods.hard" -}}
{{- $component := default "" .component -}}
{{- $customLabels := default (dict) .customLabels -}}
{{- $extraMatchLabels := default (dict) .extraMatchLabels -}}
{{- $extraPodAffinityTerms := default (list) .extraPodAffinityTerms -}}
{{- $extraNamespaces := default (list) .extraNamespaces -}}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels: {{- (include "common.labels.matchLabels" ( dict "customLabels" $customLabels "context" .context )) | nindent 8 }}
        {{- if not (empty $component) }}
        {{ printf "app.kubernetes.io/component: %s" $component }}
        {{- end }}
        {{- range $key, $value := $extraMatchLabels }}
        {{ $key }}: {{ $value | quote }}
        {{- end }}
    {{- if $extraNamespaces }}
    namespaces:
      - {{ .context.Release.Namespace }}
      {{- with $extraNamespaces }}
      {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 6 }}
      {{- end }}
    {{- end }}
    topologyKey: {{ include "common.affinities.topologyKey" (dict "topologyKey" .topologyKey) }}
  {{- range $extraPodAffinityTerms }}
  - labelSelector:
      matchLabels: {{- (include "common.labels.matchLabels" ( dict "customLabels" $customLabels "context" $.context )) | nindent 8 }}
        {{- if not (empty $component) }}
        {{ printf "app.kubernetes.io/component: %s" $component }}
        {{- end }}
        {{- range $key, $value := .extraMatchLabels }}
        {{ $key }}: {{ $value | quote }}
        {{- end }}
    {{- if .namespaces }}
    namespaces:
      - {{ $.context.Release.Namespace }}
      {{- with .namespaces }}
      {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 6 }}
      {{- end }}
    {{- end }}
    topologyKey: {{ include "common.affinities.topologyKey" (dict "topologyKey" .topologyKey) }}
  {{- end -}}
{{- end -}}

{{- define "common.affinities.pods" -}}
  {{- if eq .type "soft" }}
    {{- include "common.affinities.pods.soft" . -}}
  {{- else if eq .type "hard" }}
    {{- include "common.affinities.pods.hard" . -}}
  {{- end -}}
{{- end -}}

{{- define "common.capabilities.deployment.apiVersion" -}}
{{- print "apps/v1" -}}
{{- end -}}

{{- define "common.utils.getValueFromKey" -}}
{{- $splitKey := splitList "." .key -}}
{{- $value := "" -}}
{{- $latestObj := $.context.Values -}}
{{- range $splitKey -}}
  {{- if not $latestObj -}}
    {{- printf "please review the entire path of '%s' exists in values" $.key | fail -}}
  {{- end -}}
  {{- $value = ( index $latestObj . ) -}}
  {{- $latestObj = $value -}}
{{- end -}}
{{- printf "%v" (default "" $value) -}} 
{{- end -}}

{{- define "common.utils.getKeyFromList" -}}
{{- $key := first .keys -}}
{{- $reverseKeys := reverse .keys }}
{{- range $reverseKeys }}
  {{- $value := include "common.utils.getValueFromKey" (dict "key" . "context" $.context ) }}
  {{- if $value -}}
    {{- $key = . }}
  {{- end -}}
{{- end -}}
{{- printf "%s" $key -}} 
{{- end -}}

{{- define "common.secrets.passwords.manage" -}}
{{- $password := "" -}}
{{- $providedPasswordKey := include "common.utils.getKeyFromList" (dict "keys" .providedValues "context" $.context) -}}
{{- $providedPasswordValue := include "common.utils.getValueFromKey" (dict "key" $providedPasswordKey "context" $.context) -}}
{{- $secretData := (lookup "v1" "Secret" (include "common.names.namespace" .context) .secret).data -}}
{{- if and $secretData (hasKey $secretData .key) -}}
{{- $password = index $secretData .key | b64dec -}}
{{- else if $providedPasswordValue -}}
{{- $password = tpl ($providedPasswordValue | toString) .context -}}
{{- else -}}
{{- $passwordLength := default 10 .length -}}
{{- $password = randAlphaNum $passwordLength -}}
{{- end -}}
{{- if not .skipB64enc -}}
{{- $password = $password | b64enc -}}
{{- end -}}
{{- printf "%s" $password | quote -}}
{{- end -}}
