# AWS MySQL RDS Audit Configuration

This module configures audit logging for MySQL RDS instances using Guardium. It enables the MariaDB Audit Plugin through an option group and configures log collection via CloudWatch.

## Prerequisites

Before using this module, you need to:

1. Have an existing MySQL RDS instance
2. Have Guardium set up with appropriate credentials
3. **Important**: You must initialize Terraform and import the existing parameter and option group before applying this module

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |
| guardium-data-protection | >= 0.0.4 |

### Option Group and Parameter Group Import Process

This module uses existing option group to enable the `MariaDB Audit Plugin` and existing parameter group.
To ensure Terraform manages your RDS instance correctly:

1. Initialize Terraform in your working directory:
   ```bash
   terraform init
   ```

2. Identify your current option group name:
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier your-mysql-instance \
     --region your-region \
     --query "DBInstances[0].OptionGroupMemberships[0].OptionGroupName" \
     --output text
   ```

3. Import the option group into Terraform state:
   ```bash
   terraform import module.common_rds-mariadb-mysql-parameter-group.aws_db_option_group.audit <your-option-group-name>
   ```

4. Identify your current parameter group:
   ```bash
   aws rds describe-db-instances \
   --db-instance-identifier your-mysql-instance \
   --region your-region \
   --query "DBInstances[0].DBParameterGroups[0].DBParameterGroupName" \
   --output text
   ```

5. If using a custom parameter group, import it as well:
   ```bash
   terraform import module.common_rds-mariadb-mysql-parameter-group.aws_db_parameter_group.mysql_param_group <your-parameter-group-name>
   ```

**Note**: Skipping the import step will cause Terraform to attempt creating a new parameter group, which may fail or cause unexpected behavior.

## Features

- Configures MySQL RDS for audit logging
- Configures audit events to capture (CONNECT, QUERY, etc.)
- Integrates with Guardium for audit data collection via CloudWatch

## Usage

### Using a tfvars File

Create a `defaults.tfvars` file with your configuration:

```hcl
# AWS Configuration
aws_region = "us-east-1"
mysql_rds_cluster_identifier = "your-mysql-instance"
mysql_major_version = "5.7"

# Guardium Configuration
udc_aws_credential = "aws-credential-name"
gdp_client_secret = "client-secret"
gdp_client_id = "client-id"
gdp_server = "guardium-server.example.com"
gdp_port = "8443"  # Optional, defaults to 8443
gdp_username = "guardium-user"
gdp_password = "guardium-password"
gdp_ssh_username = "guardium-ssh-user"
gdp_ssh_privatekeypath = "/path/to/private/key"
gdp_mu_host = "mu1,mu2"  # Optional, comma-separated list of managed units

# Audit Configuration
log_export_type = "Cloudwatch"
audit_events = "CONNECT,QUERY"
audit_file_rotations = "10"  # Optional
audit_file_rotate_size = "1000000"  # Optional

# Universal Connector Configuration
udc_name = "mysql-gdp"  # Optional, defaults to "mariadb-gdp"
enable_universal_connector = true  # Optional, defaults to true
csv_start_position = "end"  # Optional, defaults to "end"
csv_interval = "5"  # Optional, defaults to "5"
csv_event_filter = ""  # Optional, defaults to ""

# Resource Tags
tags = {
  Environment = "Production"
  Owner       = "Database Team"
}
```

Then run:

```bash
# Import existing resources (if needed)
# See the "Option Group and Parameter Group Import Process" section above

# Plan the changes
terraform plan -var-file=defaults.tfvars

# Apply the changes
terraform apply -var-file=defaults.tfvars
```

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
na.artifactory.swg-devops.com/ibm/guardium-data-protection
```

## Module Dependencies

This module uses the following internal modules:

1. `aws-configuration` - Retrieves AWS account information
2. `rds-mariadb-mysql-parameter-group` - Configures the MySQL parameter group for audit logging
3. `rds-mariadb-mysql-cloudwatch-registration` - Sets up CloudWatch integration for audit logs (when using CloudWatch)

## Audit Events Configuration

The `audit_events` variable allows you to specify which events to audit:

```hcl
audit_events = "CONNECT,QUERY,TABLE,QUERY_DDL,QUERY_DML,QUERY_DCL"
```

Valid audit event options:
- CONNECT: Connection events
- QUERY: All queries
- TABLE: Table access events
- QUERY_DDL: Data Definition Language queries
- QUERY_DML: Data Manipulation Language queries
- QUERY_DCL: Data Control Language queries

## CloudWatch Integration

This module configures CloudWatch integration for MySQL RDS auditing. The audit logs are sent to a CloudWatch log group with the format:

```
/aws/rds/instance/<mysql_rds_cluster_identifier>/audit
```

Guardium is configured to collect and analyze these logs.

## Universal Connector Control

You can control the Universal Connector behavior with these variables:

- `enable_universal_connector`: Set to false to disable the universal connector (default: true)
- `csv_start_position`: Start position for UDC (default: "end")
- `csv_interval`: Polling interval for UDC in seconds (default: "5")
- `csv_event_filter`: UDC Event filters (default: "")

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region | string | `"us-east-2"` | no |
| mysql_rds_cluster_identifier | MySQL RDS cluster identifier | string | `"guardium-mysql"` | no |
| mysql_major_version | Major version of MySQL (e.g., '5.7') | string | `"5.7"` | no |
| audit_events | Comma-separated list of events to audit | string | `"CONNECT,QUERY"` | no |
| audit_file_rotations | Number of audit file rotations to keep | string | `"10"` | no |
| audit_file_rotate_size | Size in bytes before rotating audit file | string | `"1000000"` | no |
| udc_aws_credential | Name of AWS credential defined in Guardium | string | n/a | yes |
| gdp_client_secret | Client secret from Guardium | string | n/a | yes |
| gdp_client_id | Client ID from Guardium | string | n/a | yes |
| gdp_server | Guardium server hostname/IP | string | n/a | yes |
| gdp_port | Port of Guardium Central Manager | string | `"8443"` | no |
| gdp_username | Guardium username | string | n/a | yes |
| gdp_password | Guardium password | string | n/a | yes |
| gdp_ssh_username | Guardium SSH username | string | n/a | yes |
| gdp_ssh_privatekeypath | Path to SSH private key | string | n/a | yes |
| gdp_mu_host | Comma separated list of Guardium Managed Units | string | `""` | no |
| log_export_type | Log export type (Cloudwatch) | string | `"Cloudwatch"` | no |
| force_failover | Whether to force failover during option group update | bool | `false` | no |
| tags | Map of tags to apply to resources | map(string) | `{}` | no |
| udc_name | Name for universal connector | string | `"mariadb-gdp"` | no |
| enable_universal_connector | Whether to enable the universal connector | bool | `true` | no |
| csv_start_position | Start position for UDC | string | `"end"` | no |
| csv_interval | Polling interval for UDC | string | `"5"` | no |
| csv_event_filter | UDC Event filters | string | `""` | no |

## Outputs

This module does not provide any outputs.
