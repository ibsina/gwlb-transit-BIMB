# GWLB Integration Pattern - BIMB POC Option 4

## Overview

This deployment follows the Fortinet GWLB Cross-AZ integration pattern as referenced from:
https://github.com/ibsina/fortigate-terraform-deploy/tree/main/aws/8.0/gwlb-crossaz

## Architecture Patterns

### North-South Cluster (No GWLB Endpoints)

**Purpose**: Internet-bound traffic inspection

**GWLB Configuration**:
- GWLB deployed across 2 AZs
- NO VPC endpoints created
- Direct GWLB target attachment to FortiGate private interfaces

**FortiGate Configuration**:
- Port2 in FG-traffic VDOM
- Simple firewall policy on port2 (no GENEVE tunnels)
- Health probe response on port2 (port 8008)
- No special routing required

**Traffic Flow**:
```
Internet <-> IGW <-> GWLB <-> FortiGate Port2 <-> GWLB <-> Target
```

### East-West Cluster (With GWLB Endpoints - Cross-AZ Pattern)

**Purpose**: Inter-VPC and on-premises traffic inspection via Transit Gateway

**GWLB Configuration**:
- GWLB deployed across 2 AZs
- VPC endpoints created in BOTH AZs
- GWLB endpoints in dedicated subnets (ew-gwlb-az1, ew-gwlb-az2)

**FortiGate Configuration** (Each FortiGate has):
- Port2 in FG-traffic VDOM
- **2 GENEVE tunnels** (cross-AZ pattern):
  - `awsgeneve`: Points to AZ1 GWLB endpoint IP
  - `awsgeneve2`: Points to AZ2 GWLB endpoint IP
- **Zone** (`awszone`): Contains both GENEVE interfaces
- **Firewall policy**: Applied to zone (covers both tunnels)
- **Policy-based routing**: Ensures symmetric traffic flow
  - Traffic arriving on awsgeneve returns via awsgeneve
  - Traffic arriving on awsgeneve2 returns via awsgeneve2
- **Static routes**: Default routes via GENEVE tunnels + route to other AZ subnet

**Why Cross-AZ Pattern?**:
- **Resilience**: Traffic can flow through either AZ's endpoint
- **Symmetric routing**: Traffic returns via the same endpoint it arrived
- **AZ independence**: Each FortiGate can handle traffic from both AZs
- **No single point of failure**: If one endpoint fails, traffic can still flow

**Traffic Flow**:
```
Spoke VPC <-> TGW <-> Transit Subnet <-> GWLB Endpoint (AZ1 or AZ2)
                                            |
                                            v
                                    GENEVE to FortiGate
                                            |
                                            v
                                    FortiGate inspection
                                            |
                                            v
                                    GENEVE back to same endpoint
                                            |
                                            v
                      GWLB Endpoint <-> Transit Subnet <-> TGW <-> Destination
```

## Configuration Details

### GENEVE Tunnel Configuration

```
config system geneve
edit "awsgeneve"
  set interface "port2"
  set type ppp
  set remote-ip <AZ1_ENDPOINT_IP>
next
edit "awsgeneve2"
  set interface "port2"
  set type ppp
  set remote-ip <AZ2_ENDPOINT_IP>
next
end
```

### Zone Configuration

```
config system zone
edit awszone
  set interface awsgeneve awsgeneve2
next
end
```

### Policy-Based Routing (Critical for Symmetric Flow)

```
config router policy
edit 1
  set input-device "awsgeneve"
  set src "0.0.0.0/0.0.0.0"
  set dst "0.0.0.0/0.0.0.0"
  set output-device "awsgeneve"
next
edit 2
  set input-device "awsgeneve2"
  set src "0.0.0.0/0.0.0.0"
  set dst "0.0.0.0/0.0.0.0"
  set output-device "awsgeneve2"
next
end
```

### Static Routing

```
config router static
edit 1
  set device awsgeneve      # Default route via GENEVE 1
next
edit 2
  set device awsgeneve2     # Default route via GENEVE 2
next
edit 3
  set device port2
  set dst <OTHER_AZ_SUBNET>  # Route to peer AZ private subnet
  set gateway <LOCAL_GATEWAY>
next
end
```

## Terraform Variables Used

### For EW Cluster FortiGates:
```hcl
templatefile("fgtvm-ew1.conf", {
  adminsport  = "443"
  dst         = var.ew_privatecidraz2        # AZ2 private subnet
  gateway     = cidrhost(var.ew_privatecidraz1, 1)  # AZ1 gateway
  endpointip  = <AZ1_GWLB_ENDPOINT_IP>
  endpointip2 = <AZ2_GWLB_ENDPOINT_IP>
})
```

### For NS Cluster FortiGates:
```hcl
templatefile("fgtvm-ns1.conf", {
  adminsport = "443"
  # No GENEVE-related variables needed
})
```

## Endpoint IP Discovery

GWLB endpoint IPs are dynamically discovered using AWS data sources:

```hcl
data "aws_network_interface" "ew_vpcendpointip_az1" {
  depends_on = [aws_vpc_endpoint.ew_gwlbendpoint]
  filter {
    name   = "vpc-id"
    values = [aws_vpc.fgtvm-vpc.id]
  }
  filter {
    name   = "status"
    values = ["in-use"]
  }
  filter {
    name   = "description"
    values = ["*ELB*"]
  }
  filter {
    name   = "availability-zone"
    values = [var.az1]
  }
}
```

## Verification Commands

### Check GENEVE Tunnels (EW Cluster)
```bash
# SSH to FortiGate
diagnose sys geneve list

# Expected output: Two GENEVE tunnels (awsgeneve, awsgeneve2) in "up" state
```

### Check Zone Configuration
```bash
show system zone
# Should show awszone with both geneve interfaces
```

### Check Routing
```bash
get router info routing-table all
get router info policy
```

### Verify Traffic Flow
```bash
diagnose sniffer packet awsgeneve
diagnose sniffer packet awsgeneve2
```

## Common Issues and Solutions

### Issue: GENEVE tunnels not coming up
**Solution**: 
- Verify GWLB endpoints created in both AZs
- Check endpoint IPs match FortiGate configuration
- Ensure port2 security group allows all traffic

### Issue: Asymmetric routing
**Solution**:
- Verify policy-based routing is configured
- Check that both GENEVE tunnels are in routing table
- Confirm zone includes both interfaces

### Issue: Health checks failing
**Solution**:
- Verify probe-response mode is set to http-probe
- Check port2 allows probe-response access
- Ensure FortiGate is in correct VDOM

## Reference Architecture

This implementation is based on Fortinet's official GWLB cross-AZ pattern which provides:
- High availability across multiple AZs
- Symmetric traffic flow
- Resilience to single AZ failures
- Simplified firewall policy management through zones

## Additional Resources

- [Fortinet GWLB Cross-AZ Example](https://github.com/ibsina/fortigate-terraform-deploy/tree/main/aws/8.0/gwlb-crossaz)
- [AWS GWLB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/gateway/)
- [FortiGate GENEVE Configuration](https://docs.fortinet.com/document/fortigate/latest/administration-guide/910635/geneve)
