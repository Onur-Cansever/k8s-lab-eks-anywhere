#!/bin/bash
# test-nginx.sh — EKS-A: admin makinede (msi) çalıştır
# Ön koşul: cluster ayakta, KUBECONFIG export'lu, MetalLB pool (.210-214) aktif,
#           nginx-deploy.yaml apply edilmiş, 192.168.11.0/24'e erişim var.
set -uo pipefail
K() { kubectl -n nginx-lab "$@"; }

LB=$(K get svc nginx-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$LB" ]; then echo "HATA: LoadBalancer IP yok (MetalLB?)"; exit 1; fi
echo "LB IP: $LB"

probe() { # $1=etiket $2=beklenen_min_pod
  local label="$1" min="$2" ok=0 distinct
  local pods=()
  for i in $(seq 1 50); do
    r=$(curl -s -m 5 -o /dev/null -w '%{http_code}' "http://$LB/")
    [ "$r" = "200" ] && ok=$((ok+1))
    p=$(curl -s -m 5 -D - -o /dev/null "http://$LB/" | awk -F': ' 'tolower($1)=="x-pod"{print $2}' | tr -d '\r')
    [ -n "$p" ] && pods+=("$p")
  done
  distinct=$(printf '%s\n' "${pods[@]}" 2>/dev/null | sort -u | grep -c . || echo 0)
  printf '%-22s 200: %3d/50  farkli pod: %s (%s)\n' "$label" "$ok" "$distinct" "$([ "$distinct" -ge "$min" ] && echo OK || echo KONTROL)"
  sleep 3
}

echo "--- Durum: 3 replika (scale-up)"
K rollout status deploy nginx --timeout=120s >/dev/null
probe "replicas=3 (ilk)" 3

echo "--- Scale DOWN -> 1"
K scale deploy nginx --replicas=1
K rollout status deploy nginx --timeout=120s >/dev/null
probe "replicas=1" 1

echo "--- Scale UP -> 3"
K scale deploy nginx --replicas=3
K rollout status deploy nginx --timeout=120s >/dev/null
probe "replicas=3 (geri)" 3

echo "--- Pod dağılımı (node bazlı):"
K get pods -o wide
echo TEST_DONE
