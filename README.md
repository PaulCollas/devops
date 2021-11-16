# Efrei - DevOps - Terraform

## Goal
This series of exercise focus on building and deploying a NodeJS application in a fully automated way.
At the end of the exercise, you should be able to build all this infrastructure with a simple `terraform apply` and destroy everything with a `terraform destroy`

### Architecture schema
```

                                     ┌─────────────────┐
                                     │                 │
                                     │  Load Balancer  │
                                     │                 │
                                     └────────┬────────┘
                                              │
                                              │
                                              │
                                              │
      ┌────────────────────────────────┐      │      ┌────────────────────────────────┐
      │           Server 01            │      │      │           Server 02            │
      │                                │      │      │                                │
      │     ┌──────────────────────┬───┤      │      ├───┬────────────────────────┐   │
      │     │                      │ p │      │      │ p │                        │   │
      │     │  Docker Container    │ o │      │      │ o │   Docker Container     │   │
      │     │                      │ r │      │      │ r │                        │   │
      │     │ with the application │ t ◄──────┴──────► t │  with the application  │   │
      │     │                      │   │             │   │                        │   │
      │     │                      │ 8 │             │ 8 │                        │   │
      │     │                      │ 0 │             │ 0 │                        │   │
      │     └─────────────┬────────┴───┤             ├───┴────────────┬───────────┘   │
      │                   │            │             │                │               │
      └───────────────────┼────────────┘             └────────────────┼───────────────┘
                          │                                           │
                          │                                           │
                          │            ┌──────────────┐               │
                          │            │              │               │
                          │            │  Postgresql  │               │
                          └────────────►   Database   ◄───────────────┘
                                       │              │
                                       └──────────────┘
```

- The application we are trying to deploy is a simple web application that is already developed, build and push to a public docker repository.
- The application requires a postgresql database to work properly.
- The provided docker image requires an environment variable `DATABASE_URI=postgres://<username>:<password>@<database-ip>:<database_port>/<databasename>` in order to connect to the database.
- The application listen on port 8080
- The image is available at the following address:
```
rg.fr-par.scw.cloud/efrei-devops/app:latest
```

## Notes

- All your terraform code MUST be written in `main.tf` file.
- Each exercise requires the previous one to be completed first.

## Prerequisite

Before starting, you should make sure that:
- You have access to the Scaleway account that was provided to you for this session  √
- Terraform is installed on your laptop ( version >= 1.0.0 ). You can check the version by running `terraform --version`  √
- You have an SSH Key (without a password or with running ssh-agent) and you have added it to your Scaleway account  √

## Exercise 01: Install Scaleway provider

Following documentation install and configure the latest release of the [Scaleway Terraform Provider](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs)
If your configuration is correct running `terraform init` should download the latest version of the provider.

## Exercise 01: Create the database

Using the [Scaleway Terraform Provider](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs) create a postgresql database:

Mandatory settings for the database instance:
```
node_type = "db-dev-s"
engine = "PostgreSQL-12"
is_ha_cluster = false
```
Other settings are up to you.

You will need to use [scaleway_rdb_instance](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/rdb_instance) resource.

