## Introduction

With the introduction of the AWS EKS service we had high hopes ... then it turned out that we're talking about nothing else but the control plane. How we manage the rest? Not much, other than a [Launching worker nodes](https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html) guide.

The guide is Ok, however it uses cloudformation and not really customiseable. So here this project concieved.

### Usage

You should include the project as a module in your terraform project. It will create a EKS_Cluster and it will initialize EC2 nodes as workers in that cluster. 

At the end of the `terraform apply` command a folder ${var.clsuter_name} is being created with two files:
* kubeconfig.yaml - to be used with kubectl
* workder-aws-auth.yaml - a configmap, for worker node authentication based on IAM instance profile

The authentication config map is deployed onto the cluster as part of the `terraform apply` like `kubectl --kubeconfig=${var.cluster_name}/kubeconfig.yaml apply -f ${var.cluster_name}/worker-aws-auth.yaml` however, this required `heptio-authenticator-aws` to be available and configured on the local computer.

### Issues

* When creating the terraform cluster the subnets and the VPC will be tagged by AWS with tag `kubernetes.io/cluster/${var.cluster_name}` with value `shared`. Whe you run a `terraform apply` for the second time, this tag is removed as it is not defined in this module. Considering that the module handles only the control plane and the worker nodes the above tagging is outside of the scope of this module.

#### TODO

* add kube dashboard as part of deployment
* service mesh deployment?
* monitoring deployment?
* rbac config?