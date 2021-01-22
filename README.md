# Infrastructure as Code Presentation
## Author: Mason Egger

## Presentations
* DigitalOcean Webinar - 1/30/2020
* Indy Py - 8/13/2020

## About
This is an introductory webinar into Infrastructure as Code, specifically
focusing on [Hashicorp's](https://www.hashicorp.com/) [Terraform](https://www.terraform.io).


This presentation is broken into 4 parts to ease the attendee into the basics
of Terraform. All resources demoed in this presentation are from the DigitalOcean
provider. The parts are divided up as follows:

1. Using Variables, Providers, and Data Sources
2. Basic Resources
3. Parameterizing Our Files and Using Workspaces
4. Resource Dependencies and a Complete Infrastructure

More about the specific parts can be found in the READMEs in the appropriate
sections. 

Part 1 will also cover some of the more basic principles of Terraform, like
how to run it, remote state, variable interpolation, etc. For this reason
you may want to be sure to refer to it in later sections as each section
builds on each other and only the parts of the file that changed will be 
discussed.

## Prerequisites
Prerequisites to follow this tutorial along *exactly* are as follows:
1. Have a [DigitalOcean](https://digitalocean.com) account. The examples are 
all done in DigitalOcean so you will need access.
2. You will need an DigitalOcean API token ready. If you don't know how to
make one you can follow these 
[instructions on creating an API Token](https://www.digitalocean.com/docs/api/create-personal-access-token/)

## Misc.

**Note** - The structure of this repository is for educational purposes. The 
layout for these files does not reflect the best practices for laying out
a Terraform directory. For the best practices for Terraform Repositories, view [this presentation](https://www.hashicorp.com/resources/terraform-repository-best-practices) and for overall Terraform 
best practices visit [this documentation](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
