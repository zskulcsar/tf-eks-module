resource "aws_iam_role" "eks_worker" {
  name               = "eks_worker-${var.cluster_name}"
  path               = "/eks/${var.cluster_name}/"
  assume_role_policy = "${data.aws_iam_policy_document.eks_assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks_worker.name}"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks_worker.name}"
}

# Don't think this is needed
# resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = "${aws_iam_role.eks_worker.name}"
# }

resource "aws_iam_instance_profile" "eks_worker" {
  name = "worker_node_instance_profile-${var.cluster_name}"
  role = "${aws_iam_role.eks_worker.name}"
}

# Security Groups
resource "aws_security_group" "worker_node" {
  name        = "worker-${var.cluster_name}"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${data.aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "${data.aws_vpc.default.cidr_block}" ]
  }

  tags = "${
    map(
     "Name", "worker-${var.cluster_name}",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

# TODO: this is required by the applications running on the cluster - ideally this is much more closed
resource "aws_security_group_rule" "worker_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.worker_node.id}"
  source_security_group_id = "${aws_security_group.worker_node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker_ingress_cp" {
  description              = "Allow workers to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.worker_node.id}"
  source_security_group_id = "${aws_security_group.eks_control_plane.id}"
  to_port                  = 65535
  type                     = "ingress"
}

###############################################
# CP <> Worker node security group adjustment
# Please see https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
resource "aws_security_group_rule" "cp_ingress_worker" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_control_plane.id}"
  source_security_group_id = "${aws_security_group.worker_node.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cp_egress_worker" {
  description              = "Allow cluster control plane to communicate with the workers"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_control_plane.id}"
  source_security_group_id = "${aws_security_group.worker_node.id}"
  to_port                  = 65535
  type                     = "egress"
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
#
# TODO: use a template instead than this horrible sed malarchy
# TODO: revise config - maybe we can swap the cluster network range? probably not
#
# DNS_CLUSTER_IP=10.100.0.10
# if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
# are these the IP ranges the cluster can handle?
locals {
  worker_userdata = <<USERDATA
#!/bin/bash -xe

CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
mkdir -p $CA_CERTIFICATE_DIRECTORY
echo "${aws_eks_cluster.default.certificate_authority.0.data}" | base64 -d >  $CA_CERTIFICATE_FILE_PATH
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.default.endpoint},g /var/lib/kubelet/kubeconfig
sed -i s,CLUSTER_NAME,${var.cluster_name},g /var/lib/kubelet/kubeconfig
sed -i s,REGION,${var.aws_region},g /etc/systemd/system/kubelet.service
sed -i s,MAX_PODS,${var.pods_per_node[var.worker_type]},g /etc/systemd/system/kubelet.service
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.default.endpoint},g /etc/systemd/system/kubelet.service
sed -i s,INTERNAL_IP,$INTERNAL_IP,g /etc/systemd/system/kubelet.service
DNS_CLUSTER_IP=10.100.0.10
if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
sed -i s,DNS_CLUSTER_IP,$DNS_CLUSTER_IP,g /etc/systemd/system/kubelet.service
sed -i s,CERTIFICATE_AUTHORITY_FILE,$CA_CERTIFICATE_FILE_PATH,g /var/lib/kubelet/kubeconfig
sed -i s,CLIENT_CA_FILE,$CA_CERTIFICATE_FILE_PATH,g  /etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl restart kubelet kube-proxy
USERDATA
}

resource "aws_launch_configuration" "worker" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks_worker.name}"
  image_id                    = "${var.worker_ami[var.aws_region]}"
  instance_type               = "${var.worker_type}"
  name_prefix                 = "${var.cluster_name}"
  security_groups             = ["${aws_security_group.worker_node.id}"]
  user_data_base64            = "${base64encode(local.worker_userdata)}"
  associate_public_ip_address = false
  key_name                    = "${var.ssh_key}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "worker" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.worker.id}"
  max_size             = "${length(var.cp_subnets) * var.nodes_per_subnet}"
  min_size             = "${length(var.cp_subnets)}"
  name                 = "${var.cluster_name}"
  vpc_zone_identifier  = [ "${var.worker_subnets}" ]

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}