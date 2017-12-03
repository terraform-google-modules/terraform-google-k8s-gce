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
- Node
- RBAC
apiServerCertSANs:
- 127.0.0.1
controllerManagerExtraArgs:
  cluster-name: ${instance_prefix}
  allocate-node-cidrs: "true"
  cidr-allocator-type: "RangeAllocator"
  configure-cloud-routes: "true"
  cloud-config: /etc/kubernetes/pki/gce.conf
  cluster-cidr: ${pod_cidr}
  service-cluster-ip-range: ${service_cidr}
  feature-gates: ${feature_gates}
schedulerExtraArgs:
  feature-gates: ${feature_gates}
apiServerExtraArgs:
  feature-gates: ${feature_gates}
EOF
chmod 0600 /etc/kubernetes/kubeadm.conf

kubeadm init --config /etc/kubernetes/kubeadm.conf

export KUBECONFIG=/etc/kubernetes/admin.conf

if [ "${pod_network_type}" == "calico" ]; then
  manifest_version=
  [[ ${calico_version} =~ ^2.4 ]] && manifest_version=1.6
  [[ ${calico_version} =~ ^2.6 ]] && manifest_version=1.7
  [[ -z $${manifest_version} ]] && echo "ERROR: Unsupported calico version: ${calico_version}" && exit 1
  kubectl apply -f https://docs.projectcalico.org/v${calico_version}/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
  kubectl apply -f https://docs.projectcalico.org/v${calico_version}/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/$${manifest_version}/calico.yaml
fi

# ClusterRoleBiding for persistent volume provisioner.
kubectl create clusterrolebinding system:controller:persistent-volume-provisioner \
  --clusterrole=system:persistent-volume-provisioner \
  --user system:serviceaccount:kube-system:pvc-protection-controller

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
curl -sL https://raw.githubusercontent.com/kubernetes/kubernetes/v${k8s_version}/cluster/saltbase/salt/l7-gcp/glbc.manifest > /tmp/glbc.manifest
kubectl convert -f /tmp/glbc.manifest -o json | jq '.spec.volumes |= . + [{"name": "kubeconfig", "hostPath": {"path": "/etc/kubernetes/admin.conf", "type": "File"}}] | .spec.containers[0].volumeMounts |= . + [{"name": "kubeconfig", "readOnly": true, "mountPath": "/etc/kubernetes/admin.conf"}]' | \
  sed \
    -e 's|--apiserver-host=http://localhost:8080|--apiserver-host=https://127.0.0.1:6443|g' \
    -e 's|--verbose=true|--verbose=true --kubeconfig=/etc/kubernetes/admin.conf|g' \
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
