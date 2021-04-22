####################### S3 #######################
resource "aws_s3_bucket" "website" {
  bucket        = var.site_bucket_name
  acl           = "private"
  force_destroy = true
  tags          = local.tags

  versioning {
    enabled = true
  }
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3block" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_distribution" "cf" {
  enabled             = true
  aliases             = [var.endpoint]
  default_root_object = "index.html"
  depends_on = [
    aws_acm_certificate_validation.certvalidation
  ]
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.website.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = aws_s3_bucket.website.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers      = []
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  tags = local.tags
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.endpoint}"
}

resource "aws_s3_bucket_policy" "s3policy" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3policy.json
  depends_on = [
    aws_s3_bucket_public_access_block.s3block
  ]
}

resource "aws_acm_certificate" "cert" {
  provider                  = aws.us-east-1
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  tags                      = local.tags
}

resource "aws_route53_record" "certvalidation" {
  for_each = {
    for d in aws_acm_certificate.cert.domain_validation_options : d.domain_name => {
      name   = d.resource_record_name
      record = d.resource_record_value
      type   = d.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

resource "aws_acm_certificate_validation" "certvalidation" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.certvalidation : r.fqdn]
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "websiteurl" {
  name    = var.endpoint
  zone_id = aws_route53_zone.primary.zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = true
  }
}

####################### S3  END  #######################


####################### LAMBDA #######################

# VPC & SUBNET
module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git"
  name       = "main"
  cidr_block = "172.16.0.0/16"
}

module "subnets" {
  source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git"
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b"]
  name                 = "main"
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = true
  nat_instance_enabled = false
}

module "default_sg" {
  source = "cloudposse/security-group/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"
  rules = [
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "egress"
      from_port   = 6379
      to_port     = 6379
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "egress"
      from_port   = 80
      to_port     = 80
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  vpc_id = module.vpc.vpc_id
  tags = local.tags
}
module "rds_sg" {
  source = "cloudposse/security-group/aws"
  rules = [
    {
      type        = "ingress"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  vpc_id = module.vpc.vpc_id
  tags = local.tags
}
module "alb_sg" {
  source = "cloudposse/security-group/aws"
  rules = [
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from_port   = 5000
      to_port     = 5002
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  vpc_id = module.vpc.vpc_id
  tags = local.tags
}
module "bastion_sg" {
  source = "cloudposse/security-group/aws"
  rules = [
    {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  vpc_id = module.vpc.vpc_id
  tags = local.tags
}



################################## LAMBDA SETTINGS ##################################
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_policy" "iam_policy" {
  name = "lambda_access-policy"
  description = "IAM Policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.bucket_name}",
                "arn:aws:s3:::${var.bucket_name}/*"
            ]
        },
        {
          "Action": [
            "autoscaling:Describe*",
            "cloudwatch:*",
            "logs:*",
            "sns:*"
          ],
          "Effect": "Allow",
          "Resource": "*"
        },
        {
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "arn:aws:logs:*:*:*",
          "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam-policy-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy.arn
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processData.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

################################## FUNCTIONS ##################################

resource "aws_lambda_function" "processData" {
  filename      = var.processdatazip
  function_name = "processData"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  memory_size   = 10000
  timeout       = 180
  layers = [
      "arn:aws:lambda:ap-southeast-1:468957933125:layer:AWSLambda-Python38-SciPy1x:29",
      "arn:aws:lambda:ap-southeast-1:770693421928:layer:Klayers-python38-pandas:29"
   ]
  vpc_config {
    subnet_ids         = module.subnets.private_subnet_ids
    security_group_ids = [module.default_sg.id]
  }

  environment {
    variables = {
        bucket_name = var.bucket_name
        redis_host = module.redis.endpoint
    }
  }
  depends_on = [
    aws_s3_bucket.bucket,
    module.redis
  ]
}

resource "aws_lambda_function" "getHotels" {
  filename      = var.hotelszip
  function_name = "getHotels"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  memory_size   = 128
  timeout       = 900
  vpc_config {
    subnet_ids         = module.subnets.public_subnet_ids
    security_group_ids = [module.default_sg.id]
  }
  environment {
    variables = {
      "redis_host" = module.redis.endpoint
    }
  }
  depends_on = [
    module.redis
  ]
}

resource "aws_lambda_function" "getDestinations" {
    filename    = var.destzip
    function_name = "getDestinations"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "main.lambda_handler"
    runtime = "python3.8"
    vpc_config {
      subnet_ids         = module.subnets.public_subnet_ids
      security_group_ids = [module.default_sg.id]
    }
    environment {
      variables = {
        "redis_host" = module.redis.endpoint
      }
    }
    depends_on = [
      module.redis
    ]
}

resource "aws_lambda_function" "getHotelInfo" {
    filename    = var.hotelinfozip
    function_name = "getHotelInfo"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "main.lambda_handler"
    runtime = "python3.8"
}

resource "aws_lambda_function" "getPrices" {
    filename    = var.priceszip
    function_name = "getPrices"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "main.lambda_handler"
    runtime = "python3.8"
}

resource "aws_lambda_function" "getRoomPrices" {
    filename    = var.roompriceszip
    function_name = "getRoomPrices"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "main.lambda_handler"
    runtime = "python3.8"
}

resource "aws_lambda_function" "gethotelsbydest" {
    filename    = var.hotelsbydestzip
    function_name = "getHotelsByDestination"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "main.lambda_handler"
    runtime = "python3.8"
}

################################## BUCKET SETTINGS ##################################
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  force_destroy =  true
}

resource "aws_s3_bucket_public_access_block" "s3block_data" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.processData.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_bucket, aws_s3_bucket_public_access_block.s3block_data]
}


################################## REDIS ##################################

module "redis" {
  source = "cloudposse/elasticache-redis/aws"

