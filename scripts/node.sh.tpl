#!/bin/bash -xe

kubeadm join --token=${token} ${master_ip}:6443