# Part 2 - Simple Resources
In this section we will discuss resources and spin up a droplet.

## More Data Providers
As you can see from the code, we have removed our digital_ocean account 
data provider (that was only there to demonstrate how to use data
sources) and have replaced them with two of the same type of data source,
`digitalocean_ssh_key`. The documentation for this data provider can be found
[here](https://www.terraform.io/docs/providers/do/d/ssh_key.html)

```
data "digitalocean_ssh_key" "home" {
    name = "Home Desktop"
}

data "digitalocean_ssh_key" "work" {
    name = "Work Laptop"
}
```

This allows us to get information about our SSH keys that are currently
stored in DigitalOcean. As you can see, one is name `home` and the other `work`.
This is to allow us to differentiate keys and add them to our droplet so we 
can login to them. As the documentation states, the only argument required is
the name of the key. This is the name of the key that I have set inside 
DigitalOcean when I created the key. 

Now that we've done this, we have access to our SSH keys. This will allow us to
specify them on creation of our droplet so we can login to the droplet after
it is provisioned.

## Our First Resource - Creating a Droplet
Now that we have our SSH keys we can create a single droplet. The documentation
for this resource can be found 
[here](https://www.terraform.io/docs/providers/do/r/droplet.html).

In the resource definition below we are creating a droplet with the following
attributes:

* *image* - This is the operating system image provided by DigitalOcean. We're
creating an Ubuntu 18.04 droplet
* *name* - This is the hostname of the droplet and will show up in the 
DigitalOcean UI. Ours is named web-1
* *region* - This is the datacenter we want the droplet to be created in. This
droplet will be created in the `nyc3` datacenter.
* *size* - This is the specification for the size of the droplet. To see which
sizes are supported checkout [this tool](https://slugs.do-api.dev/)
* *ssh_keys* - These are the keys we want loaded onto the server so we can login
with them.

```
resource "digitalocean_droplet" "web" {
    image = "ubuntu-18-04-x64"
    name = "web-1"
    region = "nyc3"
    size = "s-1vcpu-1gb"
    ssh_keys = [data.digitalocean_ssh_key.home.id, 
        data.digitalocean_ssh_key.work.id]
}
```

After we run Terraform with this specification, we'll have a single droplet
name `web-1` that is Ubuntu 18.04 with 1 CPU and 1GB RAM running in the `nyc3`
datacenter. We can then login as root with our specified SSH keys.

## Outputting the IP Address
Once the droplet is spun up, we'll need to know what it's IP address is so we can
login to the server. By default, DigitalOcean droplets are given an ipv4 address
so, we'll want to get this address. You can see all the attributes that can
be exported in the documentation. Notice that the variable name layout for the
resource we want is 
`<name_of_resource>.<user_defined_variable_name>.<attribute>`. This is how we
get data out of a resource. Unlike variables or data sources, there isn't a 
`<type>` prepended on the name.

```
output "server_ip" {
    value = digitalocean_droplet.web.ipv4_address
}
```

## Running this file
1. Make sure you've setup the providers by running 
```
terraform init
```
2. First run the plan command to see what your Terraform is going to do. It
should show you the specifications for the droplet that will be created.
```
terraform plan
```
3. Once you're happy with the plan, you can run apply. This will execute the 
the file and provision the resources as specified. You'll have to answer
`yes` when it asks you if you want to apply.
```
terraform apply
```
4. Once you are done with the droplet and want to delte it you can run destroy.
You will be asked to confirm that you wish to destroy the resource.
```
terraform destroy
```
5. If you want to see the ipv4 address of your droplet again, you can check
the outputs by running the output command.
```
terraform output
```
**Note** - This will only report on the state that was generated the most 
recent time `terraform apply` was run. If you were to delete the droplet from
the UI and not terraform you'd need to run `terraform apply` again, but this will probably lead to a broken state file.