  availability_zones         = module.subnets.availability_zones
  name                       = "redis"
  vpc_id                     = module.vpc.vpc_id
  allowed_security_groups    = [module.vpc.vpc_default_security_group_id, module.default_sg.id]
  subnets                    = module.subnets.public_subnet_ids
  cluster_size               = 2
  multi_az_enabled           = true
  instance_type              = "cache.t2.micro"
  apply_immediately          = true
  automatic_failover_enabled = true
  engine_version             = "6.x"
  family                     = "redis6.x"
  transit_encryption_enabled = false
  replication_group_id       = "redisReplicate"
}



################################## GATEWAY GETDESTINATION ##################################
resource "aws_api_gateway_rest_api" "serverless_api" {
  name = "gateway"
}

resource "aws_api_gateway_request_validator" "gateway_validator" {
  name                        = "validator"
  rest_api_id                 = aws_api_gateway_rest_api.serverless_api.id
  validate_request_parameters = true
}

resource "aws_api_gateway_resource" "getDestinations" {
  path_part   = "destinations"
  parent_id   = aws_api_gateway_rest_api.serverless_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
}

resource "aws_api_gateway_method" "getDestinations" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.getDestinations.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "getDestinations" {
  rest_api_id             = aws_api_gateway_rest_api.serverless_api.id
  resource_id             = aws_api_gateway_resource.getDestinations.id
  http_method             = aws_api_gateway_method.getDestinations.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.getDestinations.invoke_arn
}


resource "aws_lambda_permission" "getDestinations" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getDestinations.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.serverless_api.execution_arn}/*/${aws_api_gateway_method.getDestinations.http_method}${aws_api_gateway_resource.getDestinations.path}"
}

resource "aws_api_gateway_method" "getdest_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.getDestinations.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_method_response" "getdest_options_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getDestinations.id
  http_method = aws_api_gateway_method.getdest_options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.getdest_options_method]
}


resource "aws_api_gateway_integration" "getdest_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getDestinations.id
  http_method = aws_api_gateway_method.getdest_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

  depends_on = [aws_api_gateway_method.getdest_options_method]
}


resource "aws_api_gateway_integration_response" "getdest_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getDestinations.id
  http_method = aws_api_gateway_method.getdest_options_method.http_method
  status_code = aws_api_gateway_method_response.getdest_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.getdest_options_response,
    aws_api_gateway_integration.getdest_options_integration
  ]
}



################################## GATEWAY GETHOTELS ##################################

resource "aws_api_gateway_resource" "getHotels" {
  path_part   = "hotels"
  parent_id   = aws_api_gateway_rest_api.serverless_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
}

resource "aws_api_gateway_method" "getHotels" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.getHotels.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.destination_id" = true
  }
  request_validator_id = aws_api_gateway_request_validator.gateway_validator.id
}

resource "aws_api_gateway_method_settings" "getHotels" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  stage_name = aws_api_gateway_deployment.deployment.stage_name
  method_path = "/hotels/GET"

  settings {
    caching_enabled = true
    cache_ttl_in_seconds = 3600
  }
}

resource "aws_api_gateway_integration" "getHotels" {
  rest_api_id             = aws_api_gateway_rest_api.serverless_api.id
  resource_id             = aws_api_gateway_resource.getHotels.id
  http_method             = aws_api_gateway_method.getHotels.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.getHotels.invoke_arn
}

resource "aws_lambda_permission" "getHotels" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getHotels.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.serverless_api.execution_arn}/*/${aws_api_gateway_method.getHotels.http_method}${aws_api_gateway_resource.getHotels.path}"
}

