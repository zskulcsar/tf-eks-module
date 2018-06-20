# Configures the cluster so that workers can connect 
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${var.cluster_name}/worker-aws-auth.yaml --kubeconfig=${var.cluster_name}/kubeconfig.yaml"
  }

  triggers {
    worker_auth_config = "${data.template_file.worker_auth_config.rendered}"
    kubeconfig         = "${data.template_file.kubeconfig.rendered}"
  }
}
