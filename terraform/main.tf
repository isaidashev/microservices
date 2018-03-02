provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_instance" "gitlab-ci" {
  count        = 1
  name         = "gitlab-ci${count.index}"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"
  tags         = ["gitlab-ci"]

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.app-disk-image}"
      size  = "50"
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
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "google_compute_address" "gitlab_ip" {
  name = "gitlab-ci"
}

resource "google_compute_firewall" "firewall_gitlab-ci" {
  name = "allow-gitlab-default"

  #Название сети, в которой действует правило
  network = "default"

  #Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  #Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  #Правило применимо для инстансов с тегом ...
  target_tags = ["gitlab-ci"]
}