resource "aws_api_gateway_method" "gethotels_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.getHotels.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_method_response" "gethotels_options_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getHotels.id
  http_method = aws_api_gateway_method.gethotels_options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.gethotels_options_method]
}


resource "aws_api_gateway_integration" "gethotels_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getHotels.id
  http_method = aws_api_gateway_method.gethotels_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

  depends_on = [aws_api_gateway_method.gethotels_options_method]
}


resource "aws_api_gateway_integration_response" "gethotels_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getHotels.id
  http_method = aws_api_gateway_method.gethotels_options_method.http_method
  status_code = aws_api_gateway_method_response.gethotels_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.gethotels_options_response,
    aws_api_gateway_integration.gethotels_options_integration
  ]
}


################################## GATEWAY GETPRICES ##################################

resource "aws_api_gateway_resource" "getPrices" {
  path_part   = "prices"
  parent_id   = aws_api_gateway_rest_api.serverless_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
}

resource "aws_api_gateway_method" "getPrices" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.getPrices.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.checkin" = true,
    "method.request.querystring.checkout" = true,
    "method.request.querystring.destination_id" = true,
    "method.request.querystring.guest" = true
  }
  request_validator_id = aws_api_gateway_request_validator.gateway_validator.id
}

resource "aws_api_gateway_method_settings" "getPrices" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  stage_name = aws_api_gateway_deployment.deployment.stage_name
  method_path = "/prices/GET"

  settings {
    caching_enabled = true
    cache_ttl_in_seconds = 3600
  }

}

resource "aws_api_gateway_integration" "getPrices" {
  rest_api_id             = aws_api_gateway_rest_api.serverless_api.id
  resource_id             = aws_api_gateway_resource.getPrices.id
  http_method             = aws_api_gateway_method.getPrices.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.getPrices.invoke_arn
}

resource "aws_lambda_permission" "getPrices" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getPrices.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.serverless_api.execution_arn}/*/${aws_api_gateway_method.getPrices.http_method}${aws_api_gateway_resource.getPrices.path}"
}

resource "aws_api_gateway_method" "getprices_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.getPrices.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_method_response" "getprices_options_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getPrices.id
  http_method = aws_api_gateway_method.getprices_options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.getprices_options_method]
}


resource "aws_api_gateway_integration" "getprices_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getPrices.id
  http_method = aws_api_gateway_method.getprices_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

  depends_on = [aws_api_gateway_method.getprices_options_method]
}


resource "aws_api_gateway_integration_response" "getprices_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getPrices.id
  http_method = aws_api_gateway_method.getprices_options_method.http_method
  status_code = aws_api_gateway_method_response.getprices_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.getprices_options_response,
    aws_api_gateway_integration.getprices_options_integration
  ]
}

# ################################## GATEWAY GETROOMPRICES ##################################

resource "aws_api_gateway_resource" "getRoomPrices" {
  path_part   = "prices"
  parent_id   = aws_api_gateway_resource.getHotels.id
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
}

resource "aws_api_gateway_method" "getRoomPrices" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.getRoomPrices.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.checkin" = true,
    "method.request.querystring.checkout" = true,
    "method.request.querystring.destination_id" = true,
    "method.request.querystring.guest" = true,
    "method.request.querystring.hotel" = true
  }
  request_validator_id = aws_api_gateway_request_validator.gateway_validator.id
}

resource "aws_api_gateway_integration" "getRoomPrices" {
  rest_api_id             = aws_api_gateway_rest_api.serverless_api.id
  resource_id             = aws_api_gateway_resource.getRoomPrices.id
  http_method             = aws_api_gateway_method.getRoomPrices.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.getRoomPrices.invoke_arn
}

resource "aws_lambda_permission" "getRoomPrices" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getRoomPrices.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.serverless_api.execution_arn}/*/${aws_api_gateway_method.getRoomPrices.http_method}${aws_api_gateway_resource.getRoomPrices.path}"
}

