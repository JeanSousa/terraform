# Boa pratica sempre começar pelo arquivo main.tf ele Representa as configurações do projeto terraform
terraform {
  required_providers {
    digitalocean = { # esse modelo do registry.terraform.io já da o modelo do provider
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}
# token é a chave para se autenticar na conta da digital ocean
# obtenho token em https://cloud.digitalocean.com/account/api/tokens na digital ocean
provider "digitalocean" {
  token = var.do_token
}

# 1º recurso é o droplet, a maquina ubuntu que estará com o jenkins
# Create a new Web Droplet in the nyc2 region
resource "digitalocean_droplet" "jenkins" {
  image    = "ubuntu-22-04-x64"
  name     = "jenkins"
  region   = var.region
  size     = "s-2vcpu-2gb" # maquina standard 2cpus 2gb
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.id]
}

# ssh_key é o nome desse recurso
data "digitalocean_ssh_key" "ssh_key" {
  name = var.ssh_key_name # aqui é o nome exato da chave ssh da variavel
}

# CLUSTER KUBERNETES
resource "digitalocean_kubernetes_cluster" "k8s" {
  name    = "k8s"
  region  = var.region # pega o valor da variável região
  version = "1.26.3-do.0"

  node_pool {
    name       = "default"
    size       = "s-2vcpu-2gb" # size do node dentro do cluster
    node_count = 2             # quantidade de nós do cluster
  }
}


variable "do_token" {
  default = ""
}

variable "ssh_key_name" {
  default = ""
}

variable "region" {
  default = ""
}

# output para o droplet que esta o jenkins
output "jenkins_ip" { # pego o valor olhando no registry.terraform.io no cloud provider digital ocean
  # value = tipo_recurso.nome_recurso.atributo
  value = digitalocean_droplet.jenkins.ipv4_address
}

# local file pego o tipo no registry.terraform.io 
# na documentação da hashcorp https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
resource "local_file" "kube_config" {
  content  = digitalocean_kubernetes_cluster.k8s.kube_config.0.raw_config # pego o atributo kube.confi.0 do registry em kubernetes
  filename = "kube_config.yaml"
}