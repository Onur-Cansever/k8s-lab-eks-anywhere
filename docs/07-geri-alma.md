# 07 — Geri Alma: VM'leri OL8 Durumuna Döndürme

EKS-A fazı, 4 node VM'leri **yeniden imajlar** (OL8 → Ubuntu, PXE). Geri
dönüş = domain'leri silip OL8 qcow2'lerinden yeniden başlatmak.

## 7.1 EKS-A Fazına Girmeden Önce (ZORUNLU)

```bash
# msi üzerinde: mevcut 4 OL8 qcow2'sini yedekle
mkdir -p /home/onur/vms/backup-ol8
for d in controller worker1 worker2 worker3; do
  cp -a /home/onur/vms/$d/$d.qcow2 /home/onur/vms/backup-ol8/
done
ls -la /home/onur/vms/backup-ol8/
```

## 7.2 Cluster Kaldırma (EKS-A çalışırken)

```bash
eksctl anywhere delete cluster -f eksa-lab-cluster.yaml \
  --kubeconfig lab/lab-eks-a-cluster.kubeconfig
# Tinkerbell container'ları admin'de durdurulur; VIP'yi kaldırın:
sudo ip addr del 192.168.11.201/24 dev virbr1
```

> `delete cluster` node'ları da silebilir (PXE'ye dönerler); silinemeyen
> VM'lerde disk imajı bozulabilir → 7.3'te yeniden klonlama yapın.

## 7.3 VM'leri OL8'e Geri Getirme

```bash
# msi üzerinde
for d in eksa-cp eksa-w1 eksa-w2 eksa-w3; do
  virsh destroy $d 2>/dev/null; virsh undefine $d 2>/dev/null
done
# backup-ol8'deki qcow2'leri eski konumlarına geri kopyala:
cp -a /home/onur/vms/backup-ol8/controller.qcow2 /home/onur/vms/controller/
cp -a /home/onur/vms/backup-ol8/worker1.qcow2   /home/onur/vms/worker1/
cp -a /home/onur/vms/backup-ol8/worker2.qcow2   /home/onur/vms/worker2/
cp -a /home/onur/vms/backup-ol8/worker3.qcow2   /home/onur/vms/worker3/
# domain XML'leri hazır (k8s-lab-vanilla/provision script'leri üretmişti) → yeniden define + start
for d in controller worker1 worker2 worker3; do
  virsh define /home/onur/vms/$d/$d.xml
  virsh start $d
done
virsh net-destroy eksa 2>/dev/null; virsh net-undefine eksa 2>/dev/null
```

## 7.4 Doğrulama

```bash
for ip in 73 74 75 76; do
  ssh root@192.168.10.$ip 'hostnamectl; systemctl is-active kubelet 2>/dev/null || true'
done
```

Sonrasında `k8s-lab-vanilla` / `k8s-lab-k3s` repolarının "Hızlı Başlangıç"
bölümleriyle istenen lab yeniden kurulur.

## 7.5 Tam Sıfır (opsiyonel)

Yedekler de silinsin: `rm -rf /home/onur/vms/backup-ol8` (yalnızca lab
sonlandırılacaksa).
