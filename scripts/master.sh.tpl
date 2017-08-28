#!/bin/bash -xe

cat <<EOF > /etc/kubernetes/kubeadm.conf
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: v${k8s_version}
cloudProvider: gce
token: ${token}
networking:
  serviceSubnet: ${service_cidr}
  podSubnet: ${pod_cidr}
authorizationModes:
- RBAC
apiServerCertSANs:
- 127.0.0.1
controllerManagerExtraArgs:
  cluster-name: ${instance_prefix}
  allocate-node-cidrs: "true"
  cidr-allocator-type: "RangeAllocator"
  configure-cloud-routes: "true"
  cloud-config: /etc/kubernetes/gce.conf
  cluster-cidr: ${pod_cidr}
  service-cluster-ip-range: ${service_cidr}
  feature-gates: AllAlpha=true,RotateKubeletServerCertificate=false,RotateKubeletClientCertificate=false,ExperimentalCriticalPodAnnotation=true
EOF
chmod 0600 /etc/kubernetes/kubeadm.conf

kubeadm init --config /etc/kubernetes/kubeadm.conf

export KUBECONFIG=/etc/kubernetes/admin.conf

if [ "${pod_network_type}" == "calico" ]; then
  kubectl apply -f https://docs.projectcalico.org/v${calico_version}/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
  kubectl apply -f https://docs.projectcalico.org/v${calico_version}/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.6/calico.yaml
fi

# kubeadm manages the manifests directory, so add configmap after the init returns.
kubectl create -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-uid
  namespace: kube-system
data:
  provider-uid: ${cluster_uid}
  uid: ${cluster_uid}
EOF

# Install L7 GLBC controller, path glbc.manifest to support kubeadm cluster.
curl -sL https://raw.githubusercontent.com/kubernetes/kubernetes/v${k8s_version}/cluster/saltbase/salt/l7-gcp/glbc.manifest | \
  sed \
    -e 's|--apiserver-host=http://localhost:8080|--apiserver-host=https://127.0.0.1:6443|g' \
    -e 's|--config-file-path=/etc/gce.conf|--config-file-path=/etc/kubernetes/gce.conf|g' \
    -e 's|: /etc/gce.conf|: /etc/kubernetes|g' \
    > /etc/kubernetes/manifests/glbc.manifest
chmod 0600 /etc/kubernetes/manifests/glbc.manifest

# Install default http-backend controller
curl -sL https://raw.githubusercontent.com/kubernetes/kubernetes/v${k8s_version}/cluster/addons/cluster-loadbalancing/glbc/default-svc-controller.yaml | \
  kubectl create -n kube-system -f -

# Install default http-backend service
curl -sL https://raw.githubusercontent.com/kubernetes/kubernetes/v${k8s_version}/cluster/addons/cluster-loadbalancing/glbc/default-svc.yaml | \
  kubectl create -n kube-system -f -

# Install dashboard addon
curl -sL https://raw.githubusercontent.com/kubernetes/dashboard/${dashboard_version}/src/deploy/kubernetes-dashboard.yaml |
  kubectl create -n kube-system -f -
