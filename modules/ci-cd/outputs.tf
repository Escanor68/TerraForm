output "codecommit_repo_url" {
  description = "URL del repositorio CodeCommit"
  value       = aws_codecommit_repository.main.clone_url_http
}

output "codecommit_repo_arn" {
  description = "ARN del repositorio CodeCommit"
  value       = aws_codecommit_repository.main.arn
}

output "codebuild_project_names" {
  description = "Nombres de los proyectos CodeBuild por entorno"
  value = {
    dev     = aws_codebuild_project.main["dev"].name
    preprod = aws_codebuild_project.main["preprod"].name
    prod    = aws_codebuild_project.main["prod"].name
  }
}

output "codebuild_project_arns" {
  description = "ARNs de los proyectos CodeBuild por entorno"
  value = {
    dev     = aws_codebuild_project.main["dev"].arn
    preprod = aws_codebuild_project.main["preprod"].arn
    prod    = aws_codebuild_project.main["prod"].arn
  }
}

output "codepipeline_names" {
  description = "Nombres de los pipelines por entorno"
  value = var.enable_pipelines ? {
    dev     = aws_codepipeline.dev[0].name
    preprod = aws_codepipeline.preprod[0].name
    prod    = aws_codepipeline.prod[0].name
  } : {}
}

output "codepipeline_arns" {
  description = "ARNs de los pipelines por entorno"
  value = var.enable_pipelines ? {
    dev     = aws_codepipeline.dev[0].arn
    preprod = aws_codepipeline.preprod[0].arn
    prod    = aws_codepipeline.prod[0].arn
  } : {}
}

output "codepipeline_artifacts_bucket" {
  description = "Nombre del bucket S3 para artifacts de CodePipeline"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "codebuild_service_role_arn" {
  description = "ARN del rol de servicio de CodeBuild"
  value       = aws_iam_role.codebuild.arn
}

output "codepipeline_service_role_arn" {
  description = "ARN del rol de servicio de CodePipeline"
  value       = aws_iam_role.codepipeline.arn
}

