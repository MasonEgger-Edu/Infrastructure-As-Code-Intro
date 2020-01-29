# Part 4 - Resource Dependencies and a Complete Infrastructure
In this section we will discuss resource dependencies and finish building
out a small web cluster behind a load balancer.

## Using `cloud-init` With Our Droplet
While Terraform is not a Configuration Management tool, it does provide a 
little configuration bootstrap support. Depending on your cloud provider,
the resources may support using `user_data` with your droplets. This is data
that gets fed to [`cloud-init`](https://cloudinit.readthedocs.io/en/latest/).
`cloud-init` is a tool that is on most cloud based virtual private servers
that does a lot of firstboot style provisioning of the server. One way you could
pair this with a Configuration Management tool is to have `cloud-init` auto-join
your droplets to a cluster, but that's a talk for another day. We're going to 
use `cloud-init` to install `nginx` automatically and append the hostname of
the droplet to the default `nginx` greeting page so we can see our load balancer
in action later.

```terraform
    user_data = <<EOF
    #cloud-config
    packages:
        - nginx
    runcmd:
        - [ sh, -xc, "echo '<h1>web-${var.region}-${count.index +1}</h1>' >> /var/www/html/index.nginx-debian.html"]
    EOF
```
The `user_data` section of the droplet resource uses a heredoc to allow you to
write `cloud-init` configurations directly. View the
[Modules Documentation](https://cloudinit.readthedocs.io/en/latest/topics/modules.html)
to see everything you can do with `cloud-init`.

## Creating a Load Balancer Resource
Now that we have multiple webservers setup to host our sites we should put
them behind a load balancer to help mitigate the traffic. You can find the  
documentation for the DigitalOcean load balancer Terraform resource is 
[here](https://www.terraform.io/docs/providers/do/r/loadbalancer.html).

This is an example of a resource that has a dependency on another resource.
We need the ids of the droplets that we created so the load balancer knows 
where to forward traffic to. We can do this similarly to creating output
variables. We set the `droplet_ids` field to all of the ips of our `web` 
droplets that we created by assigning it `digitalocean_droplet.web.*.id`. We
also add some basic information such as a name and region for the load balancer
(*note* - the load balancer must be in the same region as the drolets. Using
the region variable here will ensure that). You will also need to 
setup forwarding rules for traffic. The rules we have stated below simply 
forward inbound http traffic on port 80 of the load balancer to the port 80
on the droplet. For more information about DigitalOcean load balancers visit
the [documentation page](https://www.digitalocean.com/docs/networking/load-balancers/how-to/tcp/).

```terraform
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
```

## Creating a DNS Record Resource
Now that we have a load balancer for our cluster it would be nice to have
a human readable name to point to the load balancer.

**Note** - Before you proceed with this section, you must have a domain name
registered and managed by DigitalOcean. If you don't, you can purchase one
and set the name servers in your domain registrar to the name servers for
DigitalOcean. For more information of how to do this, visit this 
[quickstart guide](https://www.digitalocean.com/docs/networking/dns/how-to/add-domains/).

### Adding the Data Source
First thing we need to do is add a data source for our domain. This will allow
us to check if we actually h ave access to this domain as well as use the name
as a variable in the DNS resource. More information about the data source
provider can be found 
[here](https://www.terraform.io/docs/providers/do/d/record.html)

```terraform
data "digitalocean_domain" "web" {
    name = "egger.codes"
}
```

### Creating the A Record
Finally, we need to create the A record (ipv4 name record) for our load balancer.
In the resource we need to specify the `domain` (taken from our data source),
the `type` (an A record), the `name` of the record (we'll use the region as
our name), the `value`, or what IP the record should point to (we use the attribute
from the loadbalancer to get its ip), and finally the `ttl` or Time To Live (we
set this to 30 seconds so we can change it out quickly. For longer lived records
it is a good idea to set this higher so as to not invalidate DNS cache so 
quickly).

More information about the DNS resource can be found 
[here](https://www.terraform.io/docs/providers/do/r/record.html)

```terraform
resource "digitalocean_record" "web" {
    domain = data.digitalocean_domain.web.name
    type   = "A"
    name   = var.region
    value  = digitalocean_loadbalancer.web.ip
    ttl    = 30
}
```

## Adding More Output Variables
In addition to our IP address of the droplets we also want to see the IP
address of the load balancer. The process is the same as adding the output
variable for our droplets ip addresses.

```terraform
output "lb" {
    value = digitalocean_loadbalancer.web.ip
}
```

## Running this file
1. Make sure you've setup the providers by running 
```
terraform init
```
2. Create a workspace for a region. 
```
terraform workspace new nyc3
```
3. Run the plan command and be sure to specify the appropriate variable file 
for the region.
```
terraform plan -var-file="nyc3.tfvars"
```
4. Once you're happy with the plan, you can run apply. This will execute the 
the file and provision the resources as specified. You'll have to answer
`yes` when it asks you if you want to apply. You wll also need to specify the
variable file here.
```
terraform apply -var-file="nyc3.tfvars"
```
5. Once you are done with the droplet and want to delte it you can run destroy.
You will be asked to confirm that you wish to destroy the resource.
```
terraform destroy
```
6. If you want to see the ipv4 address of your droplet again, or the ipv4 address
of the load balancer you can check
the outputs by running the output command. This will show you the outupt on 
the state file dependent on which workspace you have activated.
```
terraform output
```
**Note** - This will only report on the state that was generated the most 
recent time `terraform apply` was run. If you were to delete the droplet from
the UI and not terraform you'd need to run `terraform apply` again, but this 
will probably lead to a broken state file.
7. Once you're ready to setup another region (say `sfo2`), go back to step 2 and
replace `nyc3` with `sfo2`.
8. Once your infrastructure is up you can view the DNS name or ipv4 address 
of the load balancer in a browser and watch the requests be round-robined to
your droplets.