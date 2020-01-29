# Part 3 - Parameterizing our Files and Workspaces
In this section we will discuss parameterizing our terraform files for maximum
reusability, creating different configurations for different environments, and
using workspaces to keep our environments separated and clean.

## Parameterizing for Maximum Reusability
In the last section we stood up static droplet. There isn't much ability to 
change anything about the droplet (like the size, region, name, etc.). While
this may be what we want, our Terraform file would be much more useful if we
could decide certain attributes of our droplet at runtime. So lets add
a few more variables so we can change the `region`, `size`, and number of
droplets we create.

```
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
```

As you can see, there is more information within the variable creation than 
there was when we created our variable for our `do_token`. This is because it 
makes sense for us to declare types and set defaults for these variables 
(*note* - while we didn't set a default for our token, we could have set the
type). By setting defaults and using these variables in place of hard-coded
data in our resource we can still ensure that our terraform will execute with
no variables present, but if we want to change say, the droplet size, we can
easily do that.

## Updating Our Droplet Spec
Now that we have variables to substitute out with our hard-coded data lets
go ahead and update our droplet spec.

We use our variables as follows:

* *region* - We simply replace the data in `region` with `var.region`. This will
now allow us to set the region our droplet(s) are deployed to.
* *droplet_count* - Terraform provides a reserved word named `count` that allows
us to specify how many droplets we want to create. This reserved word is new
in Terraform 0.12, meaning that if you used `count` as a variable name in prior
versions of Terraform you will no longer be able to.
* *droplet_size* - We simply replace the data in `size` with `var.droplet_size`.
This will now allow us to set the size of the droplet(s).

```
resource "digitalocean_droplet" "web" {
    count = var.droplet_count
    image = "ubuntu-18-04-x64"
    name = "web-${var.region}-${count.index +1}"
    region = var.region
    size = var.droplet_size
    ssh_keys = [data.digitalocean_ssh_key.home.id, 
        data.digitalocean_ssh_key.work.id]

    # ensures that we create the new resource before we destroy the old one
    # https://www.terraform.io/docs/configuration resources.html#lifecycle-lifecycle-customizations
    lifecycle {
        create_before_destroy = true
    }
}
```

### What about `name`?
But wait, what is all that in the `name` variable? That is string interpolation.
Simply put, it allows us to combine variables and strings to have more dynamic
names for our droplets. Let's break it down.

`"web-${var.region}-${count.index +1}"`
* `web-` - This is just part of a string. Nothing special here. We could change
it to `kitty` if we wanted.
* `${var.region}` - In a previous section we mention the `${var}` interpolation
syntax from previous versions of Terraform. This interpolation syntax isn't
needed when the variable is by itself, but when we are combining it we must
have it. Otherwise how would we know where the string part ends and the variable
part begins.
* `the - between region and count` - Just a -. Makes it look nice.
* `${count.index +1}` - You can envision count as a loop from `0 < count`. Every
droplet that is created is assigned an index by count. So, if you have three
droplets the indices will be 0, 1, 2 respectively. By adding the `+ 1` to the
end we simply make the indices 1, 2, 3 to be a bit nicer.

This means, when it's all said and done, if our variables are set to 
`region=nyc3` and `droplet_size=3` that a possible name for one droplet is
`web-nyc3-2`. 

### Lifecycle management
The last update we'll make to our droplet is adding lifecycle management. "By 
default, when Terraform must make a change to a resource argument that cannot be
updated in-place due to remote API limitations, Terraform will instead destroy 
the existing object and then create a new replacement object with the new 
configured arguments." - [Terraform Documentation](https://www.terraform.io/docs/configuration/resources.html#lifecycle-lifecycle-customizations)
This can be potentially problematic if you're trying to do a resource update
with 0 downtime. By adding `create_before_destroy`, this behavior is changed
to where the new resources are spun up first, and when Terraform deems that
a success *then* it will tear down the old resources.

```
    # ensures that we create the new resource before we destroy the old one
    # https://www.terraform.io/docs/configuration/resources.html#lifecycle-lifecycle-customizations
    lifecycle {
        create_before_destroy = true
    }
```

## Changing Our Output Variables
Now that we have the potential for multiple droplets being spun up we need
to modify our output variable to accommodate for this. We simply add a `*` 
character between the `<user_defined_variable>` and `<attribute>` as shown 
below.

```
output "server_ip" {
    value = digitalocean_droplet.web.*.ipv4_address
}
```

## Passing in arguments
Now that our code is setup to accept variables, how do we actually pass
variables in? There are three ways do this

1. *Command Line Arguments* - You can pass in arguments one by one via the
command line interface. `terraform plan/appply -var 'droplet_size=3'
2. *Environment Variables* - You can set arguments as environment variables, so
long as they are prepended with the `TF_VAR` prefix. 
`export TF_VAR_droplet_size=3`
3. *Variable file* - You can create a variable file (as shown below) and pass
it in via the command line `terraform plan/apply -var-file="sfo2.tfvars"`

```
# sfo2.tfvars
region = "sfo2"
droplet_count = 10
droplet_size = "s-2vcpu-4gb"
```

```
#nyc3.tfvars
region = "nyc3"
droplet_count = 3
```
Personally, I would use the variable file method. This allows you to version
control your specific configurations (so long as they don't contain sensitive
information). 

*note* - It is best practice to name your variable file with the `.tfvars`
extension. Any file name `terraform.tfvars` or any file with `.auto.tfvars` 
extension will be automatically loaded if present. 

## Workspaces
Now that we can run our terraform with different variables, we may want to use
this file to setup multiple clusters. This can become a problem since Terraform
only allows one state per `workspace`. Currently we've been working in the 
default workspace without even knowing it. However, we can create new workspaces
with different states.

We can create a new workspace for our `nyc3` region as follows.
```
terraform workspace new nyc3
```
This will create a `terraform.tfstate.d` directory that now holds the states
of our different workspaces. Now we can plan/apply/destroy resources that are
only associated with a particular state. 

In this situation we would create a workspace for each region we want to 
create resources in. We would create the resources and switch back and forth
between them as necessary to maintain our infrastructure. 

```
terraform workspace select sfo2
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
6. If you want to see the ipv4 address of your droplet again, you can check
the outputs by running the output command. This will show you the outupt on 
the state file dependent on which workspace you have activated.
```
terraform output
```
**Note** - This will only report on the state that was generated the most 
recent time `terraform apply` was run. If you were to delete the droplet from
the UI and not terraform you'd need to run `terraform apply` again, but this will probably lead to a broken state file.
7. Once you're ready to setup another region (say `sfo2`), go back to step 2 and
replace `nyc3` with `sfo2`.