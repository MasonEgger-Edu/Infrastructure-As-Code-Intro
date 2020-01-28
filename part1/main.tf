variable do_token {}
provider digitalocean {
    token = var.do_token
}

data "digitalocean_account" "account_info"{}

output "droplet_limit" {
    value = data.digitalocean_account.account_info.droplet_limit
}