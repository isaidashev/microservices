provider "google" {
  credentials = "${file(var.key)}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_compute_instance" "gitlab-ci" {
  count        = 1
  name         = "${var.instance_name}${count.index}"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"
  tags         = ["gitlab-ci"]

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.app-disk-image}"
      size  = "10"
    }
  }

  # определение сетевого интерфейса
  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "default"

    # использовать ephemeral IP для доступа из Интернет
    access_config {}
  }

  metadata {
    #Добавление публичного ключа к инстансу
    ssh-keys = "gitlabci:${var.gitlab_public_key_path}"
  }
}
