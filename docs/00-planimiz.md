# 00 — Plan, Kapsam ve Kısıtlar

## Neden EKS Anywhere?

Üç lab arasında en "AWS-oturaklı" seçenek: EKS Distro (EKS ile birebir aynı
binary/imaj) + AWS'in kendi lifecycle yönetimi (create/upgrade/scale/delete CLI).

## Donanım / OS Gerçeği (okuyun!)

| Konu | EKS-A kuralı | Lab etkisi |
|---|---|---|
| Node OS | **Ubuntu 22.04/24.04 veya RHEL 9** (image-builder ile derlenir). *Bottlerocket bare-metal desteği v0.19'de deprecated* | Mevcut OL8.10 VM'ler **doğrudan kullanılamaz**; bu fazda 4 node VM'i PXE ile yeniden imajlanır |
| Boot | KVM'de **PXE zorunlu** (ISO boot, tüm makinelerde BMC/Redfish virtual media ister) | libvirt VM'leri `bootindex=2` (network-first) ayarlanır |
| DHCP | EKS-A kendi DHCP'ini (Tinkerbell/Smee) yürütür; ağdaki **diğer DHCP ile çakışmamalı** | EKS-A fazı için **ayrı bir libvirt ağı** (`eksa`, 192.168.11.0/24, DHCP kapalı) kurulur → tek DHCP kaynağı EKS-A |
| L2 | Tüm makineler (admin dahil) aynı L2'de olmalı (PXE mod) | admin = msi host'u (virbr1 köprüsü ile `eksa` L2'sinde) |
| IP'ler | 2 IP DHCP dışı: **CP endpoint** (kube-vip) + **Tinkerbell IP** | 192.168.11.200 / 192.168.11.201 |
| Donanım asgari | 2 vCPU / 8 GiB / 25 GB — mevcut VM'ler (4/8/40) geçerli |
| BMC | Opsiyonel; **yoksa upgrade desteklenmez** (recreate gerekir) | Lab için kabul edilebilir |

## Makine Planı

| Rol | Makine | Ağı | IP |
|---|---|---|---|
| Admin (CLI + Tinkerbell stack) | msi host (Debian 13) | eksa (virbr1) | 192.168.11.1 |
| Tinkerbell VIP | admin'de sanal IP | eksa | 192.168.11.201 |
| k8s-cp | VM (PXE, 40G boş disk) | eksa | 192.168.11.101 (CSV'de) |
| k8s-w1/w2/w3 | VM (PXE) | eksa | .102/.103/.104 |
| CP endpoint (kube-vip) | CP node üzerinde VIP | eksa | 192.168.11.200 |
| MetalLB pool | — | eksa | 192.168.11.210-214 |

> orion'dan erişim: 192.168.11.0/24 NetBird custom network'e eklenmelidir
> (192.168.10.0/24 ile aynı mekanizma); aksi halde test msi host'undan yapılır.

## Sürümler

- EKS Anywhere CLI: **v0.27.0** (2026-11, aws/eks-anywhere)
- Kubernetes: **v1.36** (EKS-A'nın güncel desteklediği sürüm)
- CNI: **Cilium** (bare-metal'da tek seçenek)
- Node OS: Ubuntu 22.04 (image-builder çıktısı)

## Fazların Sırası (üç lab için)

1. `k8s-lab-vanilla` (OL8 VM'ler) → 2. `k8s-lab-k3s` (aynı OL8 VM'ler)
   → 3. **`k8s-lab-eks-anywhere`** (VM'ler PXE ile yeniden imajlanır)
   → 4. Geri dönüş: VM'ler OL8 şablonuna klonlanarak 1./2. lab'a dönülür.

⚠️ EKS-A fazına başlamadan önce mevcut 4 qcow2 dosyası
`/home/onur/vms/backup-ol8/` dizinine **yedeklenir** (docs/07).
