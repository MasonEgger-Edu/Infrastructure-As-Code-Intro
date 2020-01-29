# Part 1 - Providers, Variables, and Data Sources

This section discusses providers, variables, and data sources. This terraform
file, when executed, simply prints out the user's droplet limit.

## Providers

Providers are pluginable parts of the Terraform architecture that
allow you to access resources. You can find what providers are supported
on the [Terraform Provider page](https://www.terraform.io/docs/providers/index.html)
For all things within this workshop, we are going to be demoing the [DigitalOcean Terraform Provider](https://www.terraform.io/docs/providers/do/index.html)
These are typically automatiaclly installed when you perform a `terraform init` in a directory with say, your `main.tf`.
All providers that are specified in your file will be automatically downloaded
into the `.terraform` directory within your project and used whenever you 
declare a resource from the provider.

In the code below we declare that the value of the token can be passed in
via a variable. This will help us with our automation and keep secrets
from being hardcoded into our Terraform files.

```
provider digitalocean {
    token = var.do_token
}
```
## Setting your DigitalOcean Token
Currently, if you don't set this token when you run the Terraform command you 
will be asked to input the token into the command line. This can get be 
cumbersome to do repeatedly so you'll want a place to store this token. There
are numerous ways to do this, but I prefer storing the token securely somewhere
and when I need to work on terraform setting it as an environment variable on
my local machine. If you are using a CI/CD system you would be able to inject
the token on runtime. 

### Terraform Environment Variables
Terraform supports the use of environment variables. Any environment variable 
that is name `TF_VAR_*` will be seen by terraform. So in our case the variable
that holds our token is `do_token`. So we simply set our do token as such

```
export TF_VAR_do_token="my_happy_token"
```

Now whenever we run the terraform command it will pickup our token from the
environment seamlessly.

## Input Variables

Terraform supports variable declaration like most programming and configuration
languages. Input Variables are variables that are inputed into Terraform
before the Terraform is run. This allows for more modularity and reusability 
for our Terraform files. This differs from an Output Variable which is
simply the way to get output from Terraform. Output variables from Terraform 
modules can even be used as Input Variables for another Terraform module. An
example of an input variable is shown below.

```
variable do_token {}
```

However, we can set type and default values if we want to. This is explained
more in Part 2, since it isn't logical to have a default value for an API key.

## Data Sources
Data sources allow for relevant data to be fetched from outside of Terraform.
The data source code below simply allows us to gather our account information.
Many other data sources exist for DigitalOcean that we will use in the next
sections. All of these data sources can be found in the official
[documentation](https://www.terraform.io/docs/providers/do/d/account.html)

```
data "digitalocean_account" "account_info"{}
```

Now that we have this data source in our Terraform file, we can access the data
that it collects when run. We can see an exampleof this in the Output Variables
section.

## Resource Naming
Other than variables and providers, resources in terraform come in two - three 
parts.

For data sources and resources

```
<data_or_resource> <name_of_resource> <user_definied_variable_name>
```

and for Output Variables it is

```
output <user_defined_variable_name>
```

Knowing this structure will be useful for accessing variables from other 
resources.

## Variable Interpolation
Terraform 0.12 changed a lot of how variable interpolation works, mostly
regarding syntax. The quick and easy of it is

1. When you only need the variable and no other alterations, you simply
access the variable by a defined path with no quotes or, if you're used to
pre-0.12 syntax, ${var} syntax.

    * Example: `var.do_token`, `data.digitalocean_account.account_info.droplet_limit`, `digitalocean_droplet.web.ipv4_address`

2. When you need to do string concatenation on a variable you will need
to use the old ${var} syntax.
    * Example: `"web-${var.region}-${count.index +1}"`
    * Also note, `count` is now a reserved keyword in 0.12

If you get confused, visit the [Terraform Documentation](https://www.terraform.io/docs/configuration/expressions.html#interpolation)
for clarity. 

## Output Variables
Output variables are used to get data back to the user at the end of a state
execution or to feed into other terraform modules. The code below uses the
DigitalOcean data source defined above to get the droplet limit of the user
associated with the token that is passed in. If we wanted to look at
other data associated with the account, we could just lookup what other 
attribute we want to access in the 
[documentation](https://www.terraform.io/docs/providers/do/d/account.html).

```
output "droplet_limit" {
    value = data.digitalocean_account.account_info.droplet_limit
}
```
These output variables will be visible on the screen after you've run the code.
They can also be viewed at anytime after you've done an apply with 
`terraform output`

## Running this file
1. Make sure you've setup the providers by running 
```
terraform init
```
2. First run the plan command to see what your Terraform is going to do
```
terraform plan
```
3. Once you're happy with the plan, you can run apply. This will execute the 
the file and provision the resources as specified.
```
terraform apply
```
4. This will output your current droplet limit. If you ever want to see
this value again without re-running the state simply run
```
terraform output
```
**Note** - This will only report on the state that was generated the most 
recent time `terraform apply` was run. If your account were to be updated,
you'd have to run `terraform apply` again to get the new state.

## Keeping State
After you run a `terraform apply` a `terraform.tfstate` json file will be
created with the state of your last run. When you run `terraform output` it 
simply reads the data you want from this file and outputs it. This state file
is how terraform knows what to change when you run apply again. If this state
gets corrupted or deleted terraform will not know how to manage the resources
that were created with it. Guard the state with your life. For this reason
you may want to consider 
[Terraform Cloud](https://www.terraform.io/docs/cloud/index.html) or how to 
[manage remote state](https://www.terraform.io/docs/state/remote.html)

**Warning** - *This state file is not encrypted and may contain sensitive data.
It is highly discouraged to commit these to a version control system*