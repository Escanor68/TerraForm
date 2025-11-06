# Repositorio CodeCommit
resource "aws_codecommit_repository" "main" {
  repository_name = var.codecommit_repo_name
  description     = "Repositorio Git para ${var.project_name}"

  tags = {
    Name = var.codecommit_repo_name
  }
}

# Approval Rule Template para requerir 3 aprobaciones en PRs a producción
resource "aws_codecommit_approval_rule_template" "prod_approvals" {
  count = var.require_prod_pr_approvals ? 1 : 0

  name        = "${var.project_name}-prod-3-approvals"
  description = "Requiere 3 aprobaciones para PRs dirigidas a producción"

  content = jsonencode({
    Version = "2018-11-08"
    DestinationReferences = ["refs/heads/prod"]
    Statements = [
      merge(
        {
          Type                   = "Approvers"
          NumberOfApprovalsNeeded = 3
        },
        var.prod_approvers_arn != null && length(var.prod_approvers_arn) > 0 ? {
          ApprovalPoolMembers = var.prod_approvers_arn
        } : {}
      )
    ]
  })
}

# Asociar Approval Rule Template al repositorio
resource "aws_codecommit_approval_rule_template_association" "prod_branch" {
  count = var.require_prod_pr_approvals ? 1 : 0

  approval_rule_template_name = aws_codecommit_approval_rule_template.prod_approvals[0].name
  repository_name             = aws_codecommit_repository.main.repository_name
}

# CloudWatch Log Group para Lambda de validación de commits
resource "aws_cloudwatch_log_group" "commit_validator" {
  count             = var.validate_commit_messages ? 1 : 0
  name              = "/aws/lambda/${var.project_name}-commit-validator"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-commit-validator-logs"
  }
}

# IAM Role para Lambda de validación de commits
resource "aws_iam_role" "commit_validator" {
  count = var.validate_commit_messages ? 1 : 0
  name  = "${var.project_name}-commit-validator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-commit-validator-role"
  }
}

# IAM Policy para Lambda - Acceso a CodeCommit
resource "aws_iam_role_policy" "commit_validator_codecommit" {
  count = var.validate_commit_messages ? 1 : 0
  name  = "${var.project_name}-commit-validator-codecommit-policy"
  role  = aws_iam_role.commit_validator[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetPullRequest",
          "codecommit:GetCommit",
          "codecommit:GetDifferences",
          "codecommit:PostCommentForPullRequest",
          "codecommit:UpdatePullRequestStatus"
        ]
        Resource = aws_codecommit_repository.main.arn
      }
    ]
  })
}

# IAM Policy para Lambda - CloudWatch Logs
resource "aws_iam_role_policy" "commit_validator_logs" {
  count = var.validate_commit_messages ? 1 : 0
  name  = "${var.project_name}-commit-validator-logs-policy"
  role  = aws_iam_role.commit_validator[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.commit_validator[0].arn}:*"
      }
    ]
  })
}

# Lambda function para validar mensajes de commit
resource "aws_lambda_function" "commit_validator" {
  count = var.validate_commit_messages ? 1 : 0

  function_name = "${var.project_name}-commit-validator"
  role          = aws_iam_role.commit_validator[0].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30

  filename         = data.archive_file.commit_validator_zip[0].output_path
  source_code_hash = data.archive_file.commit_validator_zip[0].output_base64sha256

  environment {
    variables = {
      REPOSITORY_NAME = aws_codecommit_repository.main.repository_name
    }
  }

  depends_on = [
    aws_iam_role_policy.commit_validator_codecommit,
    aws_iam_role_policy.commit_validator_logs,
    aws_cloudwatch_log_group.commit_validator
  ]

  tags = {
    Name = "${var.project_name}-commit-validator"
  }
}

