# # An AMI
# variable "ami" {
#   description = "the AMI to use"
# }

# /* A multi
#    line comment. */
# resource "aws_instance" "web" {
#   ami               = "${var.ami}"
#   count             = 2
#   source_dest_check = false

#   connection {
#     user = "root"
#   }
# }

# Configure the Docker provider
provider "docker" {
  host = "tcp://127.0.0.1:2376"
}

#### Funcking Images

resource "docker_image" "debian" {
  name = "debian:latest"
}

resource "docker_image" "ubuntu" {
  name = "ubuntu:latest"
}

resource "docker_image" "centos" {
  name = "centos:latest"
}

resource "docker_image" "archlinux" {
  name = "base/archlinux:latest"
}

resource "docker_image" "alpine" {
  name = "alpine:latest"
}

resource "docker_image" "opensuse" {
  name = "opensuse/leap"
}

resource "docker_image" "slackware" {
  name = "vbatts/slackware"
}

resource "docker_image" "android" {
  name = "circleci/android:api-28-alpha"
}

resource "docker_image" "trisquel" {
  name = "kpengboy/trisquel"
}

#### Volume
## FIXME: For now it needs to be populated manually. Move x86_64 tarball files inside volume
resource "docker_volume" "nix204x8664" {
  name = "nix204x8664"
}

#### Start containers

resource "docker_container" "nixInstTestDebian" {
  name  = "nixInstTestDebian"
  image = "${docker_image.debian.latest}"

  entrypoint = ["/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"
    read_only      = true
  }
}

resource "docker_container" "nixInstTestUbuntu" {
  name  = "nixInstTestUbuntu"
  image = "${docker_image.ubuntu.latest}"

  entrypoint = ["/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"
    read_only      = true
  }
}

resource "docker_container" "nixInstTestCentos" {
  name  = "nixInstTestCentos"
  image = "${docker_image.centos.latest}"

  entrypoint = ["/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"
    read_only      = true
  }
}

resource "docker_container" "nixInstTestArchlinux" {
  name  = "nixInstTestArchlinux"
  image = "${docker_image.archlinux.latest}"

  entrypoint = ["/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"
    read_only      = true
  }
}

resource "docker_container" "nixInstTestAlpine" {
  name  = "nixInstTestAlpine"
  image = "${docker_image.alpine.latest}"

  entrypoint = ["/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"
    read_only      = true
  }
}

resource "docker_container" "nixInstTestOpensuse" {
  name  = "nixInstTestOpensuse"
  image = "${docker_image.opensuse.latest}"

  entrypoint = ["/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"
    read_only      = true
  }
}

resource "docker_container" "nixInstTestSlackware" {
  name  = "nixInstTestSlackware"
  image = "${docker_image.slackware.latest}"

  entrypoint = ["/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"
    read_only      = true
  }
}

resource "docker_container" "nixInstTestAndroid" {
  name  = "nixInstTestAndroid"
  image = "${docker_image.android.latest}"

  entrypoint = ["/usr/bin/sudo", "/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"

    read_only = true
  }
}

resource "docker_container" "nixInstTestTrisquel" {
  name  = "nixInstTestTrisquel"
  image = "${docker_image.trisquel.latest}"

  entrypoint = ["/data/install-nix.sh"]

  volumes = {
    volume_name    = "nix204x8664"
    container_path = "/data"
    read_only      = true
  }
}

### QEMU/KVM libvirt

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

# Fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

# Create a network for our VMs
resource "libvirt_network" "vm_network" {
  name      = "vm_network"
  addresses = ["10.0.1.0/24"]
}

# Use CloudInit to add our ssh-key to the instance
resource "libvirt_cloudinit" "commoninit" {
  name               = "commoninit.iso"
  ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLbPtWNZwNZp0H/P+jsIqtib0IK/SZ2KOypM+EgW+UM pyro@rogue"
}

# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name   = "ubuntu-terraform"
  memory = "512"
  vcpu   = 1

  cloudinit = "${libvirt_cloudinit.commoninit.id}"

  network_interface {
    network_name = "vm_network"
  }

  # IMPORTANT
  # Ubuntu can hang if an isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = "${libvirt_volume.ubuntu-qcow2.id}"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Print the Boxes IP
# Note: you can use `virsh domifaddr <vm_name> <interface>` to get the ip later
output "ip" {
  value = "${libvirt_domain.domain-ubuntu.network_interface.0.addresses.0}"
}
