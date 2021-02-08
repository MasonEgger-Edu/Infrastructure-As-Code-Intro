terraform {
    required_providers {
        digitalocean = {
            source = "digitalocean/digitalocean"
        }
    }
}

variable do_token {}
provider digitalocean {
    token = var.do_token
}

data "digitalocean_ssh_key" "home" {
    name = "Home Desktop WSL"
}

data "digitalocean_ssh_key" "work" {
    name = "Work Laptop"
}

data "digitalocean_domain" "web" {
    name = "egger.codes"
}

variable "region" {
    type    = string
    default = "nyc3"
}

variable "droplet_count" {
    type = number
    default = 1
}

variable "droplet_size" {
    type = string
    default = "s-1vcpu-1gb"
}

resource "digitalocean_droplet" "web" {
    count = var.droplet_count
    image = "ubuntu-20-04-x64"
    name = "web-${var.region}-${count.index +1}"
    region = var.region
    size = var.droplet_size
    ssh_keys = [data.digitalocean_ssh_key.home.id, 
        data.digitalocean_ssh_key.work.id]

    user_data = <<EOF
    #cloud-config

    packages:
        - nginx

    runcmd:
        - [ sh, -xc, "echo '<h1>web-${var.region}-${count.index +1}</h1>' >> /var/www/html/index.nginx-debian.html"]
    EOF

    # ensures that we create the new resource before we destroy the old one
    # https://www.terraform.io/docs/configuration/resources.html#lifecycle-lifecycle-customizations
    lifecycle {
        create_before_destroy = true
    }
}
resource "digitalocean_loadbalancer" "web" {
    name        = "web-${var.region}"
    region      = var.region
    droplet_ids = digitalocean_droplet.web.*.id

    forwarding_rule {
        entry_port = 80
        entry_protocol = "http"

        target_port = 80
        target_protocol = "http"
    }


    lifecycle {
        create_before_destroy = true
    }
}

resource "digitalocean_record" "web" {
    domain = data.digitalocean_domain.web.name
    type   = "A"
    name   = var.region
    value  = digitalocean_loadbalancer.web.ip
    ttl    = 30
}

output "servers" {
    value = digitalocean_droplet.web.*.ipv4_address
}

output "lb" {
    value = digitalocean_loadbalancer.web.ip
}
