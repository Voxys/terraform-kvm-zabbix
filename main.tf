resource "libvirt_volume" "ubuntu_volume" {
  name   = "ubuntu.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
  #source = "./jammy-server-cloudimg-amd64-disk-kvm.img"
  format = "qcow2"
}

resource "libvirt_volume" "volume" {
  name = "volume-ubuntu"
  base_volume_id = "${libvirt_volume.ubuntu_volume.id}"
  size = 10737418240 # 10GB
}

data "template_file" "user_data" {
  template   = file("${path.module}/cloud_init.cfg.tftpl")
  vars       = {
    username   = var.username,
    public_key = file(var.public_key_path),
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  pool      = "default"
  user_data = data.template_file.user_data.rendered
}

resource "libvirt_domain" "ubuntu" {
  name    = "ubuntu"
  memory  = "2048"
  vcpu    = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "vagrant-libvirt"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.volume.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  provisioner "local-exec" {
    command = "scp -qo StrictHostKeyChecking=no -O -i ${var.private_key_path} -r ./floppy-files ${var.username}@${libvirt_domain.ubuntu.network_interface.0.addresses.0}:/tmp"
  }

  provisioner "remote-exec" {
    connection {
      host        = libvirt_domain.ubuntu.network_interface.0.addresses.0
      agent       = true
      type        = "ssh"
      user        = var.username
      private_key = file(var.private_key_path)
    }

    inline = ["sudo apt-add-repository ppa:ansible/ansible -y","sudo apt update","sudo apt install ansible -y","sudo ansible-playbook /tmp/floppy-files/playbook.yml"]
  }

  depends_on = [
    libvirt_volume.volume
  ]
}

output "vm_ip_address"  {
  value = "${libvirt_domain.ubuntu.network_interface.0.addresses.0}"
}