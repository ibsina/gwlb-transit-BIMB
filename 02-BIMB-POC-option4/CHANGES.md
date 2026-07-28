# Change Summary - GWLB Integration Update

## Date: 2026-07-28

## Objective
Update the BIMB POC Option 4 Terraform configuration to align with Fortinet's official GWLB Cross-AZ integration pattern as referenced from:
https://github.com/ibsina/fortigate-terraform-deploy/tree/main/aws/8.0/gwlb-crossaz

## Key Changes

### 1. East-West Cluster FortiGate Configurations (fgtvm-ew1.conf, fgtvm-ew2.conf)

**Before**: Single GENEVE tunnel per FortiGate
```
config system geneve
edit "awsgeneve"
  set interface "port2"
  set remote-ip ${endpointip}
next
end
```

**After**: Cross-AZ pattern with 2 GENEVE tunnels per FortiGate
```
config system geneve
edit "awsgeneve"
  set interface "port2"
  set type ppp
  set remote-ip ${endpointip}
next
edit "awsgeneve2"
  set interface "port2"
  set type ppp
  set remote-ip ${endpointip2}
next
end
```

**Added**: Zone configuration
```
config system zone
edit awszone
  set interface awsgeneve awsgeneve2
next
end
```

**Added**: Policy-based routing for symmetric traffic flow
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

**Updated**: Firewall policy to use zone instead of single interface
```
# Before: srcintf "awsgeneve", dstintf "awsgeneve"
# After: srcintf "awszone", dstintf "awszone"
```

**Updated**: Static routes to include both GENEVE tunnels
```
config router static
edit 1
  set device awsgeneve
next
edit 2
  set device awsgeneve2
next
edit 3
  set device port2
  set dst ${dst}          # Changed from ${cidr}
  set gateway ${gateway}
next
end
```

### 2. East-West Terraform Files (fgtvm-ew1.tf, fgtvm-ew2.tf)

**Updated templatefile variables**:
```hcl
# Before:
content = templatefile("${var.bootstrap-fgtvm-ew1}", {
  adminsport = "${var.adminsport}"
  cidr       = "${var.ew_privatecidraz2}"
  gateway    = cidrhost(var.ew_privatecidraz1, 1)
  endpointip = "${data.aws_network_interface.ew_vpcendpointip_az1.private_ip}"
})

# After:
content = templatefile("${var.bootstrap-fgtvm-ew1}", {
  adminsport  = "${var.adminsport}"
  dst         = var.ew_privatecidraz2        # Changed from cidr
  gateway     = cidrhost(var.ew_privatecidraz1, 1)
  endpointip  = "${data.aws_network_interface.ew_vpcendpointip_az1.private_ip}"
  endpointip2 = "${data.aws_network_interface.ew_vpcendpointip_az2.private_ip}"  # Added
})
```

### 3. GWLB Endpoint Configuration (network.tf)

**Before**: Single subnet (AZ1 only)
```hcl
resource "aws_vpc_endpoint" "ew_gwlbendpoint" {
  service_name      = aws_vpc_endpoint_service.ew_gwlbservice.service_name
  subnet_ids        = [aws_subnet.ew_gwlbsubnetaz1.id]
  vpc_endpoint_type = aws_vpc_endpoint_service.ew_gwlbservice.service_type
  vpc_id            = aws_vpc.fgtvm-vpc.id
}
```

**After**: Both subnets (AZ1 and AZ2 for cross-AZ support)
```hcl
resource "aws_vpc_endpoint" "ew_gwlbendpoint" {
  service_name      = aws_vpc_endpoint_service.ew_gwlbservice.service_name
  subnet_ids        = [aws_subnet.ew_gwlbsubnetaz1.id, aws_subnet.ew_gwlbsubnetaz2.id]
  vpc_endpoint_type = aws_vpc_endpoint_service.ew_gwlbservice.service_type
  vpc_id            = aws_vpc.fgtvm-vpc.id
}
```

### 4. North-South Cluster Simplification (fgtvm-ns1.conf, fgtvm-ns2.conf, fgtvm-ns1.tf, fgtvm-ns2.tf)

**Removed**: Unnecessary static routing (NS cluster doesn't use GWLB endpoints)
```
# Removed from config files:
config router static
edit 1
  set device port2
  set dst ${cidr}
  set gateway ${gateway}
next
end
```

**Simplified**: Terraform template variables (removed unused cidr/gateway)
```hcl
# Before:
content = templatefile("${var.bootstrap-fgtvm-ns1}", {
  adminsport = "${var.adminsport}"
  cidr       = "${var.ns_privatecidraz2}"
  gateway    = cidrhost(var.ns_privatecidraz1, 1)
})

# After:
content = templatefile("${var.bootstrap-fgtvm-ns1}", {
  adminsport = "${var.adminsport}"
})
```

### 5. Documentation Updates

**Added**: New comprehensive guide (GWLB-INTEGRATION.md)
- Detailed explanation of both deployment patterns
- GENEVE tunnel configuration examples
- Zone and policy-based routing details
- Traffic flow diagrams
- Verification commands
- Troubleshooting guide

**Updated**: README.md
- Enhanced FortiGate configuration descriptions
- Added cross-AZ GENEVE pattern explanation
- Updated troubleshooting section
- Added important notes about GWLB integration patterns

## Benefits of Cross-AZ Pattern

1. **High Availability**: Traffic can flow through either AZ's GWLB endpoint
2. **Symmetric Routing**: Policy-based routing ensures traffic returns via the same endpoint it arrived
3. **Resilience**: No single point of failure - if one endpoint fails, traffic continues via the other
4. **Load Distribution**: Both FortiGates can handle traffic from both AZs
5. **AZ Independence**: Each FortiGate maintains connections to both AZ endpoints

## Testing Recommendations

1. **Verify GENEVE Tunnels**: Check both tunnels are up on each FortiGate
   ```bash
   diagnose sys geneve list
   ```

2. **Test Symmetric Routing**: Verify traffic returns via same endpoint
   ```bash
   diagnose sniffer packet awsgeneve
   diagnose sniffer packet awsgeneve2
   ```

3. **Validate Zone Configuration**: Confirm zone includes both interfaces
   ```bash
   show system zone
   ```

4. **Check Policy-Based Routing**: Ensure routing policies are active
   ```bash
   get router info policy
   ```

5. **Health Check Validation**: Verify GWLB health checks passing
   - Check AWS GWLB target group health status
   - Verify FortiGate probe-response is working

## Files Modified

1. fgtvm-ew1.conf - Cross-AZ GENEVE configuration
2. fgtvm-ew2.conf - Cross-AZ GENEVE configuration
3. fgtvm-ew1.tf - Updated template variables
4. fgtvm-ew2.tf - Updated template variables
5. fgtvm-ns1.conf - Simplified (removed unused routes)
6. fgtvm-ns2.conf - Simplified (removed unused routes)
7. fgtvm-ns1.tf - Simplified template variables
8. fgtvm-ns2.tf - Simplified template variables
9. network.tf - GWLB endpoint spans both AZs
10. README.md - Updated documentation
11. GWLB-INTEGRATION.md - New comprehensive guide (created)
12. CHANGES.md - This file (created)

## Compatibility

- FortiOS: 6.4.4 and above (GENEVE support)
- Terraform: >= 1.0
- AWS Provider: >= 5.0
- Region: ap-southeast-1 (configurable)

## Next Steps

1. Review configuration changes
2. Update terraform.tfvars with your environment settings
3. Run `terraform plan` to preview changes
4. Deploy with `terraform apply`
5. Verify GENEVE tunnels and routing
6. Test traffic flow through both clusters
