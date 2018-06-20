# kubectl config
data "template_file" "kubeconfig" {
  template = "${file("${path.module}/templates/kubeconfig.yaml")}"

  vars {
    cluster_name                = "${var.cluster_name}"
    cluster_endpoint            = "${aws_eks_cluster.default.endpoint}"
    certificate_authority_data  = "${aws_eks_cluster.default.certificate_authority.0.data}"
  }
}

resource "local_file" "kubeconfig" {
    content     = "${data.template_file.kubeconfig.rendered}"
    filename    = "./${var.cluster_name}/kubeconfig.yaml"
}

# Worker node config for kube
data "template_file" "worker_auth_config" {
  template = "${file("${path.module}/templates/aws-worker-configmap.yaml")}"

  vars {
    worker_role_arn = "${aws_iam_role.eks_worker.arn}"
  }
}

resource "local_file" "worker_auth_config" {
    content     = "${data.template_file.worker_auth_config.rendered}"
    filename    = "./${var.cluster_name}/worker-aws-auth.yaml"
}