After you run `terraform apply` you should be able to see your database in the [Scaleway RDB dashboard](https://console.scaleway.com/rdb/instances)

## Exercise 02: Create a server

Now that you created your database we need to create a simple server instance.

You will need to use
- [scaleway_instance_server](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_server)
- [scaleway_instance_ip](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_ip)

Mandatory settings for server:
```
type = "DEV1-S"
image = "ubuntu_focal"
```

**Note:** If you don't create and attach a public IP to your server you will not be able to connect via SSH.

After you run `terraform apply` you should be able to see your server in the [Scaleway Instance dashboard](https://console.scaleway.com/instance/servers)
You should be able to connect to your new server using SSH.

## Exercise 03: Server user data

The `user_data` property on `scaleway_instance_server` allows you to pass information from Terraform config that you can be read from within the instance.
We will use `user_data` to pass the `DATABASE_URI` variable to our server.

You should set a `user_data` with key `DATABASE_URI` and the value `DATABASE_URI=postgres://<username>:<password>@<database-ip>:<database_port>/<databasename>`.
Dynamic information should be read from the scaleway_rdb_instance resource. (see [String interpolation](https://www.terraform.io/docs/language/expressions/strings.html#interpolation))

To test your configuration connect to your server using SSH and run `scw-userdata DATABASE_URI` it should print the correct value.

_Hint: scaleway_rdb_instance automatically create a database named `rdb` that can be used for the application_

## Exercise 03: Configure a server

We will now set up our server.
While you are doing it carefully **write down all command** that you run ( you will need it for the next exercise)

To set up your server you should connect to your server and:
1. [Install docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
2. Run this command `docker run -d --name app -e DATABASE_URI="$(scw-userdata DATABASE_URI)" -p 80:8080 --restart=always rg.fr-par.scw.cloud/efrei-devops/app:latest`

If everything is set up correctly, you should be able to open your browser on the server IP and see the application running.

_Hint: Running `docker log -f app` will allow you to get the application log_

## Exercise 04: Automatic configuration

Now that we know how to install a server manually let's automatize it.
In this exercise we will tell terraform to set up our server after, it's created.

Using [Remote-Exec](https://www.terraform.io/docs/language/resources/provisioners/remote-exec.html) provisioner on your `scaleway_instance_server` you should tell
Terraform all command that needs to be run when the server is created.
Make sure you add all the command that you previously run by hand.
Be carefully when running script command that require user input (typing yes to a prompt for example) will not work.
You need to pass correct flag to your command to avoid prompt.

You can either Tell Terraform to run commands directly or create a script file and [tell Terraform to copy it and run it on the server](https://www.terraform.io/docs/language/resources/provisioners/remote-exec.html#script).
⚠️ **Warning**: provisioners are only executed when the resource is created. If you update a provisioner, you will need to re-create the resource for the changes to be applied.
To force terraform to re-create a resource you can use `terraform taint` command.
A tainted resource will be re-created during the next `terraform apply`

If you configured everything correctly terraform should create the server and run all commands required for the web application to be up and running on the `80` port.

## Exercise 05: Double it

Using [count](https://www.terraform.io/docs/language/meta-arguments/count.html) Terraform special attribute double the number of servers with our application.

## Exercise 06: Load balancer

Now that we have 2 servers with our application we need to create a load balancer in front of them.
Using `scaleway_lb`, `scaleway_lb_ip`, `scaleway_lb_backend` and `scaleway_lb_frontend` you should be able to create a load balancer.
Remember that you should not use hard-coded IPs in your configuration but rely on Terraform resources properties instead.

If everything works correctly, you should be able to access your application using the load-balancer IP.
You can check the [Scaleway LB dashboard](https://console.scaleway.com/load-balancer/lbs) so see your LB and the configuration.

Mandatory settings for lb:
```
type = "LB-S"
```


Hint: [Splat expression](https://www.terraform.io/docs/language/expressions/splat.html) might become handy while configuring your `scaleway_lb_backend.server_ips`

## The End

If you configured everything properly, you should be able to run
```
$> terraform destroy
```
to totally wipe your infrastructure and run
```
$> terraform apply 
```
to bring everything back up again.

## Cleaning Up

Another group will use the same Scaleway account. Before you go please make sure you delete all your Scaleway resources and delete your SSH key from your account.


## Bonus Exercise: Packer

This is great we have fully automatized the deployment of our application.
But reinstalling docker and our application each time we create a server is not ideal.
Instead of relying on Terraform to run command each time our server start, we can create a custom image using [Packer](https://www.packer.io).
Write a packer file that automatically creates a Scaleway server image with our application pre-installed.
You can then use the image uuid on the `scaleway_instance_server` terraform resource and remove all the `provisioner`