resource "aws_api_gateway_method" "getroomprice_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.getRoomPrices.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_method_response" "getroomprice_options_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getRoomPrices.id
  http_method = aws_api_gateway_method.getroomprice_options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.getroomprice_options_method]
}


resource "aws_api_gateway_integration" "getroomprice_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getRoomPrices.id
  http_method = aws_api_gateway_method.getroomprice_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

  depends_on = [aws_api_gateway_method.getroomprice_options_method]
}


resource "aws_api_gateway_integration_response" "getroomprice_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.getRoomPrices.id
  http_method = aws_api_gateway_method.getroomprice_options_method.http_method
  status_code = aws_api_gateway_method_response.getroomprice_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.getroomprice_options_response,
    aws_api_gateway_integration.getroomprice_options_integration
  ]
}

################################## GATEWAY GETHOTELINFO ##################################


resource "aws_api_gateway_resource" "gethotelinfo" {
  path_part   = "{hotel+}" // proxy style
  parent_id   = aws_api_gateway_resource.getHotels.id
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
}

resource "aws_api_gateway_method" "gethotelinfo" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.gethotelinfo.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "gethotelinfo" {
  rest_api_id             = aws_api_gateway_rest_api.serverless_api.id
  resource_id             = aws_api_gateway_resource.gethotelinfo.id
  http_method             = aws_api_gateway_method.gethotelinfo.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.getHotelInfo.invoke_arn
}

resource "aws_lambda_permission" "gethotelinfo" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getHotelInfo.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.serverless_api.execution_arn}/*/*/hotels/*"
}

resource "aws_api_gateway_method" "gethotelinfo_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.gethotelinfo.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_method_response" "gethotelinfo_options_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.gethotelinfo.id
  http_method = aws_api_gateway_method.gethotelinfo_options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.gethotelinfo_options_method]
}


resource "aws_api_gateway_integration" "gethotelinfo_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.gethotelinfo.id
  http_method = aws_api_gateway_method.gethotelinfo_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

  depends_on = [aws_api_gateway_method.gethotelinfo_options_method]
}


resource "aws_api_gateway_integration_response" "gethotelinfo_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.gethotelinfo.id
  http_method = aws_api_gateway_method.gethotelinfo_options_method.http_method
  status_code = aws_api_gateway_method_response.gethotelinfo_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.gethotelinfo_options_response,
    aws_api_gateway_integration.gethotelinfo_options_integration
  ]
}

################################# GATEWAY GETHOTELSBYDEST

resource "aws_api_gateway_resource" "gethotelsbydest" {
  path_part   = "info" // proxy style
  parent_id   = aws_api_gateway_resource.getHotels.id
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
}

resource "aws_api_gateway_method" "gethotelsbydest" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.gethotelsbydest.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.checkin" = true,
    "method.request.querystring.checkout" = true,
    "method.request.querystring.destination_id" = true,
    "method.request.querystring.guest" = true
  }
  request_validator_id = aws_api_gateway_request_validator.gateway_validator.id
}

resource "aws_api_gateway_integration" "gethotelsbydest" {
  rest_api_id             = aws_api_gateway_rest_api.serverless_api.id
  resource_id             = aws_api_gateway_resource.gethotelsbydest.id
  http_method             = aws_api_gateway_method.gethotelsbydest.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.gethotelsbydest.invoke_arn
}

resource "aws_lambda_permission" "gethotelsbydest" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gethotelsbydest.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.serverless_api.execution_arn}/*/${aws_api_gateway_method.gethotelsbydest.http_method}${aws_api_gateway_resource.gethotelsbydest.path}"
}

