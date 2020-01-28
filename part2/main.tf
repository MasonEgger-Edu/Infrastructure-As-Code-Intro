variable do_token {}
provider digitalocean {
    token = var.do_token
}

data "digitalocean_ssh_key" "home" {
    name = "Home Desktop"
}

data "digitalocean_ssh_key" "work" {
    name = "Work Laptop"
}

resource "digitalocean_droplet" "web" {
    image = "ubuntu-18-04-x64"
    name = "web-1"
    region = "nyc3"
    size = "s-1vcpu-1gb"
    ssh_keys = [data.digitalocean_ssh_key.home.id, 
        data.digitalocean_ssh_key.work.id]
}

output "server_ip" {
    value = digitalocean_droplet.web.ipv4_address
}