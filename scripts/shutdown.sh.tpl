#!/bin/bash
# Shutdown script to remove node from the cluster.

node=$(hostname)
cfg="--kubeconfig /etc/kubernetes/kubelet.conf"

# Drain and delete the node.
kubectl $cfg drain $node --delete-local-data --force --ignore-daemonsets
kubectl $cfg delete node $node

kubeadm reset