resource "aws_api_gateway_method" "gethotelsbydest_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.gethotelsbydest.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_method_response" "gethotelsbydest_options_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.gethotelsbydest.id
  http_method = aws_api_gateway_method.gethotelsbydest_options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.gethotelsbydest_options_method]
}


resource "aws_api_gateway_integration" "gethotelsbydest_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.gethotelsbydest.id
  http_method = aws_api_gateway_method.gethotelsbydest_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

  depends_on = [aws_api_gateway_method.gethotelsbydest_options_method]
}


resource "aws_api_gateway_integration_response" "gethotelsbydest_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.gethotelsbydest.id
  http_method = aws_api_gateway_method.gethotelsbydest_options_method.http_method
  status_code = aws_api_gateway_method_response.gethotelsbydest_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.gethotelsbydest_options_response,
    aws_api_gateway_integration.gethotelsbydest_options_integration
  ]
}

# #################

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  stage_name = "prod"
  lifecycle {
    create_before_destroy = true
  }
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.getDestinations.id,
      aws_api_gateway_resource.getDestinations.id,
      aws_api_gateway_integration.getHotels.id,
      aws_api_gateway_resource.getHotels.id,
      aws_api_gateway_integration.getPrices.id,
      aws_api_gateway_resource.getPrices.id,
      aws_api_gateway_integration.getRoomPrices.id,
      aws_api_gateway_resource.getRoomPrices.id,
      aws_api_gateway_integration.gethotelinfo.id,
      aws_api_gateway_resource.gethotelinfo.id,
      aws_api_gateway_integration.gethotelsbydest.id,
      aws_api_gateway_resource.gethotelsbydest.id,
    ]))
  }
  depends_on = [
    aws_api_gateway_integration.getDestinations,
    aws_api_gateway_integration.getdest_options_integration,
    aws_api_gateway_integration.getHotels,
    aws_api_gateway_integration.gethotels_options_integration,
    aws_api_gateway_integration.getPrices,
    aws_api_gateway_integration.getprices_options_integration,
    aws_api_gateway_integration.getRoomPrices,
    aws_api_gateway_integration.getroomprice_options_integration,
    aws_api_gateway_integration.gethotelinfo,
    aws_api_gateway_integration.gethotelinfo_options_integration,
    aws_api_gateway_integration.gethotelsbydest,
    aws_api_gateway_integration.gethotelsbydest_options_integration,
  ]
}

################################# GATEWAY DOMAIN ################################

resource "aws_api_gateway_domain_name" "domain" {
  certificate_arn = aws_acm_certificate_validation.certvalidation.certificate_arn
  domain_name     = "api.ascendahotels.me"
}

# Example DNS record using Route53.
# Route53 is not specifically required; any DNS host can be used.
resource "aws_route53_record" "gateway_domain" {
  # provider = aws.us-east-1
  name    = aws_api_gateway_domain_name.domain.domain_name
  type    = "A"
  zone_id = aws_route53_zone.primary.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.domain.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.domain.cloudfront_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id      = aws_api_gateway_rest_api.serverless_api.id
  stage_name  = aws_api_gateway_deployment.deployment.stage_name
  domain_name = aws_api_gateway_domain_name.domain.domain_name
}


##### UPLOAD DATA SET TO S3 #####
resource "aws_s3_bucket_object" "object1" {
  for_each = fileset("data/", "*")
  bucket = aws_s3_bucket.bucket.id
  key = each.value
  source = "data/${each.value}"
  etag = filemd5("data/${each.value}")
  depends_on = [
    aws_lambda_function.processData
  ]
}

######################### BACKEND #########################
data "aws_ecr_authorization_token" "ecr_token" {}

resource "aws_ecr_repository" "itsa_backend" {
    name = "itsa_backend"
}

# Multiple docker push commands can be run against a single token
resource "null_resource" "renew_ecr_token" {
  triggers = {
    token_expired = data.aws_ecr_authorization_token.ecr_token.expires_at
  }

  provisioner "local-exec" {
    command = "echo ${data.aws_ecr_authorization_token.ecr_token.password} | docker login --username ${data.aws_ecr_authorization_token.ecr_token.user_name} --password-stdin ${data.aws_ecr_authorization_token.ecr_token.proxy_endpoint}"

  }
}

