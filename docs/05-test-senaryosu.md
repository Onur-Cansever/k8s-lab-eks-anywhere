# 05 — Test Senaryosu: nginx + Scale

Diğer iki repodaki senaryonun birebir aynısı (aynı `nginx-deploy.yaml`):

1. nginx Deployment **3 replika** (3 worker'a dağılır).
2. LoadBalancer servisi (MetalLB, 192.168.11.210-214 pool) üzerinden 50 istek
   → **3 farklı pod** (X-Pod header'ı) yanıtlar.
3. **Scale down 1** → 50 istek, %100 200, tek pod.
4. **Scale up 3** → tekrar 3 farklı pod.

## MetalLB (eksa ağı için pool)

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.2/config/manifests/metallb-native.yaml
kubectl apply -f scripts/metallb-eksa.yaml    # pool: 192.168.11.210-214
kubectl apply -f scripts/nginx-deploy.yaml
```

## Test

```bash
export KUBECONFIG=$PWD/lab/lab-eks-a-cluster.kubeconfig
bash scripts/test-nginx.sh    # LB IP'yi svc'ten okur; istekleri msi admin makineden yapar
```

> EKS-A cluster'ının 192.168.11.0/24 ağına orion'dan erişim yoksa (NetBird
> custom network eklenmediyse), test msi host'undan çalıştırılır — script,
> `KUBECONFIG` + curl hedefini o makineye göre ayarlar.

## EKS-A'ya Özel Doğrulama (opsiyonel ama kıymetli)

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'
# → v1.36.x-eks-N (EKS Distro etiketi) — EKS'tekiyle aynı binary sürümünü kanıtlar
```
