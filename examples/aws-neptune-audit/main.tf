#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

provider "aws" {
  region = var.aws_region
}

module "datastore-audit_aws-neptune-audit" {
  source = "../../modules/aws-neptune-audit"

  # AWS Configuration
  aws_region                   = var.aws_region

  # Neptune Configuration
  neptune_cluster_identifier   = var.neptune_cluster_identifier
  neptune_endpoint             = var.neptune_endpoint

  # Guardium Configuration
  udc_aws_credential           = var.udc_aws_credential
  gdp_client_id                = var.gdp_client_id
  gdp_client_secret            = var.gdp_client_secret
  gdp_server                   = var.gdp_server
  gdp_port                     = var.gdp_port
  gdp_username                 = var.gdp_username
  gdp_password                 = var.gdp_password
  gdp_ssh_username             = var.gdp_ssh_username
  gdp_ssh_privatekeypath       = var.gdp_ssh_privatekeypath
  gdp_mu_host                  = var.gdp_mu_host

  # Universal Connector Configuration
  enable_universal_connector   = var.enable_universal_connector
  csv_start_position           = var.csv_start_position
  csv_interval                 = var.csv_interval
  codec_pattern                = var.codec_pattern
  csv_event_filter             = var.csv_event_filter
  use_aws_bundled_ca           = var.use_aws_bundled_ca

  # SFTP and Multipart Upload Configuration
  profile_upload_directory     = var.profile_upload_directory
  profile_api_directory        = var.profile_api_directory
  use_multipart_upload         = var.use_multipart_upload

  # Tags
  tags                         = var.tags
}