# Build docker image and push to ecr
# From folder: ../booking
module "ecr_booking_image" {
  source = "git::https://github.com/onnimonni/terraform-ecr-docker-build-module"

  # Absolute path into the service which needs to be build
  dockerfile_folder = "${path.module}/../../backend/booking"

  # Tag for the builded Docker image (Defaults to ‘latest’)
  docker_image_tag = "booking"

  # The region which we will log into with aws-cli
  aws_region = "ap-southeast-1"

  # ECR repository where we can push
  ecr_repository_url = aws_ecr_repository.itsa_backend.repository_url
  
  # Acquire ecr auth token only once
  depends_on = [null_resource.renew_ecr_token, aws_ecr_repository.itsa_backend]
}

# Build docker image and push to ecr
# From folder: ../registration
module "ecr_registration_image" {
  source = "./.terraform/modules/ecr_booking_image"

  # Absolute path into the service which needs to be build
  dockerfile_folder = "${path.module}/../../backend/registration"

  # Tag for the builded Docker image (Defaults to ‘latest’)
  docker_image_tag = "registration"

  # The region which we will log into with aws-cli
  aws_region = "ap-southeast-1"

  # ECR repository where we can push
  ecr_repository_url = aws_ecr_repository.itsa_backend.repository_url
  
  # Acquire ecr auth token only once
  depends_on = [module.ecr_booking_image]
}

# Build docker image and push to ecr
# From folder: ../login
module "ecr_login_image" {
  source = "./.terraform/modules/ecr_booking_image"

  # Absolute path into the service which needs to be build
  dockerfile_folder = "${path.module}/../../backend/login"

  # Tag for the builded Docker image (Defaults to ‘latest’)
  docker_image_tag = "login"

  # The region which we will log into with aws-cli
  aws_region = "ap-southeast-1"

  # ECR repository where we can push
  ecr_repository_url = aws_ecr_repository.itsa_backend.repository_url
  
  # Acquire ecr auth token only once
  depends_on = [module.ecr_booking_image]
}

### RDS ###
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "itsa_db"

  engine               = "mysql"
  engine_version       = "8.0.20"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class    = "db.t3.micro"
  
  allocated_storage = 20
  max_allocated_storage = 1000
  storage_encrypted     = true

  name     = "itsa_db"
  username = "admin"
  password = "$%MFmQilRzv2"
  port     = "3306"

  iam_database_authentication_enabled = false

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]

  backup_retention_period = 7
  skip_final_snapshot     = true

  # Database Deletion Protection
  deletion_protection     = true

  performance_insights_enabled          = false
  create_monitoring_role                = true
  monitoring_role_name = "itsa-rds-monitoring-role"
  monitoring_interval                   = 60

  multi_az               = true
  # DB subnet group
  subnet_ids = flatten([module.subnets.public_subnet_ids, module.subnets.private_subnet_ids])

  vpc_security_group_ids = [module.rds_sg.id]


  tags = {
    Owner       = "itsa-team8"
    Environment = "prod"
  }

  parameters = [
    {
      name = "character_set_client"
      value = "utf8mb4"
    },
    {
      name = "character_set_server"
      value = "utf8mb4"
    }
  ]
  
}

### Bastion Host ###

module "bastion" {
  source = "cloudposse/ec2-instance/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version     = "x.x.x"
  ssh_key_pair                = "team8project"
  instance_type               = "t2.micro"
  vpc_id                      = module.vpc.vpc_id
  security_groups             = [module.bastion_sg.id]
  subnet                      = module.subnets.public_subnet_ids[0]
  name                        = "ec2-bastion"
  namespace                   = "cloudposse"
  stage                       = "prod"

  associate_public_ip_address = true

  depends_on = [
    module.db
  ]

  user_data = <<-EOF
              #!/bin/bash
              sudo su
              sudo apt-get update
              sudo apt-get install mysql-server -y
              echo "${var.sql_script}" > script.sql
              mysql -h ${module.db.this_db_instance_address} -P ${module.db.this_db_instance_port} --user=${module.db.this_db_instance_username} --password=${module.db.this_db_instance_password} < script.sql
              EOF
}

######################### END OF BACKEND #########################