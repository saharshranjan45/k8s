#!/bin/bash
# kubeadm installation instructions as on
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

# disable swap 
sed -i  '/ swap / s/^/#/' /etc/fstab
swapoff -a

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet

# load br_netfilter module if not loaded
if ! lsmod | grep -i br_netfilter &> /dev/null ;
then
sudo modprobe br_netfilter
cat > /etc/modules-load.d/br_netfilter.conf <<EOF
br_netfilter
EOF
fi


#allow ports in firewall or disable firewall
#below ports are for control node 
if [[ $HOSTNAME = cen8str ]]
then
    firewall-cmd --add-port 6443/tcp --permanent
    firewall-cmd --add-port 2379-2380/tcp --permanent
    firewall-cmd --add-port 10250/tcp --permanent
    firewall-cmd --add-port 10251/tcp --permanent
    firewall-cmd --add-port 10252/tcp --permanent
    firewall-cmd --add-masquerade --permanent
fi

#below is for worker node
if [[ $HOSTNAME = cen8str2 ]]
then
    firewall-cmd --add-port 10250/tcp --permanent
    firewall-cmd --add-port 30000-32767/tcp --permanent
    firewall-cmd --add-masquerade --permanent
fi


systemctl restart firewalld

