# 03 — Node VM Hazırlığı ve hardware.csv

## 3.1 Node OS

EKS-A bare-metal için destekli node OS'leri: **Ubuntu 22.04/24.04** veya
**RHEL 9** (RHEL'de legacy BIOS boot gerekir). Bu lab: **Ubuntu 22.04**.

- İnternet erişimli kurulumlarda Tinkerbell, release bundle'ı üzerinden
  gerekli imajları yönetir; air-gapped ortamda `image-builder` ile
  (aws/eks-anywhere-build-tooling) node imajı önceden derlenir.
  Resmî referans: *OS Management Artifacts* sayfası
  (anywhere.eks.amazonaws.com/docs/osmgmt/artifacts/).
- *Bottlerocket bare-metal desteği v0.19 ile deprecated*'tir — kullanmayın.

## 3.2 VM'lerin Oluşturulması

```bash
# 1) Mevcut OL8 domain'leri kapat + yedekle (docs/07 — ZORUNLU)
# 2) eksa ağını başlat (docs/02)
# 3) PXE VM'leri oluştur:
bash /home/onur/vms/create-eksa-vms.sh     # scripts/ klasöründeki dosyanın kopyası
```

## 3.3 hardware.csv

`scripts/hardware.csv` — Tinkerbell'in makine envanteri. BMC sütunları
KVM'de boş bırakılır (BMC yok; bu yüzden bu lab'da cluster **upgrade
desteklenmez**, recreate gerekir).

```csv
hostname,mac,ip_address,netmask,gateway,nameservers,labels,disk
eksa-cp,52:54:00:aa:bb:51,192.168.11.101,255.255.255.0,192.168.11.1,1.1.1.1,type=cp,/dev/vda
eksa-w1,52:54:00:aa:bb:52,192.168.11.102,255.255.255.0,192.168.11.1,1.1.1.1,type=worker,/dev/vda
eksa-w2,52:54:00:aa:bb:53,192.168.11.103,255.255.255.0,192.168.11.1,1.1.1.1,type=worker,/dev/vda
eksa-w3,52:54:00:aa:bb:54,192.168.11.104,255.255.255.0,192.168.11.1,1.1.1.1,type=worker,/dev/vda
```

Notlar:
- `labels` alanı, cluster.yaml'deki `hardwareSelector` ile eşleşir
  (`type=cp` / `type=worker`).
- CSV'deki `ip_address`, Tinkerbell DHCP'inin o MAC'e vereceği IP'dir.
- Ek makine eklemek (scale) için CSV'ye satır ekleyip `--hardware-csv`
  ile yeniden vermek yeterlidir.

## 3.4 Kontrol

- 4 VM de network-boot edip PXE ekranına gelmeli (virt-manager konsolu).
- Admin'de `tcpdump -i virbr1 port 67 or port 68` ile DHCP trafiği görülmeli.
