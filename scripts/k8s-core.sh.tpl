#!/bin/bash -xe

curl --retry 5 -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get install -y \
  docker-ce=${docker_version}* \
  kubelet=${k8s_version}* \
  kubeadm=${k8s_version}* \
  kubectl=${k8s_version}* \
  kubernetes-cni=${cni_version}*

network_plugin=kubenet
if [ "${pod_network_type}" == "calico" ]; then
  network_plugin=cni
fi

# Drop in config for kubenet and cloud provider
cat >/etc/systemd/system/kubelet.service.d/20-gcenet.conf <<EOF
[Service]
Environment="KUBELET_NETWORK_ARGS=--network-plugin=$${network_plugin} --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=${dns_ip} --cluster-domain=cluster.local"
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=gce"
EOF

systemctl daemon-reload

cat <<'EOF' > /etc/kubernetes/gce.conf
[global]
node-tags = ${tags}
node-instance-prefix = ${instance_prefix}
EOF
cp /etc/kubernetes/gce.conf /etc/gce.conf

# for GLBC
touch /var/log/glbc.log