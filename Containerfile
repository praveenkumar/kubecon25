FROM quay.io/fedora/fedora-bootc:42 as base

# Optional: label for bootc
LABEL bootc = "true"

# Setup kubernetes repo
RUN cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
EOF

# sysctl param
RUN mkdir -p /etc/modules-load.d && echo br_netfilter > /etc/modules-load.d/br_netfilter.conf
RUN mkdir -p /etc/sysctl.d && \
    tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.ipv4.ip_forward = 1
EOF

# make /opt mutable
RUN rm -fr /opt && ln -sf var/opt /opt && mkdir /var/opt
RUN rm -fr /usr/libexec/cni && mkdir -p /var/usr/libexec/cni && ln -sf /var/usr/libexec/cni /usr/libexec/cni 

# Set default packages for Kubernetes control plane
RUN rpm-ostree install \
        kubelet \
        kubeadm \
        kubectl \
        containerd \
        iproute \
        iptables \
        bash-completion \
        socat \
        ebtables \
        ethtool \
        conntrack-tools \
        cri-tools && \
    rpm-ostree cleanup -m && \
    rm -f /etc/yum.repos.d/kubernetes.repo

# Enable required services
RUN systemctl enable kubelet \
    && systemctl enable containerd

# Bootc required metadata
LABEL bootc.version="0.1"
LABEL bootc.image-description="Kubernetes Control Plane Node Image"

# If you want to pre-load kubeadm config or patches, copy them in:
COPY kubeadm-init.yaml /etc/kubernetes/kubeadm-init.yaml
COPY kube-flannel.yml /etc/kubernetes/kube-flannel.yml
COPY kubeadm-init.service /etc/systemd/system/kubeadm-init.service

# Enable the service
RUN systemctl enable kubeadm-init.service

# OCI-required config
CMD [ "/sbin/init" ]
