# AWS Neptune Audit Configuration

This module configures audit logging for AWS Neptune clusters with IBM Guardium Data Protection. It enables Neptune audit logging through cluster parameter groups and configures log collection via CloudWatch.

## Prerequisites

Before using this module, you need to:

1. Have an existing Neptune cluster
2. Have Guardium set up with appropriate credentials
3. **Important**: You must initialize Terraform and import the existing parameter group before applying this module (if using a custom parameter group)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | ~> 6.0 |
| guardium-data-protection | >= 1.0.0 |
| gdp-middleware-helper | >= 1.0.0 |

### Parameter Group Import Process

This module automatically detects whether your Neptune cluster uses a default or custom parameter group:

- **Default Parameter Group**: If your cluster uses the default parameter group (e.g., `default.neptune1`), the module creates a new custom parameter group
- **Custom Parameter Group**: If your cluster already uses a custom parameter group, the module modifies it to enable audit logging

To ensure Terraform manages your Neptune cluster correctly when using a custom parameter group:

1. Initialize Terraform in your working directory:
   ```bash
   terraform init
   ```
   
2. Identify your current parameter group:
   ```bash
   aws neptune describe-db-clusters \
   --db-cluster-identifier your-neptune-cluster \
   --region your-region \
   --query "DBClusters[0].DBClusterParameterGroup" \
   --output text
   ```

