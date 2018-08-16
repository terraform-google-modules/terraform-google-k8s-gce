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

variable region {
  default = "us-west1"
}

variable zone {
  default = "us-west1-b"
}

provider google {
  region = "${var.region}"
}

variable num_nodes {
  default = 3
}

variable cluster_name {
  default = "dev"
}

variable k8s_version {
  default = "1.9.4"
}

resource "google_compute_network" "k8s-dev" {
  name                    = "k8s-dev"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "k8s-dev-us-west1" {
  name          = "k8s-dev-us-west1"
  ip_cidr_range = "10.138.0.0/20"
  network       = "${google_compute_network.k8s-dev.self_link}"
  region        = "us-west1"
}

module "k8s" {
  source           = "../../"
  name             = "${var.cluster_name}"
  network          = "${google_compute_subnetwork.k8s-dev-us-west1.network}"
  subnetwork       = "${google_compute_subnetwork.k8s-dev-us-west1.name}"
  region           = "${var.region}"
  zone             = "${var.zone}"
  k8s_version      = "${var.k8s_version}"
  pod_network_type = "kubenet"
  num_nodes        = "${var.num_nodes}"
}

resource "null_resource" "route_cleanup" {
  // Cleanup the routes after the managed instance groups have been deleted.
  provisioner "local-exec" {
    when    = "destroy"
    command = "gcloud compute routes list --filter='name~k8s-${var.cluster_name}.*' --format='get(name)' | tr '\n' ' ' | xargs -I {} sh -c 'echo Y|gcloud compute routes delete {}' || true"
  }
}
