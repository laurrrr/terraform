#!/bin/bash
# Ruleaza acest script pe Proxmox host INAINTE de terraform apply
# ssh root@192.168.1.100 "bash -s" < setup-proxmox.sh

set -e

echo "=== [1/4] Adaugare vmbr1 (bridge intern) ==="
if ! grep -q "vmbr1" /etc/network/interfaces; then
  cat >> /etc/network/interfaces << 'EOF'

auto vmbr1
iface vmbr1 inet static
    address 10.10.0.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
EOF
  ifreload -a
  echo "vmbr1 creat si activat."
else
  echo "vmbr1 exista deja, skip."
fi

echo "=== [2/4] Descarcare imagine Debian 12 cloud ==="
cd /root
if [ ! -f debian-12-genericcloud-amd64.qcow2 ]; then
  wget -q --show-progress \
    https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
else
  echo "Imaginea exista deja, skip."
fi

echo "=== [3/4] Creare template Debian 12 (ID: 9000) ==="
if ! qm status 9000 &>/dev/null; then
  qm create 9000 \
    --name debian12-template \
    --memory 1024 \
    --cores 1 \
    --net0 virtio,bridge=vmbr0 \
    --ostype l26

  qm importdisk 9000 debian-12-genericcloud-amd64.qcow2 local-lvm

  qm set 9000 \
    --scsihw virtio-scsi-pci \
    --scsi0 local-lvm:vm-9000-disk-0 \
    --ide2 local-lvm:cloudinit \
    --boot c \
    --bootdisk scsi0 \
    --serial0 socket \
    --vga serial0 \
    --agent enabled=1

  qm template 9000
  echo "Template creat."
else
  echo "Template 9000 exista deja, skip."
fi

echo "=== [4/4] Instalare Terraform ==="
if ! command -v terraform &>/dev/null; then
  apt-get update -q
  apt-get install -y -q wget unzip
  TF_VERSION="1.7.5"
  wget -q "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
  unzip -q "terraform_${TF_VERSION}_linux_amd64.zip"
  mv terraform /usr/local/bin/
  rm "terraform_${TF_VERSION}_linux_amd64.zip"
  echo "Terraform $(terraform version -json | grep terraform_version | cut -d'"' -f4) instalat."
else
  echo "Terraform deja instalat: $(terraform version | head -1)"
fi

echo ""
echo "=== GATA. Poti rula acum terraform apply ==="
echo "IP-uri planificate:"
echo "  acs     -> 10.10.0.10"
echo "  api     -> 10.10.0.11"
echo "  db      -> 10.10.0.12"
echo "  grafana -> 10.10.0.13"