3. Import your current parameter group (only if it's a custom parameter group):
   ```bash
   terraform import module.datastore-audit_aws-neptune-audit.aws_neptune_cluster_parameter_group.guardium <your-parameter-group-name>
   ```

**Note**: Skipping the import step for custom parameter groups will cause Terraform to attempt creating a new parameter group, which may fail or cause unexpected behavior.

## Features

- Configures Neptune cluster for audit logging
- Enables `neptune_enable_audit_log` parameter
- Supports both Gremlin and SPARQL query logging
- Integrates with Guardium for audit data collection via CloudWatch
- Automatic parameter group detection and management

## Usage

### Using a tfvars File

Create a `terraform.tfvars` file with your configuration. See [terraform.tfvars.example](./terraform.tfvars.example) for an example with available options and detailed comments.

Then run:

```bash
# Import existing resources (if using custom parameter group)
# See the "Parameter Group Import Process" section above

# Plan the changes
terraform plan -var-file=terraform.tfvars

# Apply the changes
terraform apply -var-file=terraform.tfvars
```

**Important**: This module automatically:
1. Creates or modifies the Neptune cluster parameter group to enable audit logging
2. Attaches the parameter group to your Neptune cluster
3. Enables "Audit log" in CloudWatch log exports
4. The changes are applied immediately, and the cluster will be rebooted automatically if needed for the parameter to take effect

## Provider Configuration

This module requires both the AWS provider and the Guardium Data Protection provider.
The providers are configured automatically using the variables you provide:

```hcl
provider "aws" {
  region = var.aws_region
}

provider "guardium-data-protection" {
  host = var.gdp_server
  port = var.gdp_port
}
```

Make sure your Terraform environment has access to the Guardium Data Protection provider, which is sourced from:
```
IBM/guardium-data-protection
```

## Neptune Audit Logging

Neptune audit logging captures:
- **Gremlin queries**: Apache TinkerPop Gremlin graph traversal queries
- **SPARQL queries**: W3C SPARQL queries for RDF data
- Connection events and authentication attempts

### CloudWatch Integration

This module configures CloudWatch integration for Neptune auditing. The audit logs are automatically sent to a CloudWatch log group with the format:

```
/aws/neptune/<neptune_cluster_identifier>/audit
```

Guardium is configured to collect and analyze these logs through the Universal Connector.

## Supported Neptune Versions

- Neptune 1.1 and above
- Supports both Gremlin and SPARQL query languages

## Guardium Support

- **Guardium Data Protection**: 11.4 and above
- **Guardium Data Security Center SaaS**: 1.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region | string | `"us-east-1"` | no |
| neptune_cluster_identifier | Neptune cluster identifier to be monitored | string | n/a | yes |
| neptune_endpoint | Neptune cluster endpoint (optional - will be fetched automatically if not provided) | string | `""` | no |
| tags | Map of tags to apply to resources | map(string) | n/a | yes |
| udc_aws_credential | Name of AWS credential defined in Guardium | string | n/a | yes |
| gdp_client_secret | Client secret from output of grdapi register_oauth_client | string | n/a | yes |
| gdp_client_id | Client id used when running grdapi register_oauth_client | string | n/a | yes |
| gdp_server | Hostname/IP address of Guardium Central Manager | string | n/a | yes |
| gdp_port | Port of Guardium Central Manager | string | `"8443"` | no |
| gdp_username | Username of Guardium Web UI user | string | n/a | yes |
| gdp_password | Password of Guardium Web UI user | string | n/a | yes |
| gdp_ssh_username | Guardium OS user with SSH access | string | n/a | yes |
| gdp_ssh_privatekeypath | Private SSH key to connect to Guardium OS with ssh username | string | n/a | yes |
| gdp_mu_host | Comma separated list of Guardium Managed Units to deploy profile | string | n/a | yes |
| enable_universal_connector | Whether to enable the universal connector module. Set to false to completely disable the universal connector for a run. | bool | `true` | no |
| csv_start_position | Start position for UDC | string | `"end"` | no |
| csv_interval | Polling interval for UDC | string | `"5"` | no |
| csv_event_filter | UDC Event filters | string | `""` | no |
| use_aws_bundled_ca | Whether to use AWS bundled CA certificates for Neptune connections | bool | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| profile_csv | Universal Connector profile CSV |
| udc_name | Name of the Universal Connector |
| parameter_group_name | Name of the Neptune cluster parameter group |
| cloudwatch_log_group | Name of the CloudWatch Log Group for audit logs |
| aws_region | AWS region where resources are deployed |
| aws_account_id | AWS account ID |
| neptune_cluster_identifier | Neptune cluster identifier |
| neptune_cluster_endpoint | Neptune cluster endpoint |

## Important Notes

### Automatic Configuration

The module automatically handles the complete setup:
- Attaches the created parameter group to your Neptune cluster
- Enables "Audit log" in CloudWatch log exports
- Applies changes immediately
- Waits for the cluster to become available
- Reboots the cluster if needed for the `neptune_enable_audit_log` parameter to take effect

Plan for a maintenance window accordingly as the cluster may be rebooted during the apply process.

### Limitations

Based on the Neptune-Guardium Logstash filter documentation:

1. **SourceProgram**: Not available in Neptune audit logs (field left blank in Guardium)
2. **OS User**: Not available in Neptune audit logs
3. **Client HostName**: Not available in Neptune audit logs
4. **Error Logs**: Neptune audit logs don't include error logs, so SQL_ERROR and LOGIN_FAILED reports won't show Neptune errors. Invalid queries will appear in Guardium logs instead of records.

### Security Considerations

- Store sensitive values (passwords, secrets) securely using Terraform variables or secret management tools
- Use IAM roles with least privilege for AWS access
- Regularly rotate OAuth client secrets
- Monitor CloudWatch Logs for unauthorized access attempts
- The `neptune_enable_audit_log` parameter is set to `1` to enable audit logging

## Example

See the [examples/aws-neptune-audit](../../examples/aws-neptune-audit) directory for a complete example of how to use this module.

## References

- [Neptune Audit Logging Documentation](https://docs.aws.amazon.com/neptune/latest/userguide/auditing.html)
- [IBM Guardium Universal Connector](https://github.com/IBM/universal-connectors)
- [Neptune-Guardium Filter Plugin](https://github.com/IBM/universal-connectors/tree/main/filter-plugin/logstash-filter-neptune-aws-guardium)

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0