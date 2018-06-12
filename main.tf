# 
data "aws_vpc" "default" {
  id = "${var.vpc_id}"
}

# First we create the cluster ...
resource "aws_eks_cluster" "default" {
  name     = "${var.cluster_name}"
  role_arn = "${aws_iam_role.eks_control_plane_role.arn}"
  version  = "${var.kube_version}"

  vpc_config {
    subnet_ids  = [ "${var.cp_subnets}" ]
    security_group_ids = [ "${aws_security_group.eks_control_plane.id}" ]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks_cluster",
    "aws_iam_role_policy_attachment.eks_service",
  ]
}


# IAM for EKS
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_control_plane_role" {
  name               = "eks_service_role-${var.cluster_name}"
  path               = "/eks/${var.cluster_name}/"
  assume_role_policy = "${data.aws_iam_policy_document.eks_assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
    role       = "${aws_iam_role.eks_control_plane_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service" {
    role       = "${aws_iam_role.eks_control_plane_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Security groups for CP, Workers and CP API inbound
resource "aws_security_group" "eks_control_plane" {
  name        = "eks_allow_all-${var.cluster_name}"
  description = "Allow all inbound traffic"
  vpc_id      = "${data.aws_vpc.default.id}"
}

# resource "aws_security_group" "eks_control_plane_api_ingress" {
#   name        = "eks_allow_all"
#   description = "Allow all inbound traffic"
#   vpc_id      = "${module.vpc.vpc_id}"

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

#   egress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     cidr_blocks     = ["${var.vpc_cidr}"]
#   }
# }