# 02 — PXE Altyapısı (libvirt `eksa` Ağı + 4 Node VM)

## 2.1 Ayrı L2: `eksa` libvirt ağı

EKS-A kendi DHCP'ini (Tinkerbell/Smee) yönetir; aynı L2'deki libvirt dnsmasq
ile çakışmaması için EKS-A node'ları **ayrı bir ağa** konur:

- Ad: `eksa` — 192.168.11.0/24, host IP 192.168.11.1 (msi)
- **DHCP kapalı** (XML'de `<dhcp>` bölümü yok) → ağda tek DHCP = EKS-A
- NAT açık (node'ların internet çıkışı: imaj/manifest indirme)

```bash
# msi üzerinde
sudo virsh net-define /home/onur/vms/eksa-network.xml
sudo virsh net-start eksa
sudo virsh net-autostart eksa
# (XML: scripts/eksa-network.xml)
```

## 2.2 Node VM'leri (PXE, boş disk)

Bu fazda 4 VM **yeniden imajlanır**; mevcut OL8 domain'leri önce
shutdown + yedeklenir (docs/07). Yeni domain'ler:

| Domain | MAC | CSV'deki IP | Disk | Boot |
|---|---|---|---|---|
| eksa-cp | 52:54:00:aa:bb:51 | 192.168.11.101 | 40G boş qcow2 | network-first |
| eksa-w1 | 52:54:00:aa:bb:52 | .102 | 40G boş | network-first |
| eksa-w2 | 52:54:00:aa:bb:53 | .103 | 40G boş | network-first |
| eksa-w3 | 52:54:00:aa:bb:54 | .104 | 40G boş | network-first |

Özellikler: q35 + UEFI (OVMF), 4 vCPU / 8 GiB, virtio disk (`/dev/vda`),
`eksa` ağına bağlanır, **diskten bağımsız network boot**
(UEFI boot sırası: `<boot><order dev='network'/></boot>`).

```bash
# msi üzerinde: scripts/create-eksa-vms.sh
# (4 domain define + start; boş qcow2 üretir)
```

## 2.3 PXE Akışı (EKS-A tarafından otomatik)

1. VM network'den boot eder → DHCPDISCOVER.
2. Tinkerbell/Smee (admin makine) DHCP yanıtlar (CSV'deki IP).
3. iPXE yüklenir → HookOS initrd indirilir → OSIE (kurulum ortamı) ayağa gelir.
4. Tinkerbell, hardware.csv'deki label'larla eşleşen makineye OS imajını
   `/dev/vda`'ya kurar; VM diske boot eder.
5. Node cluster'a katılır (CAPI machine `Running`).

> **KVM notu:** PXE akışı gerçek donanım için tasarlanmıştır; KVM VM'lerinde
> virtio NIC + OVMF ile de çalışır (PXE ROM gerektirmez, iPXE HTTP'den gelir).
> Takılma durumunda: admin'de `tcpdump -i any port 67 or 68` ile DHCP
> paketlerini izleyin (doküman: bare-prereq "Verifying Layer 2 Connectivity").

## 2.4 IP Planı Özet (192.168.11.0/24)

| IP | Kullanan |
|---|---|
| .1 | msi host (virbr1) |
| .100-.199 | EKS-A DHCP havuzu (node'lar buradan; CSV sabitlemesi ile .101-.104) |
| .200 | CP endpoint — kube-vip (CP node) |
| .201 | Tinkerbell VIP — admin (virbr1'e eklenir) |
| .210-.214 | MetalLB pool (LoadBalancer servisleri) |
