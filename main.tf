locals {
  # Generic configuration
  identifier = "cloud-platform-${random_id.name.hex}"
  vpc_name   = (var.vpc_name == "live") ? "live-1" : var.vpc_name

  # Tags
  default_tags = {
    # Mandatory
    business-unit = var.business_unit
    application   = var.application
    is-production = var.is_production
    owner         = var.team_name
    namespace     = var.namespace # for billing and identification purposes

    # Optional
    environment-name       = var.environment_name
    infrastructure-support = var.infrastructure_support
  }
}

##################
# Get AWS region #
##################
data "aws_region" "current" {}

###########################
# Get account information #
###########################
data "aws_caller_identity" "current" {}

#######################
# Get VPC information #
#######################
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnets" "eks_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    SubnetType = "EKS-Private"
  }
}

data "aws_subnet" "eks_private" {
  for_each = toset(data.aws_subnets.eks_private.ids)
  id       = each.value
}

########################
# Generate identifiers #
########################
resource "random_id" "name" {
  byte_length = 4 # this is because there is a character limit of 24 characters per OpenSearch domain, so this generates `cloud-platform-12345678` which is 23 characters
}

##########################
# Create Security Groups #
##########################
resource "aws_security_group" "this" {
  vpc_id      = data.aws_vpc.this.id
  name        = local.identifier
  description = "Allow TLS ingress traffic via the private subnet for OpenSearch domain: ${local.identifier}"

  ingress {
    description = "TLS from the private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(
      [for s in data.aws_subnet.private : s.cidr_block],
      [for s in data.aws_subnet.eks_private : s.cidr_block]
    )
  }

  egress {
    description = "Egress to the private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = concat(
      [for s in data.aws_subnet.private : s.cidr_block],
      [for s in data.aws_subnet.eks_private : s.cidr_block]
    )
  }

  tags = local.default_tags
}

############################
# Create OpenSearch domain #
############################
resource "aws_kms_key" "this" {
  description = "Used for OpenSearch: ${local.identifier}"
  key_usage   = "ENCRYPT_DECRYPT"

  bypass_policy_lockout_safety_check = false
  deletion_window_in_days            = 30
  is_enabled                         = true
  enable_key_rotation                = false
  multi_region                       = false
  tags                               = local.default_tags
}

resource "aws_opensearch_domain" "this" {
  domain_name = local.identifier

  advanced_options = merge({
    "rest.action.multi.allow_explicit_index" = "true"
  }, var.advanced_options)

  dynamic "cluster_config" {
    for_each = [var.cluster_config]

    content {
      # Dedicated primary nodes
      dedicated_master_count   = try(cluster_config.value["dedicated_master_enabled"], false) ? cluster_config.value["dedicated_master_count"] : null
      dedicated_master_enabled = try(cluster_config.value["dedicated_master_enabled"], false) ? cluster_config.value["dedicated_master_enabled"] : false
      dedicated_master_type    = try(cluster_config.value["dedicated_master_enabled"], false) ? cluster_config.value["dedicated_master_type"] : null

      # Instances
      instance_count = cluster_config.value["instance_count"]
      instance_type  = cluster_config.value["instance_type"]

      # Warm storage
      warm_count   = try(cluster_config.value["warm_enabled"], false) ? cluster_config.value["warm_count"] : null
      warm_enabled = try(cluster_config.value["warm_enabled"], false) ? cluster_config.value["warm_enabled"] : false
      warm_type    = try(cluster_config.value["warm_enabled"], false) ? cluster_config.value["warm_type"] : null

      # Zone awareness
      zone_awareness_enabled = (cluster_config.value["instance_count"] >= 2) ? true : false

      dynamic "zone_awareness_config" {
        for_each = cluster_config.value["instance_count"] == 2 ? [2] : cluster_config.value["instance_count"] >= 3 ? [3] : []

        content {
          availability_zone_count = zone_awareness_config.value
        }
      }
    }
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07" # default to TLS 1.2
  }

  ebs_options {
    ebs_enabled = var.ebs_enabled
    iops        = var.ebs_enabled ? try(var.ebs_options["iops"], 3000) : null      # these are AWS defaults
    throughput  = var.ebs_enabled ? try(var.ebs_options["throughput"], 125) : null # these are AWS defaults
    volume_size = var.ebs_enabled ? var.ebs_options["volume_size"] : null
    volume_type = var.ebs_enabled ? "gp3" : null
  }

  engine_version = var.engine_version

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.this.key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    security_group_ids = [aws_security_group.this.id]
    subnet_ids         = (var.cluster_config["instance_count"] < 3) ? slice(data.aws_subnets.private.ids, 0, 2) : data.aws_subnets.private.ids
  }

  dynamic "auto_tune_options" {
    for_each = var.auto_tune_enabled ? [true] : []
    content {
      desired_state       = var.auto_tune_enabled ? (length(split("t3.", var.cluster_config["instance_type"])) > 1 ? "DISABLED" : "ENABLED") : "DISABLED"
      rollback_on_disable = (var.auto_tune_config != null) ? var.auto_tune_config["rollback_on_disable"] : "NO_ROLLBACK"
      dynamic "maintenance_schedule" {
        for_each = var.auto_tune_config != null ? [1] : []
        content {
          start_at = var.auto_tune_config["start_at"]
          duration {
            value = var.auto_tune_config["duration_value"]
            unit  = var.auto_tune_config["duration_unit"]
          }
          cron_expression_for_recurrence = var.auto_tune_config["cron_expression_for_recurrence"]
        }
      }
    }
  }

  software_update_options {
    auto_software_update_enabled = var.auto_software_update_enabled
  }

  tags = local.default_tags
}

# Configure OpenSearch snapshot repository
data "aws_arn" "snapshot_bucket" {
  arn = var.snapshot_bucket_arn
}

data "aws_iam_policy_document" "snapshot_assume_role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "snapshot" {
  name               = "${local.identifier}-snapshot"
  assume_role_policy = data.aws_iam_policy_document.snapshot_assume_role.json

  tags = local.default_tags
}

data "aws_iam_policy_document" "snapshot" {
  version = "2012-10-17"

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.snapshot_bucket_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${var.snapshot_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "snapshot" {
  name   = "${local.identifier}-snapshot"
  path   = "/cloud-platform/opensearch/"
  policy = data.aws_iam_policy_document.snapshot.json
  tags   = local.default_tags
}

resource "aws_iam_role_policy_attachment" "snapshot" {
  role       = aws_iam_role.snapshot.name
  policy_arn = aws_iam_policy.snapshot.arn
}

# Allow access for the Kubernetes cluster/IRSA
data "aws_iam_policy_document" "domain_policy" {
  statement {
    effect = "Allow"
    actions = [
      "es:ESHttp*"
    ]
    resources = [
      "${aws_opensearch_domain.this.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [module.irsa.role_arn]
    }
  }
}

resource "aws_opensearch_domain_policy" "this" {
  domain_name     = aws_opensearch_domain.this.domain_name
  access_policies = data.aws_iam_policy_document.domain_policy.json
}
