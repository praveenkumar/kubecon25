# 🐧 Bootc Kubernetes Control Plane VM

This project demonstrates how to build a [bootc](https://coreos.github.io/bootc/) image using a custom container image that includes Kubernetes control plane components, and boot it as a virtual machine using `virt-install`.

## 🔧 Requirements

- Fedora or RHEL-based host
- `podman`
- `bootc-image-builder`
- `virt-install` (`libvirt` + `qemu`)
- SSH key access (used for login into VM)

---

Clone this repository first and then follow the step by step guide.

## 🏗️ 1. Build the Container Image

Create your custom Fedora image with Kubernetes components using the `Containerfile`.

```bash
sudo podman build -t my-k8s-control-plane -f Containerfile .
```

---

## 📁 2. Prepare the Output Directory

Clean and create a directory to store the generated bootc VM image.

```bash
rm -fr output/ && mkdir output
```

---

## 📦 3. Build the Bootc Image (QCOW2)

Use `bootc-image-builder` to generate a QCOW2 virtual disk image.

```bash
sudo podman run --rm -it --privileged \
  --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./config.toml:/config.toml:ro \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 \
  --use-librepo=True \
  --rootfs btrfs \
  localhost/my-k8s-control-plane:latest
```

---

## 💻 4. Launch the VM with `virt-install`

```bash
sudo virt-install --name fedora-bootc \
  --cpu host --vcpus 4 --memory 4096 \
  --import \
  --disk ./output/qcow2/disk.qcow2,format=qcow2 \
  --os-variant fedora-eln
```

---

## 🌐 5. Get the VM's IP Address

```bash
sudo virsh domifaddr fedora-bootc
```

Example output:
```
 Name       MAC address          Protocol     Address
-----------------------------------------------------------
 vnet12     52:54:00:0e:ea:87    ipv4         192.168.124.154/24
```

---

## 🔐 6. SSH into the VM

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@192.168.124.154
```

> Ensure your SSH public key is set in `config.toml` under the `core` user section.

---

## 🚀 7. Initialize the Kubernetes Control Plane

Once inside the VM:

```bash
sudo kubeadm init --config /etc/kubernetes/kubeadm-init.yaml
```

---

## 📝 Files Overview

### `Containerfile`
Builds the image with pre-installed Kubernetes (`kubeadm`, `kubelet`, etc.) and system config files.

### `config.toml`
Used by `bootc-image-builder` to define hostname, users, and SSH access.

Example:
```toml
[identity]
hostname = "fedora-bootc"

[users.core]
ssh-authorized-keys = ["ssh-ed25519 AAAA..."]
```

---

## 📚 Resources

- [bootc documentation](https://coreos.github.io/bootc/)
- [bootc-image-builder](https://github.com/containers/bootc-image-builder)
- [Kubernetes kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
