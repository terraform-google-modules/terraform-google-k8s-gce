/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable name {
  description = "The name of the kubernetes cluster. Note that nodes names will be prefixed with `k8s-`"
}

variable cluster_uid {
  description = "The cluster uid"
  default     = ""
}

variable k8s_version {
  description = "The version of kubernetes to use. See available versions using: `apt-cache madison kubelet`"
  default     = "1.8.1"
}

variable dashboard_version {
  description = "The version tag of the kubernetes dashboard, per the tags in the repo: https://github.com/kubernetes/dashboard"
  default     = "v1.6.3"
}

variable cni_version {
  description = "The version of the kubernetes cni resources to install. See available versions using: `apt-cache madison kubernetes-cni`"
  default     = "0.5.1"
}

variable docker_version {
  description = "The version of Docker to install. See available versions using: `apt-cache madison docker-ce`"
  default     = "17.09.0"
}

variable calico_version {
  description = "Version of Calico to install for pod networking. Major and minor version only, example: `2.4` or `2.6`."
  default     = "2.6"
}

variable compute_image {
  description = "The project/image to use on the master and nodes. Must be ubuntu or debian 8+ compatible."
  default     = "ubuntu-os-cloud/ubuntu-1704"
}

variable network {
  description = "The network to deploy to"
  default     = "default"
}

variable pod_network_type {
  description = "The type of networking to use for inter-pod traffic. Either kubenet or calico."
  default     = "kubenet"
}

variable subnetwork {
  description = "The subnetwork to deploy to"
  default     = "default"
}

variable region {
  description = "The region to create the cluster in."
  default     = "us-central1"
}

variable zone {
  description = "The zone to create the cluster in."
  default     = "us-central1-f"
}

variable access_config {
  description = "The access config block for the instances. Set to [] to remove external IP."
  type        = "list"
  default     = [{}]
}

variable master_machine_type {
  description = "The machine tyoe for the master node."
  default     = "n1-standard-4"
}

variable node_machine_type {
  description = "The machine type for the nodes."
  default     = "n1-standard-4"
}

variable num_nodes {
  description = "The number of nodes."
  default     = "3"
}

variable add_tags {
  description = "Additional list of tags to add to the nodes."
  type        = "list"
  default     = []
}

variable master_ip {
  description = "The internal IP of the master node. Note this must be in the CIDR range of the region and zone."
  default     = "10.128.0.10"
}

variable pod_cidr {
  description = "The CIDR for the pod network. The master will allocate a portion of this subnet for each node."
  default     = "192.168.0.0/16"
}

variable service_cidr {
  description = "The CIDR for the service network"
  default     = "10.96.0.0/12"
}

variable dns_ip {
  description = "The IP of the kube DNS service, must live within the service_cidr."
  default     = "10.96.0.10"
}

variable depends_id {
  description = "The ID of a resource that the instance group depends on."
  default     = ""
}