# Código fuente de la Lambda function
data "archive_file" "commit_validator_zip" {
  count    = var.validate_commit_messages ? 1 : 0
  type     = "zip"
  output_path = "${path.module}/commit_validator.zip"

  source {
    content = <<-PYTHON
import json
import re
import boto3
import os

codecommit = boto3.client('codecommit')
repository_name = os.environ['REPOSITORY_NAME']

# Tipos de commit permitidos según Conventional Commits
ALLOWED_TYPES = [
    'feat',      # Una nueva característica para el usuario
    'fix',       # Arregla un bug que afecta al usuario
    'perf',      # Cambios que mejoran el rendimiento del sitio
    'build',     # Cambios en el sistema de build, tareas de despliegue o instalación
    'ci',        # Cambios en la integración continua
    'docs',      # Cambios en la documentación
    'refactor',  # Refactorización del código
    'style',    # Cambios de formato, tabulaciones, espacios, etc.
    'test'       # Añade tests o refactoriza uno existente
]

def validate_commit_message(message):
    """
    Valida que el mensaje de commit siga el formato Conventional Commits
    Formato esperado: <tipo>: <descripción>
    """
    if not message or not message.strip():
        return False, "El mensaje de commit no puede estar vacío"
    
    # Patrón para Conventional Commits: tipo: descripción
    pattern = r'^({}):\s+.+'.format('|'.join(ALLOWED_TYPES))
    
    if not re.match(pattern, message.strip(), re.IGNORECASE):
        allowed = ', '.join(ALLOWED_TYPES)
        return False, f"El mensaje de commit debe seguir el formato Conventional Commits. Tipos permitidos: {allowed}. Ejemplo: 'feat: Agregar nueva funcionalidad'"
    
    return True, "Mensaje de commit válido"

def handler(event, context):
    """
    Handler principal de la Lambda function
    Se activa cuando se crea o actualiza un Pull Request en CodeCommit
    """
    try:
        # Obtener información del evento de EventBridge
        detail = event.get('detail', {})
        event_type = detail.get('event')
        
        if event_type not in ['pullRequestCreated', 'pullRequestSourceBranchUpdated']:
            return {
                'statusCode': 200,
                'body': json.dumps('Evento no relevante, omitiendo validación')
            }
        
        # Obtener información del PR
        pull_request_id = detail.get('pullRequestId')
        source_commit = detail.get('sourceCommit')
        destination_commit = detail.get('destinationCommit')
        
        if not pull_request_id:
            return {
                'statusCode': 400,
                'body': json.dumps('No se pudo obtener el ID del Pull Request')
            }
        
        # Obtener información del PR
        try:
            pr_response = codecommit.get_pull_request(
                pullRequestId=pull_request_id
            )
            
            pr = pr_response.get('pullRequest', {})
            pull_request_targets = pr.get('pullRequestTargets', [])
            
            if not pull_request_targets:
                return {
                    'statusCode': 400,
                    'body': json.dumps('No se encontraron targets en el PR')
                }
            
            target = pull_request_targets[0]
            source_commit_id = target.get('sourceCommit')
            destination_commit_id = target.get('destinationCommit')
            
            # Obtener los commits entre destination y source
            if source_commit_id and destination_commit_id:
                try:
                    # Obtener commits usando get_commits con el rango
                    commits_response = codecommit.get_commits(
                        repositoryName=repository_name,
                        commitId=source_commit_id
                    )
                    commits = commits_response.get('commits', [])
                    
                    # Filtrar commits que están después del destination commit
                    filtered_commits = []
                    for commit in commits:
                        commit_id = commit.get('commitId', '')
                        # Si llegamos al destination commit, paramos
                        if commit_id == destination_commit_id:
                            break
                        filtered_commits.append(commit)
                    
                    commits = filtered_commits if filtered_commits else commits
                        
                except Exception as e:
                    print(f"Error obteniendo commits: {str(e)}")
                    return {
                        'statusCode': 500,
                        'body': json.dumps(f'Error obteniendo commits: {str(e)}')
                    }
            else:
                return {
                    'statusCode': 400,
                    'body': json.dumps('No se pudieron obtener los commits del PR')
                }
            
        except Exception as e:
            print(f"Error obteniendo PR: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f'Error obteniendo PR: {str(e)}')
            }
        
        # Validar cada commit
        invalid_commits = []
        for commit in commits:
            commit_id = commit.get('commitId', '')
            commit_message = commit.get('message', '')
            
            is_valid, error_message = validate_commit_message(commit_message)
            
            if not is_valid:
                invalid_commits.append({
                    'commitId': commit_id[:7] if commit_id else 'unknown',
                    'message': commit_message[:100] if commit_message else 'empty',
                    'error': error_message
                })
        
        # Si hay commits inválidos, comentar en el PR y actualizar estado
        if invalid_commits:
            error_details = "\n".join([
                f"- Commit {c['commitId']}: {c['error']}\n  Mensaje: {c['message']}"
                for c in invalid_commits
            ])
            
            comment = f"""⚠️ **Validación de Commits Fallida**

Los siguientes commits no cumplen con el formato Conventional Commits:

{error_details}

**Tipos de commit permitidos:**
- feat: Una nueva característica para el usuario
- fix: Arregla un bug que afecta al usuario
- perf: Cambios que mejoran el rendimiento
- build: Cambios en el sistema de build
- ci: Cambios en la integración continua
- docs: Cambios en la documentación
- refactor: Refactorización del código
- style: Cambios de formato
- test: Añade o refactoriza tests

**Formato esperado:** `<tipo>: <descripción>`

Ejemplo: `feat: Agregar nueva funcionalidad de login`
"""
            
            try:
                # Obtener información del PR para los commits
                pr_info = codecommit.get_pull_request(pullRequestId=pull_request_id)
                pr_targets = pr_info.get('pullRequest', {}).get('pullRequestTargets', [])
                
                if pr_targets:
                    target = pr_targets[0]
                    dest_commit = target.get('destinationCommit')
                    src_commit = target.get('sourceCommit')
                    
                    codecommit.post_comment_for_pull_request(
                        pullRequestId=pull_request_id,
                        repositoryName=repository_name,
                        beforeCommitId=dest_commit,
                        afterCommitId=src_commit,
                        content=comment
                    )
            except Exception as e:
                print(f"Error comentando en PR: {str(e)}")
            
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Commits inválidos encontrados',
                    'invalid_commits': invalid_commits
                })
            }
        
        # Todos los commits son válidos
        success_comment = "✅ **Validación de Commits Exitosa**\n\nTodos los commits cumplen con el formato Conventional Commits."
        
        try:
            # Obtener información del PR para los commits
            pr_info = codecommit.get_pull_request(pullRequestId=pull_request_id)
            pr_targets = pr_info.get('pullRequest', {}).get('pullRequestTargets', [])
            
            if pr_targets:
                target = pr_targets[0]
                dest_commit = target.get('destinationCommit')
                src_commit = target.get('sourceCommit')
                
                codecommit.post_comment_for_pull_request(
                    pullRequestId=pull_request_id,
                    repositoryName=repository_name,
                    beforeCommitId=dest_commit,
                    afterCommitId=src_commit,
                    content=success_comment
                )
        except Exception as e:
            print(f"Error comentando en PR: {str(e)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Todos los commits son válidos')
        }
        
    except Exception as e:
        print(f"Error en handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error procesando evento: {str(e)}')
        }
