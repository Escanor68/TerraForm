# Repositorio CodeCommit
resource "aws_codecommit_repository" "main" {
  repository_name = var.codecommit_repo_name
  description     = "Repositorio Git para ${var.project_name}"

  tags = {
    Name = var.codecommit_repo_name
  }
}

# IAM Role para CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-codebuild-role"
  }
}

# IAM Policy para CodeBuild - Acceso a CodeCommit
resource "aws_iam_role_policy" "codebuild_codecommit" {
  name = "${var.project_name}-codebuild-codecommit-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull",
          "codecommit:GetRepository",
          "codecommit:ListRepositories"
        ]
        Resource = aws_codecommit_repository.main.arn
      }
    ]
  })
}

# IAM Policy para CodeBuild - Logs
resource "aws_iam_role_policy" "codebuild_logs" {
  name = "${var.project_name}-codebuild-logs-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.codebuild["dev"].arn}:*"
      }
    ]
  })
}

# IAM Policy para CodeBuild - EC2, ECR, S3, SSM, Secrets Manager, SNS, SQS
resource "aws_iam_role_policy" "codebuild_services" {
  name = "${var.project_name}-codebuild-services-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::codepipeline-*",
          "arn:aws:s3:::codepipeline-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:GetTopicAttributes",
          "sns:ListTopics"
        ]
        Resource = var.sns_topic_arns != null ? var.sns_topic_arns : []
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
        Resource = var.sqs_queue_arns != null ? var.sqs_queue_arns : []
      }
    ]
  })
}

# CloudWatch Log Groups para CodeBuild por entorno
resource "aws_cloudwatch_log_group" "codebuild" {
  for_each          = toset(["dev", "preprod", "prod"])
  name              = "/aws/codebuild/${var.project_name}-build-${each.key}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-codebuild-logs-${each.key}"
    Environment = each.key
  }
}

# Proyectos CodeBuild para cada entorno
resource "aws_codebuild_project" "main" {
  for_each = {
    dev     = "dev"
    preprod = "preprod"
    prod    = "prod"
  }

  name          = "${var.project_name}-build-${each.key}"
  description   = "Proyecto CodeBuild para ${var.project_name} - ${each.value}"
  build_timeout = 60
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = each.value
    }

    environment_variable {
      name  = "VPC_ID"
      value = var.vpc_id
    }

    environment_variable {
      name  = "SUBNET_IDS"
      value = join(",", var.private_subnet_ids)
    }

    environment_variable {
      name  = "SECURITY_GROUP_IDS"
      value = var.ec2_security_group_id
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }

    # API Gateway URLs por entorno (si está disponible)
    dynamic "environment_variable" {
      for_each = var.api_gateway_id != null ? [1] : []
      content {
        name  = "API_GATEWAY_URL"
        value = "https://${var.api_gateway_id}.execute-api.${var.aws_region}.amazonaws.com/${each.value}"
      }
    }

    # SNS Topic ARNs (si están disponibles)
    dynamic "environment_variable" {
      for_each = var.sns_events_topic_arn != null ? [1] : []
      content {
        name  = "SNS_EVENTS_TOPIC_ARN"
        value = var.sns_events_topic_arn
      }
    }

    dynamic "environment_variable" {
      for_each = var.sns_notifications_topic_arn != null ? [1] : []
      content {
        name  = "SNS_NOTIFICATIONS_TOPIC_ARN"
        value = var.sns_notifications_topic_arn
      }
    }

    dynamic "environment_variable" {
      for_each = var.sns_data_processing_topic_arn != null ? [1] : []
      content {
        name  = "SNS_DATA_PROCESSING_TOPIC_ARN"
        value = var.sns_data_processing_topic_arn
      }
    }

    # SQS Queue URLs (si están disponibles)
    dynamic "environment_variable" {
      for_each = var.sqs_events_queue_url != null ? [1] : []
      content {
        name  = "SQS_EVENTS_QUEUE_URL"
        value = var.sqs_events_queue_url
      }
    }

    dynamic "environment_variable" {
      for_each = var.sqs_notifications_queue_url != null ? [1] : []
      content {
        name  = "SQS_NOTIFICATIONS_QUEUE_URL"
        value = var.sqs_notifications_queue_url
      }
    }

    dynamic "environment_variable" {
      for_each = var.sqs_data_processing_queue_url != null ? [1] : []
      content {
        name  = "SQS_DATA_PROCESSING_QUEUE_URL"
        value = var.sqs_data_processing_queue_url
      }
    }

    # Variables de entorno no sensibles definidas en variables.tf
    dynamic "environment_variable" {
      for_each = lookup(var.codebuild_environment_variables, each.key, {})
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }

    # Variables de entorno desde Parameter Store
    dynamic "environment_variable" {
      for_each = var.use_parameter_store && each.key == "dev" ? try({
        for key, param in var.parameter_store_dev_vars : key => param
      }, {}) : {}
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PARAMETER_STORE"
      }
    }

    dynamic "environment_variable" {
      for_each = var.use_parameter_store && each.key == "preprod" ? try({
        for key, param in var.parameter_store_preprod_vars : key => param
      }, {}) : {}
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PARAMETER_STORE"
      }
    }

    dynamic "environment_variable" {
      for_each = var.use_parameter_store && each.key == "prod" ? try({
        for key, param in var.parameter_store_prod_vars : key => param
      }, {}) : {}
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PARAMETER_STORE"
      }
    }
  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.private_subnet_ids
    security_group_ids = [var.ec2_security_group_id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild[each.key].name
      stream_name = "codebuild"
    }
  }

  tags = {
    Name        = "${var.project_name}-build-${each.key}"
    Environment = each.value
  }

  depends_on = [
    aws_cloudwatch_log_group.codebuild,
    aws_iam_role.codebuild
  ]
}

