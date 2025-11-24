# AWS Neptune Audit Logging with IBM Guardium Data Protection

This example demonstrates how to enable audit logging for AWS Neptune and integrate it with IBM Guardium Data Protection using the Universal Connector.

## Overview

This Terraform configuration:
- Creates or modifies a Neptune cluster parameter group to enable audit logging (`neptune_enable_audit_log = 1`)
- Automatically attaches the parameter group to your Neptune cluster
- Enables "Audit log" in CloudWatch log exports
- Configures CloudWatch Logs integration for Neptune audit logs
- Sets up IBM Guardium Universal Connector to monitor Neptune audit events
- Supports both default and custom parameter groups

## Prerequisites

1. **AWS Neptune Cluster**: An existing Neptune cluster that you want to monitor
2. **IBM Guardium Data Protection**: A running Guardium instance with:
   - OAuth client registered (use `grdapi register_oauth_client`)
   - AWS credentials configured in Guardium
   - SSH access configured
3. **Terraform**: Version 0.13 or later
4. **AWS Credentials**: Configured with appropriate permissions to:
   - Manage Neptune parameter groups
   - Access CloudWatch Logs
   - Read Neptune cluster metadata

## Neptune Audit Logging

Neptune audit logging captures:
- **Gremlin queries**: Apache TinkerPop Gremlin graph traversal queries
- **SPARQL queries**: W3C SPARQL queries for RDF data
- Connection events and authentication attempts

Audit logs are automatically sent to CloudWatch Logs at:
```
/aws/neptune/<cluster-name>/audit
```

## Usage

1. **Copy the example configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your specific values:
   - Neptune cluster identifier
   - Neptune endpoint (optional)
   - Guardium server details
   - AWS credentials name in Guardium
   - OAuth client credentials

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region where resources will be created | `string` | `"us-east-1"` | no |
| neptune_cluster_identifier | Neptune cluster identifier to be monitored | `string` | n/a | yes |
| tags | Map of tags to apply to resources | `map(string)` | n/a | yes |
| udc_aws_credential | Name of AWS credential defined in Guardium | `string` | n/a | yes |
| gdp_client_id | Client ID used when running grdapi register_oauth_client | `string` | n/a | yes |
| gdp_client_secret | Client secret from output of grdapi register_oauth_client | `string` | n/a | yes |
| gdp_server | Hostname/IP address of Guardium Central Manager | `string` | n/a | yes |
| gdp_port | Port of Guardium Central Manager | `string` | `"8443"` | no |
| gdp_username | Username of Guardium Web UI user | `string` | n/a | yes |
| gdp_password | Password of Guardium Web UI user | `string` | n/a | yes |
| gdp_ssh_username | Guardium OS user with SSH access | `string` | n/a | yes |
| gdp_ssh_privatekeypath | Private SSH key to connect to Guardium OS | `string` | n/a | yes |
| gdp_mu_host | Comma separated list of Guardium Managed Units to deploy profile | `string` | n/a | yes |
| enable_universal_connector | Whether to enable the universal connector | `bool` | `true` | no |
| csv_start_position | Start position for UDC | `string` | `"end"` | no |
| csv_interval | Polling interval for UDC | `string` | `"5"` | no |
| csv_event_filter | UDC Event filters | `string` | `""` | no |
| neptune_endpoint | Neptune cluster endpoint (optional - will be fetched automatically if not provided) | `string` | `""` | no |
| use_aws_bundled_ca | Whether to use the AWS bundled CA certificates for Neptune connection | `bool` | `true` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `udc_name` | Name of the Universal Connector |
| `parameter_group_name` | Name of the Neptune parameter group |
| `cloudwatch_log_group` | CloudWatch Log Group for audit logs |
| `aws_region` | AWS region where resources are deployed |
| `aws_account_id` | AWS account ID |
| `neptune_cluster_identifier` | Neptune cluster identifier |
| `neptune_cluster_endpoint` | Neptune cluster endpoint |

## Important Notes

### Parameter Group Behavior

- **Default Parameter Group**: If your Neptune cluster uses the default parameter group, this module creates a new custom parameter group
- **Custom Parameter Group**: If your cluster already uses a custom parameter group, the module modifies it to enable audit logging

### Automatic Configuration

The module automatically:
- Attaches the created parameter group to your Neptune cluster
- Enables "Audit log" in CloudWatch log exports
- Applies changes immediately
- Reboots the cluster if needed for the `neptune_enable_audit_log` parameter to take effect

Plan for a maintenance window accordingly as the cluster may be rebooted during the apply process.

### Importing Existing Parameter Groups

To import an existing parameter group:
```bash
terraform import module.datastore-audit_aws-neptune-audit.aws_neptune_cluster_parameter_group.guardium <parameter-group-name>
```

### CloudWatch Logs

Neptune automatically creates the CloudWatch Log Group when audit logging is enabled. No manual log group creation is needed.

## Limitations

Based on the Neptune-Guardium Logstash filter documentation:

1. **SourceProgram**: Not available in Neptune audit logs (field left blank)
2. **OS User**: Not available in Neptune audit logs
3. **Client HostName**: Not available in Neptune audit logs
4. **Error Logs**: Neptune audit logs don't include error logs, so SQL_ERROR and LOGIN_FAILED reports won't show Neptune errors

## Supported Neptune Versions

- Neptune 1.1 and above
- Supports both Gremlin and SPARQL query languages

## Guardium Support

- **Guardium Data Protection**: 11.4 and above
- **Guardium Data Security Center SaaS**: 1.0

## Troubleshooting

### Audit Logs Not Appearing

1. Verify the parameter group is attached to your Neptune cluster
2. Confirm the cluster has been rebooted after parameter change
3. Check CloudWatch Logs for the log group `/aws/neptune/<cluster-name>/audit`
4. Verify AWS credentials in Guardium have CloudWatch read permissions

### Universal Connector Issues

1. Verify OAuth client is properly registered in Guardium
2. Check SSH connectivity to Guardium server
3. Confirm AWS credential name matches what's configured in Guardium
4. Review Guardium logs for connection errors

## Security Considerations

- Store sensitive values (passwords, secrets) securely using Terraform variables or secret management tools
- Use IAM roles with least privilege for AWS access
- Regularly rotate OAuth client secrets
- Monitor CloudWatch Logs for unauthorized access attempts

## References

- [Neptune Audit Logging Documentation](https://docs.aws.amazon.com/neptune/latest/userguide/auditing.html)
- [IBM Guardium Universal Connector](https://github.com/IBM/universal-connectors)
- [Neptune-Guardium Filter Plugin](https://github.com/IBM/universal-connectors/tree/main/filter-plugin/logstash-filter-neptune-aws-guardium)

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0
