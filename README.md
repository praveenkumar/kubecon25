$ sudo podman build -t my-k8s-control-plane -f Containerfile .
$ rm -fr output/ && mkdir output
$ sudo podman run --rm -it  --privileged \
       --pull=newer \
       --security-opt \
       label=type:unconfined_t  \
       -v ./config.toml:/config.toml:ro \
       -v ./output:/output  \
       -v /var/lib/containers/storage:/var/lib/containers/storage \
       quay.io/centos-bootc/bootc-image-builder:latest \
       --type qcow2 \
       --use-librepo=True \
       --rootfs btrfs \
       localhost/my-k8s-control-plane:latest
$ sudo virt-install --name fedora-bootc --cpu host  --vcpus 4 --memory 4096 \
    --import --disk ./output/qcow2/disk.qcow2,format=qcow2  \
    --os-variant fedora-eln

$ sudo virsh domifaddr fedora-bootc
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet12     52:54:00:0e:ea:87    ipv4         192.168.124.154/24

$ ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@192.168.124.154
<VM>$ sudo kubeadm init --config /etc/kubernetes/kubeadm-init.yaml
