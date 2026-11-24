> **Durum (24.11.2026): PARK EDİLDİ** — Canlı kurulum kararı ertelendi (Tinkerbell/PXE alt yapısı ve VM re-imaging maliyeti). Repo, plan + prosedür dokümanı olarak kalır; vanilla ve k3s laboratuvarları bu 4 VM üzerinde test edildi.
# k8s-lab-eks-anywhere — 1 CP + 3 Worker EKS Anywhere (Bare Metal / KVM)

AWS'un **EKS Anywhere** dağıtımıyla (Apache-2.0, ücretsiz), kendi VM'lerimizin
üzerinde 1 control plane + 3 worker node'luk, **AWS servislerinden tamamen
bağımsız** çalışan, EKS ile **birebir aynı EKS Distro** bileşenlerini kullanan
bir test ortamı.

> ⚠️ **Önemli beklenti notu:** EKS Anywhere node OS'leri **Bottlerocket /
> Ubuntu / RHEL 9**'dur; mevcut Oracle Linux 8.10 VM'ler doğrudan kullanılamaz.
> Bu lab için 4 node VM'i (CP+3 worker) bu OS'lerden **PXE boot** ile
> (Tinkerbell provider) kurulur; ayrıca bir **admin host** (CLI makinesi)
> gerekir. Bu repo, o kurulumu **adımlı, script'li ve geri alınabilir**
> biçimde belgeleyip otomatikleştirir.

## Mimari (hedef durum)

| Makine | IP | Rol | OS |
|---|---|---|---|
| admin (mevcut makine) | — | eksctl-anywhere CLI, Tinkerbell hub | Ubuntu/Debian + Docker |
| k8s-cp | 192.168.10.73 | Control plane (kube-vip floating) | Bottlerocket (metal) |
| k8s-w1 | 192.168.10.74 | Worker | Bottlerocket (metal) |
| k8s-w2 | 192.168.10.75 | Worker | Bottlerocket (metal) |
| k8s-w3 | 192.168.10.76 | Worker | Bottlerocket (metal) |

- Cluster: self-managed (`managementCluster.name` = kendi adı), tek cluster.
- CNI: **Cilium** (EKS-A'da bare-metal için tek desteklenen CNI).
- Kubernetes: v1.36 (EKS-A'nın güncel desteklediği sürüm — docs/00).
- LoadBalancer: MetalLB (aynı pool: 192.168.10.80-84) → nginx test senaryosu
  diğer iki repo ile birebir aynı.
- GUI: **Rancher** (EKS-A cluster'larını yönetebilir; docs/04).

## Dokümantasyon

| # | Belge |
|---|---|
| 0 | [docs/00-planimiz.md](docs/00-planimiz.md) — kapsam, neden, maliyet, kısıtlar |
| 1 | [docs/01-admin-hazirligi.md](docs/01-admin-hazirligi.md) — CLI + Tinkerbell stack |
| 2 | [docs/02-pxe-altyapisi.md](docs/02-pxe-altyapisi.md) — libvirt VM'leri PXE'ye çevirme |
| 3 | [docs/03-vm-hazirligi.md](docs/03-vm-hazirligi.md) — 4 node VM + hardware.csv |
| 4 | [docs/04-cluster-kurulumu.md](docs/04-cluster-kurulumu.md) — cluster.yaml (1 CP + 3 worker) |
| 5 | [docs/05-test-senaryosu.md](docs/05-test-senaryosu.md) — nginx scale 3→1 |
| 6 | [docs/06-rancher-gui.md](docs/06-rancher-gui.md) |
| 7 | [docs/07-geri-alma.md](docs/07-geri-alma.md) — **VM'leri OL8 şablonuna geri döndürme** |

## Durum

- [x] Mimari + IP planı (docs/00, 02)
- [x] Admin CLI + Tinkerbell akışı (docs/01)
- [x] PXE altyapısı: `eksa` ağı + 4 node VM script'i (docs/02, scripts/)
- [x] hardware.csv + cluster.yaml (1 CP + 3 worker) (scripts/)
- [x] Test senaryosu + Rancher + geri alma dokümanları
- [ ] **Fiili kurulum** — VM'leri yeniden imajlayacağı için ayrıca onayla çalıştırılacak
  (önce docs/07.1 yedeği). Tahmini süre: 1-2 saat (PXE akışı dahil).

## Lisans

EKS Anywhere: Apache-2.0 (github.com/aws/eks-anywhere). Tinkerbell: Apache-2.0.
Bottlerocket: Apache-2.0. Bu repodaki belgeler: MIT.
