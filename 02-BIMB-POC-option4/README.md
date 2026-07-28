# BIMB POC Option 4 - Dual FortiGate Cluster Deployment

## Architecture Overview

This Terraform configuration deploys a dual FortiGate cluster architecture in AWS with:

- **Single VPC**: Centralized Inspection VPC for both North-South and East-West traffic
- **North-South Cluster**: 2 FortiGate instances with dedicated GWLB (NO GWLB endpoints)
- **East-West Cluster**: 2 FortiGate instances with dedicated GWLB and GWLB endpoints
- **High Availability**: Active-Active configuration across 2 Availability Zones

## Architecture Components

### Network Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│          Centralized Inspection VPC: NS & EW                   │
│                                                                 │
│  ┌───────────────────────┐      ┌───────────────────────────┐ │
│  │  North-South Cluster  │      │   East-West Cluster        │ │
│  │                       │      │                            │ │
│  │  ┌────────┐           │      │  ┌────────┐  ┌─────────┐  │ │
│  │  │ NS-FGT1│  AZ1      │      │  │ EW-FGT1│  │ GWLB EP │  │ │
│  │  │ (Mgmt) │           │      │  │ (Mgmt) │  │   AZ1   │  │ │
│  │  │(Private)│          │      │  │(Private)│ │ (TGW)   │  │ │
│  │  └────────┘           │      │  └────────┘  └─────────┘  │ │
│  │                       │      │                            │ │
│  │  ┌────────┐           │      │  ┌────────┐  ┌─────────┐  │ │
│  │  │ NS-FGT2│  AZ2      │      │  │ EW-FGT2│  │ GWLB EP │  │ │
│  │  │ (Mgmt) │           │      │  │ (Mgmt) │  │   AZ2   │  │ │
│  │  │(Private)│          │      │  │(Private)│ │ (TGW)   │  │ │
│  │  └────────┘           │      │  └────────┘  └─────────┘  │ │
│  │       │               │      │       │                    │ │
│  │    NS-GWLB            │      │    EW-GWLB                │ │
│  │  (No Endpoint)        │      │  (With Endpoint)          │ │
│  └───────────────────────┘      └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### North-South Cluster
- **Purpose**: Internet-bound traffic inspection
- **Configuration**: 
  - 2 FortiGate instances (AZ1 and AZ2)
  - Dedicated Gateway Load Balancer
  - NO GWLB endpoints (direct GWLB attachment)
  - Management and Private subnets per AZ

### East-West Cluster
- **Purpose**: Inter-VPC/on-premises traffic inspection
- **Configuration**:
  - 2 FortiGate instances (AZ1 and AZ2)
  - Dedicated Gateway Load Balancer
  - GWLB endpoints for TGW attachment
  - Management, Private, Transit (TGW), and GWLB subnets per AZ

## Subnet Layout

### VPC: 172.21.168.0/24

#### North-South Cluster:
- **AZ1**:
  - NS-Mgmt: 172.21.168.0/28
  - NS-Private: 172.21.168.16/28
- **AZ2**:
  - NS-Mgmt: 172.21.168.32/28
  - NS-Private: 172.21.168.48/28

#### East-West Cluster:
- **AZ1**:
  - EW-Mgmt: 172.21.168.64/28
  - EW-Private: 172.21.168.80/28
  - EW-Transit: 172.21.168.96/28
  - EW-GWLB: 172.21.168.112/28
- **AZ2**:
  - EW-Mgmt: 172.21.168.128/28
  - EW-Private: 172.21.168.144/28
  - EW-Transit: 172.21.168.160/28
  - EW-GWLB: 172.21.168.176/28

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **FortiGate Licenses** (if using BYOL):
   - license-ns1.lic (North-South FGT1)
   - license-ns2.lic (North-South FGT2)
   - license-ew1.lic (East-West FGT1)
   - license-ew2.lic (East-West FGT2)

## Deployment Steps

### 1. Prepare Configuration

```bash
# Clone or navigate to the repository
cd 02-BIMB-POC-option4

# Copy the example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vi terraform.tfvars
```

### 2. Configure Variables

Edit `terraform.tfvars` and update:
- AWS credentials (access_key, secret_key)
- Region and availability zones
- Instance type and architecture
- License files (if using BYOL)

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Deployment

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

Review the plan and type `yes` to confirm deployment.

## Post-Deployment

### Access FortiGate Instances

1. **Retrieve passwords**:
   ```bash
   terraform output FGT-NS1-Password
   terraform output FGT-NS2-Password
   terraform output FGT-EW1-Password
   terraform output FGT-EW2-Password
   ```

2. **Get Management IPs**:
   ```bash
   terraform output FGT-NS1-Management-IP
   terraform output FGT-NS2-Management-IP
   terraform output FGT-EW1-Management-IP
   terraform output FGT-EW2-Management-IP
   ```

3. **Access FortiGate**:
   - Username: `admin`
   - Password: Instance ID (from output above)
   - URL: `https://<Management-IP>:443`

### Retrieve SSH Private Key

