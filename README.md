# cloud-platform-terraform-opensearch

[![Releases](https://img.shields.io/github/v/release/ministryofjustice/cloud-platform-terraform-opensearch.svg)](https://github.com/ministryofjustice/cloud-platform-terraform-opensearch/releases)

This Terraform module will create an [Amazon OpenSearch](https://aws.amazon.com/opensearch-service/) domain for use on the Cloud Platform.

It also creates an [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) to allow access via your Cloud Platform namespace pods, and a [proxy webserver](https://github.com/awslabs/aws-sigv4-proxy) to automatically sign requests to your OpenSearch domain from your pods.

## Usage

```hcl
module "opensearch" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-opensearch?ref=version" # use the latest release

  # VPC/EKS configuration
  vpc_name         = var.vpc_name
  eks_cluster_name = var.eks_cluster_name

  # Cluster configuration
  engine_version      = "OpenSearch_2.7"
  snapshot_bucket_arn = module.s3.bucket_arn

  cluster_config = {
    instance_count = 2
    instance_type  = "t3.small.search"
  }

  ebs_options = {
    volume_size = 10
  }

  # Tags
  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  team_name              = var.team_name
  namespace              = var.namespace
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
}
```

See the [examples/](examples/) folder for more information.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_irsa"></a> [irsa](#module\_irsa) | github.com/ministryofjustice/cloud-platform-terraform-irsa | 2.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_opensearch_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain) | resource |
| [aws_opensearch_domain_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain_policy) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [kubernetes_deployment.proxy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.proxy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [random_id.name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_arn.snapshot_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.domain_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snapshot_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.eks_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.eks_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_advanced_options"></a> [advanced\_options](#input\_advanced\_options) | Key-value string pairs to specify advanced configuration options | `map(string)` | `{}` | no |
| <a name="input_application"></a> [application](#input\_application) | Application name | `string` | n/a | yes |
| <a name="input_auto_software_update_enabled"></a> [auto\_software\_update\_enabled](#input\_auto\_software\_update\_enabled) | Whether automatic service software updates are enabled for the domain. | `bool` | `false` | no |
| <a name="input_auto_tune_config"></a> [auto\_tune\_config](#input\_auto\_tune\_config) | see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain#maintenance_schedule for object structure | <pre>object({<br/>    start_at                       = string<br/>    duration_value                 = number<br/>    duration_unit                  = string<br/>    cron_expression_for_recurrence = string<br/>    rollback_on_disable            = string<br/>  })</pre> | `null` | no |
| <a name="input_auto_tune_enabled"></a> [auto\_tune\_enabled](#input\_auto\_tune\_enabled) | Whether to enable auto-tune or not | `bool` | `true` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | Area of the MOJ responsible for the service | `string` | n/a | yes |
| <a name="input_cluster_config"></a> [cluster\_config](#input\_cluster\_config) | Configuration block for the cluster of the domain | `map(any)` | n/a | yes |
| <a name="input_ebs_enabled"></a> [ebs\_enabled](#input\_ebs\_enabled) | Whether to configure an EBS volume. Set to false for instance types that do not support EBS. | `bool` | `true` | no |
| <a name="input_ebs_options"></a> [ebs\_options](#input\_ebs\_options) | Configuration block for EBS options for the domain | `map(any)` | `{}` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | The name of the eks cluster to retrieve the OIDC information | `string` | n/a | yes |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | OpenSearch engine version | `string` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name | `string` | n/a | yes |
| <a name="input_infrastructure_support"></a> [infrastructure\_support](#input\_infrastructure\_support) | The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>) | `string` | n/a | yes |
| <a name="input_is_production"></a> [is\_production](#input\_is\_production) | Whether this is used for production or not | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace name | `string` | n/a | yes |
| <a name="input_proxy_count"></a> [proxy\_count](#input\_proxy\_count) | Replica count for OpenSearch proxy | `number` | `1` | no |
| <a name="input_snapshot_bucket_arn"></a> [snapshot\_bucket\_arn](#input\_snapshot\_bucket\_arn) | S3 bucket ARN for domain snapshots | `string` | n/a | yes |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | Team name | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the vpc (eg.: live-1) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain_arn"></a> [domain\_arn](#output\_domain\_arn) | OpenSearch domain ARN |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | OpenSearch domain name |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | OpenSearch VPC endpoint |
| <a name="output_irsa_role_arn"></a> [irsa\_role\_arn](#output\_irsa\_role\_arn) | Service account role ARN |
| <a name="output_proxy_url"></a> [proxy\_url](#output\_proxy\_url) | URL for opensearch-proxy service |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Service account name |
| <a name="output_snapshot_role_arn"></a> [snapshot\_role\_arn](#output\_snapshot\_role\_arn) | Snapshot role ARN |
<!-- END_TF_DOCS -->

## Tags

Some of the inputs for this module are tags. All infrastructure resources must be tagged to meet the MOJ Technical Guidance on [Documenting owners of infrastructure](https://technical-guidance.service.justice.gov.uk/documentation/standards/documenting-infrastructure-owners.html).

You should use your namespace variables to populate these. See the [Usage](#usage) section for more information.

## Reading Material

- [Cloud Platform user guide](https://user-guide.cloud-platform.service.justice.gov.uk/#cloud-platform-user-guide)
- [Amazon OpenSearch developer guide](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/what-is.html)
