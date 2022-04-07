output "s3_bucket_id" {
  value = aws_s3_bucket.s3_new_buc.website_endpoint
}