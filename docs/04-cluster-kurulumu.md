# 04 — Cluster Kurulumu (1 CP + 3 Worker, self-managed)

## 4.1 Cluster Config

`scripts/eksa-lab-cluster.yaml` — resmî akış:

```bash
eksctl anywhere generate clusterconfig lab --provider tinkerbell eksa-lab-cluster.yaml
# → çıktı, bu repodaki eksa-lab-cluster.yaml ile değiştirilir
eksctl anywhere create cluster \
  --hardware-csv hardware.csv \
  -f eksa-lab-cluster.yaml
export KUBECONFIG=$PWD/lab/lab-eks-a-cluster.kubeconfig
```

Anahtar alanlar (detay: bare-spec sayfası):

| Alan | Değer | Açıklama |
|---|---|---|
| `spec.kubernetesVersion` | `1.36` | EKS-A güncel destek |
| `spec.controlPlaneConfiguration.count` | `1` | tek CP (lab) |
| `controlPlaneConfiguration.endpoint.host` | `192.168.11.200` | kube-vip; DHCP dışı |
| `workerNodeGroupConfigurations[0].count` | `3` | 3 worker |
| `clusterNetwork.cniConfig.cilium` | `{}` | bare-metal'da tek CNI |
| `managementCluster.name` | `lab` | self-managed (kendi kendinin yöneticisi) |
| `TinkerbellDatacenterConfig.spec.tinkerbellIP` | `192.168.11.201` | Tinkerbell servis VIP (admin) |
| `TinkerbellMachineConfig.osFamily` | `ubuntu` | node OS (docs/03) |
| `TinkerbellMachineConfig.hardwareSelector` | `type: cp` / `type: worker` | CSV label eşleşmesi |

## 4.2 Kurulum Sırası (CLI tarafında)

1. `create cluster` başlar → admin makinede Tinkerbell bileşenleri başlar.
2. 4 VM PXE boot → DHCP (Smee) → iPXE → HookOS.
3. Tinkerbell: OS imajı `/dev/vda`'ya (Ubuntu 22.04, bundle'dan).
4. VM diske boot → CAPI Machine `Running` → control plane kurulur (etcd + apiserver).
5. Worker'lar katılır → cluster `Ready`.
6. Kubeconfig: `$PWD/lab/lab-eks-a-cluster.kubeconfig`.

## 4.3 Doğrulama

```bash
kubectl get nodes -o wide
kubectl get machines -A          # exsa-system: 4 makine, PHASE=Running
kubectl get pods -A
# cilium, coreDNS, csi? (bare-metal'da varsayılan CSI yok — local-path gerekirse helm)
```

## 4.4 Notlar

- **Upgrade**: BMC olmadığı için rolling upgrade desteklenmez; sürüm yükseltmek
  için cluster recreate edilir (`eksctl anywhere delete cluster` + yeni
  versiyonlu CLI ile `create cluster`). Lab için kabul edilebilir.
- **EKS Distro uyumu**: kurulan bileşenler, AWS EKS'tekilerle aynı dağıtımdır
  (bu, EKS-A'nın ana değeridir).
