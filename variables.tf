#################
# Configuration #
#################
variable "vpc_name" {
  description = "The name of the vpc (eg.: live-1)"
  type        = string
}

variable "eks_cluster_name" {
  description = "The name of the eks cluster to retrieve the OIDC information"
  type        = string
}

variable "advanced_options" {
  description = "Key-value string pairs to specify advanced configuration options"
  type        = map(string)
  default     = {}
}

variable "cluster_config" {
  description = "Configuration block for the cluster of the domain"
  type        = map(any)
}

variable "ebs_enabled" {
  description = "Whether to configure an EBS volume. Set to false for instance types that do not support EBS."
  type        = bool
  default     = true
}

variable "ebs_options" {
  description = "Configuration block for EBS options for the domain"
  type        = map(any)
  default     = {}
}

variable "engine_version" {
  description = "OpenSearch engine version"
  type        = string
}

variable "proxy_count" {
  description = "Replica count for OpenSearch proxy"
  type        = number
  default     = 1
}

variable "snapshot_bucket_arn" {
  description = "S3 bucket ARN for domain snapshots"
  type        = string
}

variable "auto_tune_enabled" {
  description = "Whether to enable auto-tune or not"
  type        = bool
  default     = true
}
variable "auto_tune_config" {
  type = object({
    start_at                       = string
    duration_value                 = number
    duration_unit                  = string
    cron_expression_for_recurrence = string
    rollback_on_disable            = string
  })
  default     = null
  description = "see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain#maintenance_schedule for object structure"
}

variable "auto_software_update_enabled" {
  description = "Whether automatic service software updates are enabled for the domain."
  default     = false
  type        = bool
}

########
# Tags #
########
variable "business_unit" {
  description = "Area of the MOJ responsible for the service"
  type        = string
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "is_production" {
  description = "Whether this is used for production or not"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "namespace" {
  description = "Namespace name"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "infrastructure_support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
  type        = string
}
