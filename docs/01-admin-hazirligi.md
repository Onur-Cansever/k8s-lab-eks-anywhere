# 01 — Admin Makinesi ve CLI (msi host)

Admin makinesi: **msi noteri** (Debian 13, KVM host). `eksa` libvirt ağına
virbr1 köprüsüyle aynı L2'dedir; Tinkerbell stack'i `create cluster` sırasında
bu makine üzerinde otomatik başlatılır.

## Adımlar

```bash
# msi üzerinde (onur)
# 1) Docker (Tinkerbell bileşenleri için)
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER && newgrp docker

# 2) EKS Anywhere CLI v0.27.0
sudo apt-get install -y libbpf0
curl -sL "https://github.com/aws/eks-anywhere/releases/download/v0.27.0/eksctl-anywhere-linux-amd64" \
  -o /usr/local/bin/eksctl-anywhere
sudo chmod +x /usr/local/bin/eksctl-anywhere
eksctl anywhere version

# 3) `eksa` ağı (DHCP'siz) + virbr1  — docs/02
# 4) Tinkerbell VIP (admin tarafında sanal IP; services bu IP'den erişilir)
sudo ip addr add 192.168.11.201/24 dev virbr1
```

## Çıkış Erişimi (zorunlu endpoint'ler)

Admin + cluster makinelerinden TCP/443:

- `public.ecr.aws`
- `anywhere-assets.eks.amazonaws.com` (binary/manifest/ISO)
- `distro.eks.amazonaws.com` (EKS Distro)
- `d2glxqk2uabbnd.cloudfront.net` (imajlar)
- `d5l0dvt14r5h8.cloudfront.net` (paket imajları)

msi, Wi-Fi üzerinden internete erişebildiği için bu şart sağlılıktır;
yine de kurulumdan önce doğrulanmalıdır:

```bash
for h in public.ecr.aws anywhere-assets.eks.amazonaws.com distro.eks.amazonaws.com; do
  curl -sI -m 5 https://$h >/dev/null && echo "$h OK" || echo "$h FAIL"
done
```

## Tinkerbell Stack

Ayrı bir kurulum adımı **yoktur**: `eksctl anywhere create cluster`
tinkerbell provider'ıyla çalıştırıldığında Tinkerbell bileşenleri
(Smee, Tink-server, Hegel, Rufio) admin makine üzerinde başlatılır.
`tinkerbellIP` (192.168.11.201) bu servislerin sanal IP'sidir ve
admin'deki köprü arayüzüne yukarıdaki `ip addr add` ile bağlanır.

## Doğrulama

```bash
eksctl anywhere version | head -3
docker ps            # create cluster sonrası tink/smee konteynerleri görünür
```
