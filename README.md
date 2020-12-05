# ECS Sandbox
This is a Terraform project which will create a barebones set of resources for an ECS cluster.

Boilerplate VPC Stuff
* VPC
* Use first 2 subnets of Region (us-east-2 by default)
* Public and Private Subnets
* Bastion host for SSH Access

ECS Stuff
* EC2 Launch Configuration (use Amazon ECS-Optimized AMI, t2.micro)
* Auto-Scaling Group
* Security Groups (ALB -> ASG Hosts, Bastion -> ASG Hosts)
* Load Balancer
* Target Group
* Service-Linked Role for ECS
* ECS Cluster
* ECS Service (registered against target group)
* ECS Task (nginx)


# Create
Terraform is uses the same 3 commands for all modules. This project is a set of modules composed
upon each other, so you'll need to only do this once.

```
terraform init
terraform plan
terraform apply
```

`terraform init` will retrieve any required modules from the terraform registry, github, or bitbucket.

`terraform plan` will show you the resources to be created/updated/destroyed

`terraform apply` will apply the changes.

```

# Destroy
You'll destroy all of the above resources opposite of the order you created them using `terraform destroy`.

```
terraform destroy
```

Some resources may take time to destroy. For example, ECS will be attempting to keep your service running _as you destroy it and the ASG underneath it_, which may take some time. You can re-run `terraform destroy` or go into the AWS Console to remove the resource.

Don't panic! Some resources take time to destroy!
In particular, it takes time to drain ECS tasks from the cluster, drain the ALB Target Groups, and
drain all of the instances out of the ASG.

# What Will This Cost Me?
All billable resources created here (EC2, CloudWatch Logs) are in the AWS Free Tier, EXCEPT THE NAT GATEWAY.

The NAT Gateway is billed by the hour regardless of
whether or not you use it.

You should destroy all the resources when you are
not actively using them, lest you wind up with a
$50 AWS bill for your highly-available, horizontally scalable, containerized Hello World application.

In the creation of this project, I ran up a bill of about $3. Do the math on that and you'll see that I have no idea what I'm doing.

# Pricing Considerations

## $$ - NAT Gateway vs PrivateLink Endpoints
ECS requires access to several AWS Endpoints. This can be done via
VPC PrivateLink, which will expose the endpoints internally to your VPC,
or via NAT Gateways, which allow your private subnet EC2s to connect
to the service endpoints over the public internet.

* com.amazonaws.<region>.ecs-agent
* com.amazonaws.<region>.ecs-telemetry
* com.amazonaws.<region>.ecs

As of this writing, VPC Privatelink endpoints are charged on a per-endpoint,
per-AZ, per-hour basis. NAT Gateways are charged on a "per NAT-gateway hour" basis.

Both services additionally charge on a per-GB basis.

See https://aws.amazon.com/vpc/pricing/ to help decide which approach to take.

# Troubleshooting
## Instances not registering with ECS Cluster
See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html, Step 9. You must populate the ECS_CLUSTER variable on the EC2 instances. This is
done using instance "User Data". Without this, containers will try to register against
your VPC's default cluster.

```
#!/bin/bash
echo ECS_CLUSTER=your_cluster_name >> /etc/ecs/ecs.config
```

## Instances Not Staying Up
Look at the *stopped* tasks on the cluster. The "Last Status" column should give you some
indication of what what wrong. For example, if an "essential service" has died, it means
that your process (httpd, spring-boot app, etc) has stopped running.

Check the log output for the either by drilling down into the task _and container_
and clicking on "View logs in CloudWatch", or go to CloudWatch directly and 
dig around until you find the log group associated with your task.

If none of that works, SSH in via the bastion host to the instances created by your ASG
```
ssh -J ec2-user@bastion-public-ip ec2-user@asg-private-ip
```

and poke around with the `docker` command, e.g. `docker ps`, `docker container ls`, etc.



## Instances not registering with ALB Target Group
Look at the *stopped* tasks on the cluster. If they are being terminated because they fail 
ALB health checks, then verify that the security group assigned to the ASG
instances has these ephemeral port ranges open.

```
32768 - 61000
49153 - 65535
```

# Related Links
* https://registry.terraform.io/search/modules?namespace=terraform-aws-modules
* https://github.com/terraform-aws-modules/