```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw SSH-PrivateKey-SecretARN) \
  --query SecretString \
  --output text > fortigate-key.pem

chmod 400 fortigate-key.pem
```

### Key Outputs

After successful deployment, the following outputs are available:

#### North-South Cluster:
- `NS-GWLB-ARN`: ARN of the NS Gateway Load Balancer
- `NS-GWLB-Service-Name`: Service name for NS GWLB (can be used by other VPCs)
- `FGT-NS1-Management-IP`: Management IP for NS FortiGate 1
- `FGT-NS2-Management-IP`: Management IP for NS FortiGate 2

#### East-West Cluster:
- `EW-GWLB-ARN`: ARN of the EW Gateway Load Balancer
- `EW-GWLB-Service-Name`: Service name for EW GWLB
- `EW-GWLB-Endpoint-ID`: GWLB Endpoint ID for TGW attachment
- `EW-LoadBalancer-PrivateIP-AZ1`: GWLB endpoint IP in AZ1
- `EW-LoadBalancer-PrivateIP-AZ2`: GWLB endpoint IP in AZ2

## Configuration Details

### FortiGate Configuration

#### North-South Cluster (NS1 & NS2):
- Multi-VDOM mode enabled
- No GENEVE tunnel (direct GWLB attachment without endpoints)
- Simple firewall policy on port2 allowing all traffic
- Health probe response enabled on port2
- Used for internet-bound traffic inspection

#### East-West Cluster (EW1 & EW2):
- Multi-VDOM mode enabled
- **Cross-AZ GENEVE configuration**: Each FortiGate has 2 GENEVE tunnels (one per AZ endpoint)
  - `awsgeneve`: Tunnel to AZ1 GWLB endpoint
  - `awsgeneve2`: Tunnel to AZ2 GWLB endpoint
- Zone configuration (`awszone`) containing both GENEVE interfaces
- Firewall policy on zone interface allowing all traffic
- Policy-based routing for symmetric traffic flow
- Static routes for traffic steering
- Used for inter-VPC/on-premises traffic inspection

### Security

- **KMS Encryption**: All EBS volumes encrypted with customer-managed KMS key
- **SSH Keys**: Automatically generated and stored in AWS Secrets Manager
- **Security Groups**:
  - Management: Allows SSH (22), HTTPS (443), Admin (8443)
  - Private: Allows all traffic for inspection

## Integration

### Transit Gateway Integration (East-West)

To use the East-West cluster with Transit Gateway:

1. **Create TGW Attachment**:
   - Attach to EW Transit subnets (ew-transit-az1, ew-transit-az2)

2. **Configure TGW Route Tables**:
   - Point traffic to GWLB endpoint IPs
   - Use outputs: `EW-LoadBalancer-PrivateIP-AZ1` and `EW-LoadBalancer-PrivateIP-AZ2`

### VPC Endpoint Service (North-South)

To use the North-South GWLB from other VPCs:

1. **Get Service Name**: Use output `NS-GWLB-Service-Name`
2. **Create VPC Endpoint**: In target VPC, create endpoint using the service name
3. **Configure Route Tables**: Route traffic to the endpoint

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` to confirm deletion.

## Important Notes

1. **Cost Consideration**: Running 4 FortiGate instances and 2 GWLBs will incur significant AWS costs
2. **License Management**: Ensure you have valid licenses if using BYOL mode
3. **High Availability**: This configuration provides AZ-level redundancy
4. **Instance Type**: Default is c6g.xlarge (ARM). Change if using x86 instances
5. **Cluster Independence**: NS and EW clusters operate independently with separate GWLBs
6. **Cross-AZ GWLB Pattern**: EW cluster uses cross-AZ GENEVE configuration where each FortiGate maintains tunnels to both AZ endpoints for symmetric traffic flow and resilience
7. **GWLB Endpoint Integration**: Only the EW cluster has GWLB endpoints for TGW attachment. NS cluster uses direct GWLB attachment without endpoints

## Troubleshooting

### FortiGate Not Accessible
- Check security group rules
- Verify instance is running
- Check VPC DNS settings

### GWLB Health Checks Failing
- Verify FortiGate probe-response is enabled
- Check port2 configuration on FortiGates
- Review FortiGate system logs

### GENEVE Tunnel Not Establishing (EW Cluster)
- Verify GWLB endpoints are created in BOTH AZs
- Check both endpoint IPs in FortiGate configuration (awsgeneve and awsgeneve2)
- Review FortiGate GENEVE interface status: `diagnose sys geneve list`
- Verify zone configuration includes both GENEVE interfaces
- Check policy-based routing configuration

## Support

For issues related to:
- **Terraform**: Check Terraform documentation
- **FortiGate**: Consult Fortinet documentation or support
- **AWS Services**: Refer to AWS documentation

## Version Information

- Terraform >= 1.0
- AWS Provider >= 5.0
- FortiGate OS: 7.6.7
- TLS Provider >= 4.0

## License

This configuration is for BIMB POC purposes. Ensure compliance with FortiGate licensing requirements.
