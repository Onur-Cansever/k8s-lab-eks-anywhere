#!/bin/bash
# create-eksa-vms.sh — msi üzerinde: 4 PXE node VM (boş disk, network-first boot)
# ZORUNLU: önce docs/07.1'deki backup-ol8 yedeği + OL8 domain'lerin kapatılması
set -euo pipefail
BASE=/home/onur/vms
OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_VARS=/usr/share/OVMF/OVMF_VARS_4M.fd
V() { virsh -c qemu:///system "$@"; }

# 0) OL8 domain'leri kapat (disk yedeği docs/07.1 — script onu KONTROL eder)
for d in controller worker1 worker2 worker3; do
  [ -f "$BASE/backup-ol8/$d.qcow2" ] || { echo "HATA: $BASE/backup-ol8/$d.qcow2 yok! Önce 7.1'i yapın."; exit 1; }
  V destroy "$d" 2>/dev/null || true
done

# 1) eksa ağı
V net-define "$BASE/eksa-network.xml" 2>/dev/null || true
V net-start eksa || true
V net-autostart eksa || true

# 2) 4 PXE VM
i=1
for NAME in eksa-cp eksa-w1 eksa-w2 eksa-w3; do
  MAC="52:54:00:aa:bb:5$i"
  DIR="$BASE/$NAME"
  DISK="$DIR/$NAME.qcow2"
  mkdir -p "$DIR"
  if [ ! -f "$DISK" ]; then
    qemu-img create -f qcow2 "$DISK" 40G
  fi
  if V dominfo "$NAME" >/dev/null 2>&1; then V destroy "$NAME" || true; V undefine "$NAME" || true; fi
  cat > "$DIR/$NAME.xml" <<XML
<domain type='kvm'>
  <name>$NAME</name>
  <memory unit='GiB'>8</memory>
  <currentMemory unit='GiB'>8</currentMemory>
  <vcpu placement='static'>4</vcpu>
  <os>
    <loader readonly='yes' type='pflash'>$OVMF_CODE</loader>
    <nvram template='$OVMF_VARS'/>
    <type arch='x86_64' machine='q35'>hvm</type>
    <boot>
      <order dev='network'/>
      <order dev='hd'/>
    </boot>
  </os>
  <features><acpi/><apic/></features>
  <cpu mode='host-model'/>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$DISK'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='network'>
      <source network='eksa'/>
      <mac address='$MAC'/>
      <model type='virtio'/>
    </interface>
    <console type='pty'/>
    <graphics type='spice' autoport='yes'/>
  </devices>
</domain>
XML
  V define "$DIR/$NAME.xml"
  i=$((i+1))
done

# 3) başlat (PXE'ye girecekler)
for NAME in eksa-cp eksa-w1 eksa-w2 eksa-w3; do V start "$NAME"; done
echo EKSA_VMS_READY
echo "Konsollardan PXE/iPXE akışını izleyin: virsh console eksa-cp"
