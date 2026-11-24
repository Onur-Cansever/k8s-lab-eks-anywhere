# 06 — Rancher GUI (EKS Anywhere üzerinde)

Rancher, EKS Anywhere kümelerini de yönetebilir (import + dashboard). Kurulum
diğer iki lab'dakiyle aynı mantık: `cattle-system` + helm.

```bash
export KUBECONFIG=$PWD/lab/lab-eks-a-cluster.kubeconfig
kubectl create namespace cattle-system
kubectl create serviceaccount rancher -n cattle-system || true

# LoadBalancer servisi (MetalLB pool: 192.168.11.210-214)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: rancher
  namespace: cattle-system
spec:
  type: LoadBalancer
  selector:
    app: rancher
  ports:
    - {port: 80, targetPort: 80}
    - {port: 443, targetPort: 443}
EOF

helm repo add rancher-stable https://releases.rancher.com/chart
helm repo update
helm upgrade --install rancher rancher-stable/rancher \
  -n cattle-system --set replicas=1 --timeout 20m

kubectl -n cattle-system rollout status deploy/rancher --timeout=600s
kubectl -n cattle-system get svc rancher     # EXTERNAL-IP: 192.168.11.21x
kubectl -n cattle-system get secret bootstrap-password -o jsonpath='{.data.password}' | base64 -d
```

- Erişim: `http://<Rancher-LB-IP>/` (192.168.11.0/24 NetBird'e eklenmişse
  orion'dan da açılır).
- Kaldırma: `helm uninstall rancher -n cattle-system`.

> Not: Rancher ilk boot'ta EKS-A cluster'ını "local cluster" olarak listeler.
> EKS-A'ya özel derin yönetim (eksa CR'ları) için Rancher'ın EKS-A desteği
> sürüme bağlıdır; bu lab'da amaç genel dashboard + workload yönetimidir.
