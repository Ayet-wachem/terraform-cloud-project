output "state_bucket_name" {
  description = "Bucket à renseigner dans les fichiers backend.hcl."
  value       = aws_s3_bucket.terraform_state.bucket
}
