# Kubernetes Cluster on GCE Example

This example creates a Kunbernetes cluster on Compute Engine.

**Figure 1.** *diagram of Google Cloud resources*

![architecture diagram](./diagram.png)

## Set up the environment

```
gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

## Run Terraform

```
terraform init
terraform plan
terraform apply
```

SSH into master through the nat gateway

```
ZONE=us-west1-b
gcloud compute ssh --zone ${ZONE} $(gcloud compute instances list --filter='name~k8s-.*master.*' --format='get(name)')
```

Wait for kubeadm to complete:

```
until [[ -f /etc/kubernetes/admin.conf ]]; do echo "waiting for k8s install to complete..."; sleep 2; done
```

Configure kubectl:

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Wait for all nodes to join and become Ready:

```
kubectl get nodes -o wide
```