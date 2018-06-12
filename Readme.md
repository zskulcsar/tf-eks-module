## Introduction

With the introduction of the AWS EKS service we had high hopes ... then it turned out that we're talking about nothing else but the control plane. How we manage the rest? Not much, other than a [Launching worker nodes](https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html) guide.

The guide is Ok, however it uses cloudformation and not really customiseable. So here this project concieved.

### Usage

You should include the project as a module in your terraform project. It will create a EKS_Cluster and it will initialize EC2 nodes as workers in that cluster.