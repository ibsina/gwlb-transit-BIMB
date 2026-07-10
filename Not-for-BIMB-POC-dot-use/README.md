# Deployment of FortiGate-VM (BYOL/PAYG) on AWS with GWLB integration and Transit Gateway
## Introduction
A Terraform script to deploy FortiGate-VM instances on AWS with Gateway Load Balancer integration.

## Requirements
* [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) >= 1.0.0
* Terraform Provider AWS >= 3.63.0
* Terraform Provider Template >= 2.2.0
* FOS Version >= 6.4.4

Default deployment values in this folder are configured for Malaysia Region (`ap-southeast-5`) across three Availability Zones (`ap-southeast-5a`, `ap-southeast-5b`, `ap-southeast-5c`).

## Deployment overview
Terraform deploys the following components:
* 1 AWS VPC
  - FGT Security VPC with 1 management, 1 private, 1 gwlb, and 1 transit gateway subnet per AZ across three AZs.
      - 1 Internet Gateway
      - 1 Route table with private subnet association.
      - 1 Route table with management subnet association, 1 default route with target to Internet Gateway.
      - 1 Route table with gwlb subnet association.
      - 1 Route table with transit gateway subnet association, and 1 default with with target to Gateway Load Balancer Endpoint.
  - Three FortiGate-VM instances with 2 NICs each: port1 on management subnet and port2 on private subnet, one instance per AZ.
    - No public IP is assigned to FortiGate port1 in this template.
    - port2 will be in its own FG-traffic vdom.
    - A geneve interface will be created base on port2 during bootstrap and this will be the interface where traffic will received from the Gateway Load Balancer.
  - Two Network Security Group rules: one for external, one for internal.
  - One Gateway Load Balancer with targets to FortiGates in each of the three AZs.
* Transit Gateway and spoke/customer VPC resources are not created by this template and must be integrated manually.


## Topology overview
* FortiGate Security VPC (10.1.0.0/24)
  - management-az1 (10.1.0.0/28)
  - private-az1  (10.1.0.16/28)
  - transit-az1  (10.1.0.32/28)
  - gwlb-az1     (10.1.0.48/28)
  - management-az2 (10.1.0.64/28)
  - private-az2  (10.1.0.80/28)
  - transit-az2  (10.1.0.96/28)
  - gwlb-az2     (10.1.0.112/28)
  - management-az3 (10.1.0.128/28)
  - private-az3  (10.1.0.144/28)
  - transit-az3  (10.1.0.160/28)
  - gwlb-az3     (10.1.0.176/28)

FortiGate VM(s) are deployed in Security VPC on both management and private subnet across three AZs.
Transit Gateway and spoke/customer VPC integration is out of scope of this template and should be configured manually.

![gwlb-transit-architecture](./aws-gwlb-transit.png?raw=true "GWLB Transit Architecture")


## Deployment
To deploy the FortiGate-VM(s) to AWS:
1. Clone the repository.
2. Customize variables in the `terraform.tfvars.example` and `variables.tf` file as needed.  And rename `terraform.tfvars.example` to `terraform.tfvars`.
> [!NOTE]    
> In the license_format variable, there are two different choices.   
> Either token or file.  Token is FortiFlex token, and file is FortiGate-VM license file.
3. Initialize the providers and modules:
   ```sh
   $ cd XXXXX
   $ terraform init
    ```
4. Submit the Terraform plan:
   ```sh
   $ terraform plan
   ```
5. Verify output.
6. Confirm and apply the plan:
   ```sh
   $ terraform apply
   ```
7. If output is satisfactory, type `yes`.

Output will include the information necessary to log in to the FortiGate-VM instances:
```sh
Outputs:

FGT1-Password = <FGT 1 Password>
FGT2-Password = <FGT 2 Password>
FGT3-Password = <FGT 3 Password>
FGTVPC = <FGT Security VPC>
LoadBalancerPrivateIP = <Private Load Balancer IP>
LoadBalancerPrivateIP2 = <Private Load Balancer IP>
LoadBalancerPrivateIP3 = <Private Load Balancer IP>
Username = <FGT Username>

```

## Manual Integration to Existing TGW and Spoke VPCs
Use the following sequence after this template is deployed.

1. Create TGW attachment for FortiGate Security VPC
- Use your existing Transit Gateway.
- Attach the Security VPC (FGTVPC output) using transit subnets in all three AZs:
  - transit-az1 (10.1.0.32/28)
  - transit-az2 (10.1.0.96/28)
  - transit-az3 (10.1.0.160/28)
- Enable appliance mode on this attachment to preserve symmetric inspection flow.

2. Create or select TGW route tables
- Security route table: associated with the FortiGate Security VPC attachment.
- Spoke route table: associated with spoke VPC attachments.

3. Associate and propagate TGW attachments
- Associate the Security VPC attachment to the Security route table.
- Associate each spoke VPC attachment to the Spoke route table.
- Enable propagation:
  - Spoke attachments propagating into Security route table.
  - Security attachment propagating into Spoke route table.

4. Add TGW static routes
- In Spoke route table, add default route 0.0.0.0/0 to Security VPC attachment if you want centralized egress inspection.
- In Security route table, add spoke CIDR routes to each corresponding spoke attachment.

5. Update Security VPC route table in this deployment
- In route table fgtvm-gwlb-rt, add routes for each spoke CIDR pointing to the existing TGW.
- Keep route table fgtvm-tgw-rt default route 0.0.0.0/0 to GWLB endpoint for return traffic from TGW subnets.

6. Update each spoke VPC route tables
- Private/application subnets: route inspected destinations (or default route) to TGW, based on your policy.
- Edge ingress routing (if publishing inbound services): configure gateway route table to send protected subnet prefixes to local GWLB endpoint.

7. Validate data path
- From one spoke workload to another spoke workload, verify traffic passes through FortiGate and returns symmetrically.
- Validate north-south internet path if centralized egress is enabled.
- Confirm no asymmetric routing between TGW route tables and VPC route tables.

Recommended checks
- TGW attachment state is available for Security VPC and all spokes.
- Appliance mode is enabled on Security VPC TGW attachment.
- Security VPC route table fgtvm-gwlb-rt contains all spoke CIDR routes via TGW.
- Spoke route tables point inspected traffic to TGW as intended.

## Destroy the instance
To destroy the instance, use the command:
```sh
$ terraform destroy
```

# Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/fortigate-terraform-deploy/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License
[License](https://github.com/fortinet/fortigate-terraform-deploy/blob/master/LICENSE) © Fortinet Technologies. All rights reserved.
