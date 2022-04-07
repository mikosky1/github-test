provider "aws" {
    region = var.region
}

resource "aws_s3_bucket" "s3_new_buc" {
    bucket = "mikosky_bucket_new"
    acl = "public-read"

    website {
        index_document = "index.html"
        error_document = "error.html"
    }
}

resource "aws_s3_bucket_object" "object1" {
    for_each = fileset("html/", "*")
    bucket = "aws_s3_bucket.s3_new_buc.id"
    key = each.value
    source = "html/${each.value}"
    etag = filemd5("html/${each.value}")
    content_type = "text/html"
}

resource "aws_s3_bucket_policy" "prod_website" {  
  bucket = aws_s3_bucket.s3_new_buc.id   
policy = <<POLICY
{    
    "Version": "2022-04-17",    
    "Statement": [        
      {            
          "Sid": "PublicReadGetObject",            
          "Effect": "Allow",            
          "Principal": "*",            
          "Action": [                
             "s3:GetObject"            
          ],            
          "Resource": [
             "arn:aws:s3:::${aws_s3_bucket.s3_new_buc.id}/*"            
          ]        
      }    
    ]
}
POLICY
}