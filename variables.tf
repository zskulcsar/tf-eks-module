#
variable "aws_region" {
  description = "The region where to create the VPC"
  # US East (N. Virginia) us-east-1
  # US West (Oregon)      us-west-2
}

# Variables where no default can be provided
variable "cluster_name" {
  description = "The name of the cluster. Please use alphanum '-' 
                 and '_' only as this is used as part of the name for many resources"
}

variable "vpc_id" {
  description = "The id of the VPC where the cluster should be created."
}

variable "cp_subnets" {
  type = "list"
  description = "The subnets where the control plane should live. At least 2 separate subnets. 
                 Ideally control_plane goes to a public subnet."
}

variable "worker_subnets" {
  type = "list"
  description = "The subnets where the worker nodes should live. No restrictions on the number of subnets. 
                 Ideally the worker nodes are living in a private subnet."
}

variable "ssh_key" {
  description = "The ssh key used to login to the worker nodes. Normally you don't need this, but you'll never know."
}

variable "sg_bastion" {
 description = "The security group for the bastion instance. It is assumed that the worker nodes
                can't be accessed via ssh other than using the bastion."
}

# Variables with sensible defaults
variable "kube_version" {
  description = "The kubernetes version to be used."
  default = "1.10"
}

variable "nodes_per_subnet" {
  description = "The number of nodes per subnet"
  default = "2"
}

variable "worker_type" {
  default = "t2.large"
}

variable "pods_per_node" {
  type = "map"
  description = "The number of pods a worker node can have as a maximum. Defined by AWS"

  default = {
    c4.large    = 29
    c4.xlarge   = 58
    c4.2xlarge  = 58
    c4.4xlarge  = 234
    c4.8xlarge  = 234
    c5.large    = 29
    c5.xlarge   = 58
    c5.2xlarge  = 58
    c5.4xlarge  = 234
    c5.9xlarge  = 234
    c5.18xlarge = 737
    i3.large    = 29
    i3.xlarge   = 58
    i3.2xlarge  = 58
    i3.4xlarge  = 234
    i3.8xlarge  = 234
    i3.16xlarge = 737
    m3.medium   = 12
    m3.large    = 29
    m3.xlarge   = 58
    m3.2xlarge  = 118
    m4.large    = 20
    m4.xlarge   = 58
    m4.2xlarge  = 58
    m4.4xlarge  = 234
    m4.10xlarge = 234
    m5.large    = 29
    m5.xlarge   = 58
    m5.2xlarge  = 58
    m5.4xlarge  = 234
    m5.12xlarge = 234
    m5.24xlarge = 737
    p2.xlarge   = 58
    p2.8xlarge  = 234
    p2.16xlarge = 234
    p3.2xlarge  = 58
    p3.8xlarge  = 234
    p3.16xlarge = 234
    r3.xlarge   = 58
    r3.2xlarge  = 58
    r3.4xlarge  = 234
    r3.8xlarge  = 234
    r4.large    = 29
    r4.xlarge   = 58
    r4.2xlarge  = 58
    r4.4xlarge  = 234
    r4.8xlarge  = 234
    r4.16xlarge = 737
    t2.small    = 8
    t2.medium   = 17
    t2.large    = 35
    t2.xlarge   = 44
    t2.2xlarge  = 44
    x1.16xlarge = 234
    x1.32xlarge = 234
  }
}

variable "os_name" {
  default = "amazon"
  description = "The name of the OS, currently only 'amazon' is supported."
}

variable "worker_ami" {
  type = "map"

  default = {
    # AMZN
    us-west-2.amazon = "ami-73a6e20b"
    us-east-1.amazon = "ami-dea4d5a1"
    # Canonical
    # us-west-2.ubuntu = "ami-7183c009"
    # us-east-1.ubuntu = "ami-75692f0a"
  }
}