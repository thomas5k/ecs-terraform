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

# Related Links
* https://registry.terraform.io/search/modules?namespace=terraform-aws-modules
* https://github.com/terraform-aws-modules/