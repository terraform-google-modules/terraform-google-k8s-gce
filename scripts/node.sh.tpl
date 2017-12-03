#!/bin/bash -xe

kubeadm join --token=${token} --discovery-token-unsafe-skip-ca-verification ${master_ip}:6443