# S3 Bucket para artifacts de CodePipeline
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.project_name}-codepipeline-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-codepipeline-artifacts"
    Environment = "all"
  }
}

# Bloqueo de versión para el bucket de artifacts
resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación para el bucket de artifacts
resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Política de ciclo de vida para artifacts antiguos
resource "aws_s3_bucket_lifecycle_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    id     = "delete-old-artifacts"
    status = "Enabled"

    expiration {
      days = var.artifacts_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Bloqueo de acceso público al bucket
resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data source para obtener el account ID
data "aws_caller_identity" "current" {}

# IAM Role para CodePipeline
resource "aws_iam_role" "codepipeline" {
  name = "${var.project_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-codepipeline-role"
  }
}

# IAM Policy para CodePipeline - Acceso a CodeCommit
resource "aws_iam_role_policy" "codepipeline_codecommit" {
  name = "${var.project_name}-codepipeline-codecommit-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:ListBranches",
          "codecommit:ListRepositories"
        ]
        Resource = aws_codecommit_repository.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull"
        ]
        Resource = aws_codecommit_repository.main.arn
      }
    ]
  })
}

# IAM Policy para CodePipeline - Acceso a CodeBuild
resource "aws_iam_role_policy" "codepipeline_codebuild" {
  name = "${var.project_name}-codepipeline-codebuild-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [
          aws_codebuild_project.main["dev"].arn,
          aws_codebuild_project.main["preprod"].arn,
          aws_codebuild_project.main["prod"].arn
        ]
      }
    ]
  })
}

# IAM Policy para CodePipeline - Acceso a S3
resource "aws_iam_role_policy" "codepipeline_s3" {
  name = "${var.project_name}-codepipeline-s3-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy para CodePipeline - CloudWatch Logs
resource "aws_iam_role_policy" "codepipeline_logs" {
  name = "${var.project_name}-codepipeline-logs-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodePipeline para DEV
resource "aws_codepipeline" "dev" {
  count    = var.enable_pipelines ? 1 : 0
  name     = "${var.project_name}-pipeline-dev"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.main.repository_name
        BranchName           = "dev"
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.main["dev"].name
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-pipeline-dev"
    Environment = "dev"
    Branch      = "dev"
  }
}

# CodePipeline para PREPROD
resource "aws_codepipeline" "preprod" {
  count    = var.enable_pipelines ? 1 : 0
  name     = "${var.project_name}-pipeline-preprod"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.main.repository_name
        BranchName           = "preprod"
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.main["preprod"].name
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-pipeline-preprod"
    Environment = "preprod"
    Branch      = "preprod"
  }
}

# CodePipeline para PROD
resource "aws_codepipeline" "prod" {
  count    = var.enable_pipelines ? 1 : 0
  name     = "${var.project_name}-pipeline-prod"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.main.repository_name
        BranchName           = "prod"
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.main["prod"].name
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-pipeline-prod"
    Environment = "prod"
    Branch      = "prod"
  }
}

