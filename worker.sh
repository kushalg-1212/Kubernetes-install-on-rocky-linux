#!/usr/bin/env bash
echo updating system
sleep 2s
dnf update -y
echo Disable Swap 
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo Set SELINUX Policy
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# Updating Firewall Rules
echo updating firewall rules to allow port 6443 , 2379-2380 ,10250,10251,10252 
sleep 1s
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --reload
modprobe br_netfilter
sh -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"
sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"
# Installing Docker
echo adding docker repo and installing docker 
sleep 2s
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce -y
systemctl start docker
systemctl enable docker
# Add Kube Repo
echo adding kubernetes repository 
sleep 2s
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
# installing KUBE
echo installing Kubernetes and required packages 
sleep 2s
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
# Creating Kube Config Files and starting Master
echo making a kube directory and adding the config files 
sleep 2s
cd /home/
sleep 5s
mkdir kube
sleep 2s
cd kube
sleep 2s
touch kubeadm-config.yaml
sleep 2s
cat << EOF | sudo tee kubeadm-config.yaml
# kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.25.3
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF
sleep 5s
echo removing containerd config files 
sleep 5s
rm /etc/containerd/config.toml
sleep 5s
systemctl restart containerd
sleep 5s
echo starting kubernetes Control Node with created config files 
kubeadm init --config /home/kube/kubeadm-config.yaml
echo waiting for 10 seconds before configuring Kubernetes config Files
sleep 10s
export KUBECONFIG=/etc/kubernetes/admin.conf
echo Successfull
echo waiting 10 seconds before installing Network Policy 
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.3/manifests/calico.yaml
sleep 5s
echo done
