terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================
# NETWORKING - VPC, Subnets, IGW, NAT
# ============================================
module "networking" {
  source = "./modules/networking"

  project_name      = var.project_name
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ============================================
# SECURITY - Security Groups e IAM
# ============================================
module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
  enable_messaging_permissions = false  # Se actualizará después de crear messaging
  sns_topic_arns = null  # Se actualizará después de crear messaging
  sqs_queue_arns = null  # Se actualizará después de crear messaging
}

# Actualizar permisos de Security después de crear Messaging
resource "aws_iam_role_policy" "ec2_messaging" {
  name = "${var.project_name}-ec2-messaging-policy"
  role = module.security.ec2_role_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:GetTopicAttributes"
        ]
        Resource = values(module.messaging.sns_topic_arns)
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = values(module.messaging.sqs_queue_arns)
      }
    ]
  })
}

# ============================================
# COMPUTE - EC2, Auto Scaling, Load Balancer
# ============================================
module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  private_subnet_ids  = module.networking.private_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  ec2_security_group_id = module.security.ec2_security_group_id
  ec2_instance_profile_name = module.security.ec2_instance_profile_name
  instance_type       = var.instance_type
  key_name            = var.key_name
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
}

# ============================================
# MESSAGING - API Gateway, SNS, SQS
# ============================================
module "messaging" {
  source = "./modules/messaging"

  project_name           = var.project_name
  aws_region             = var.aws_region
  cors_origins           = var.cors_origins
  enable_sns_encryption  = var.enable_sns_encryption
  enable_sqs_encryption  = var.enable_sqs_encryption
  load_balancer_dns      = module.compute.load_balancer_dns
  load_balancer_arn      = module.compute.load_balancer_arn
}

# ============================================
# STORAGE - Parameter Store, Secrets Manager
# ============================================
module "storage" {
  source = "./modules/storage"

  project_name      = var.project_name
  use_parameter_store = var.use_parameter_store
  use_secrets_manager  = var.use_secrets_manager
}

# ============================================
# CI/CD - CodeCommit, CodeBuild, CodePipeline
# ============================================
module "ci_cd" {
  source = "./modules/ci-cd"

  project_name              = var.project_name
  aws_region                = var.aws_region
  environment               = var.environment
  codecommit_repo_name      = var.codecommit_repo_name
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  ec2_security_group_id     = module.security.ec2_security_group_id
  enable_pipelines          = var.enable_pipelines
  artifacts_retention_days  = var.artifacts_retention_days
  codebuild_environment_variables = var.codebuild_environment_variables
  use_parameter_store       = var.use_parameter_store
  use_secrets_manager       = var.use_secrets_manager
  
  # Referencias de Messaging
  api_gateway_id                = module.messaging.api_gateway_id
  sns_events_topic_arn          = module.messaging.sns_events_topic_arn
  sns_notifications_topic_arn   = module.messaging.sns_notifications_topic_arn
  sns_data_processing_topic_arn = module.messaging.sns_data_processing_topic_arn
  sqs_events_queue_url          = module.messaging.sqs_events_queue_url
  sqs_notifications_queue_url   = module.messaging.sqs_notifications_queue_url
  sqs_data_processing_queue_url = module.messaging.sqs_data_processing_queue_url
  sns_topic_arns                = values(module.messaging.sns_topic_arns)
  sqs_queue_arns                = values(module.messaging.sqs_queue_arns)
  
  # Referencias de Storage
  parameter_store_dev_vars     = module.storage.parameter_store_dev_names
  parameter_store_preprod_vars = module.storage.parameter_store_preprod_names
  parameter_store_prod_vars   = module.storage.parameter_store_prod_names
  
  # Aprobaciones manuales para producción
  require_prod_approvals      = var.require_prod_approvals
  prod_approval_sns_topic_arn = var.prod_approval_sns_topic_arn
  
  # Aprobaciones de PR para producción
  require_prod_pr_approvals = var.require_prod_pr_approvals
  prod_approvers_arn        = var.prod_approvers_arn
}
