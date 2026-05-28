{{- define "cozystack.platform.package" -}}
{{- $name := index . 0 -}}
{{- $variant := default "default" (index . 1) -}}
{{- $root := default $ (index . 2) -}}
{{- $components := dict -}}
{{- if gt (len .) 3 -}}
{{- $components = index . 3 -}}
{{- end -}}
{{- $disabled := default (list) $root.Values.bundles.disabledPackages -}}
{{- if not (has $name $disabled) -}}
---
apiVersion: cozystack.io/v1alpha1
kind: Package
metadata:
  name: {{ $name }}
  annotations:
    helm.sh/resource-policy: keep
spec:
  variant: {{ $variant }}
{{- if $components }}
  components:
{{ toYaml $components | indent 4 }}
{{- end }}
{{- end }}
{{ end }}

{{- define "cozystack.platform.package.default" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- include "cozystack.platform.package" (list $name "default" $root) }}
{{ end }}

{{- define "cozystack.platform.package.optional" -}}
{{- $name := index . 0 -}}
{{- $variant := default "default" (index . 1) -}}
{{- $root := default $ (index . 2) -}}
{{- $disabled := default (list) $root.Values.bundles.disabledPackages -}}
{{- $enabled := default (list) $root.Values.bundles.enabledPackages -}}
{{- if and (has $name $enabled) (not (has $name $disabled)) -}}
---
apiVersion: cozystack.io/v1alpha1
kind: Package
metadata:
  name: {{ $name }}
  annotations:
    helm.sh/resource-policy: keep
spec:
  variant: {{ $variant }}
{{- end }}
{{ end }}

{{- define "cozystack.platform.package.optional.default" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- include "cozystack.platform.package.optional" (list $name "default" $root) }}
{{ end }}

{{/*
Common system packages shared between isp-full and isp-full-generic bundles.
Does NOT include: networking (variant differs), linstor (talos.enabled differs)
*/}}
{{- define "cozystack.platform.system.common-packages" -}}
{{- $root := . -}}
{{- /* turing-pi2 brings its own networking (noop = BYO Cilium with LB-IPAM + BGP).
       Exclude EVERYTHING that touches the CNI/LB layer so the install cannot perturb
       the existing Cilium: kube-ovn helpers (orphan admission webhook), Multus (a
       meta-CNI that can rewrite the node CNI config dir), and MetalLB (fights Cilium's
       LoadBalancer over type:LoadBalancer services). With these out, turing-pi2
       installs zero networking-layer components; Cilium is wholly outside the blast
       radius. Real kube-ovn variants (isp-full / isp-full-generic) keep all of them. */ -}}
{{- if ne $root.Values.bundles.system.variant "turing-pi2" }}
{{include "cozystack.platform.package.default" (list "cozystack.kubeovn-webhook" $root) }}
{{include "cozystack.platform.package.default" (list "cozystack.kubeovn-plunger" $root) }}
{{include "cozystack.platform.package.default" (list "cozystack.multus" $root) }}
{{include "cozystack.platform.package.default" (list "cozystack.metallb" $root) }}
{{- end }}
{{include "cozystack.platform.package.default" (list "cozystack.cozy-proxy" $root) }}
{{include "cozystack.platform.package.default" (list "cozystack.reloader" $root) }}
{{include "cozystack.platform.package.default" (list "cozystack.linstor-scheduler" $root) }}
{{include "cozystack.platform.package.default" (list "cozystack.snapshot-controller" $root) }}
{{- end }}