PYTHON
    filename = "index.py"
  }
}

# Permiso para que EventBridge invoque la Lambda
resource "aws_lambda_permission" "eventbridge_invoke" {
  count         = var.validate_commit_messages ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.commit_validator[0].function_name
  principal     = "events.amazonaws.com"
  source_arn     = aws_cloudwatch_event_rule.commit_validator[0].arn
}

# EventBridge Rule para validar commits en PRs
resource "aws_cloudwatch_event_rule" "commit_validator" {
  count       = var.validate_commit_messages ? 1 : 0
  name        = "${var.project_name}-commit-validator-rule"
  description = "Valida mensajes de commit cuando se crea o actualiza un PR"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Pull Request State Change"]
    detail = {
      event = ["pullRequestCreated", "pullRequestSourceBranchUpdated"]
      repositoryNames = [aws_codecommit_repository.main.repository_name]
    }
  })

  tags = {
    Name = "${var.project_name}-commit-validator-rule"
  }
}

# EventBridge Target - Lambda function
resource "aws_cloudwatch_event_target" "commit_validator" {
  count = var.validate_commit_messages ? 1 : 0
  rule  = aws_cloudwatch_event_rule.commit_validator[0].name
  arn   = aws_lambda_function.commit_validator[0].arn
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
        Resource = [
          "${aws_cloudwatch_log_group.codebuild["dev"].arn}:*",
          "${aws_cloudwatch_log_group.codebuild["preprod"].arn}:*",
          "${aws_cloudwatch_log_group.codebuild["prod"].arn}:*"
        ]
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

  # Aprobación Manual 1 - Requerida antes del despliegue a producción
  dynamic "stage" {
    for_each = var.require_prod_approvals ? [1] : []
    content {
      name = "Approval-1"

      action {
        name     = "ManualApproval-1"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = var.prod_approval_sns_topic_arn != null ? {
          CustomData = "Primera aprobación requerida para despliegue a producción. Por favor, revisa los cambios antes de aprobar."
          NotificationArn = var.prod_approval_sns_topic_arn
        } : {
          CustomData = "Primera aprobación requerida para despliegue a producción. Por favor, revisa los cambios antes de aprobar."
        }
      }
    }
  }

  # Aprobación Manual 2 - Requerida antes del despliegue a producción
  dynamic "stage" {
    for_each = var.require_prod_approvals ? [1] : []
    content {
      name = "Approval-2"

      action {
        name     = "ManualApproval-2"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = var.prod_approval_sns_topic_arn != null ? {
          CustomData = "Segunda aprobación requerida para despliegue a producción. Por favor, revisa los cambios antes de aprobar."
          NotificationArn = var.prod_approval_sns_topic_arn
        } : {
          CustomData = "Segunda aprobación requerida para despliegue a producción. Por favor, revisa los cambios antes de aprobar."
        }
      }
    }
  }

  # Aprobación Manual 3 - Requerida antes del despliegue a producción
  dynamic "stage" {
    for_each = var.require_prod_approvals ? [1] : []
    content {
      name = "Approval-3"

      action {
        name     = "ManualApproval-3"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = var.prod_approval_sns_topic_arn != null ? {
          CustomData = "Tercera aprobación requerida para despliegue a producción. Por favor, revisa los cambios antes de aprobar."
          NotificationArn = var.prod_approval_sns_topic_arn
        } : {
          CustomData = "Tercera aprobación requerida para despliegue a producción. Por favor, revisa los cambios antes de aprobar."
        }
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

