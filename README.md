# Project
This repository contains your submissions for the project.

Note that this repo is writable by you. Any changes you or your team members made in this repo can be pushed to origin.

If you have changes or discover issues, you can also create an issue.


Architecture Deployment.

Infrastructure as Code:
Services Deployed:
- Route53
- Cloudfront
- Lambda
- API Gateway
- S3
- RDS
- Bastion Host
- ECR Docker Images
Terraform:
NOTE:
1. kaligo_inventory_prod_destinations.csv & kaligo_inventory_prod_hotels.csv must be available initial-app/aws-resources/merged/data (File is too big in size to be uploaded.)

STEPS:
1. cd initial-app/aws-resources/merged
2. terraform init
3. terraform apply
4. enter yes to confirm deployment


Manual Deployment
Services Deployed:
- ALB
1. Create an ALB with minimum 2 public subnets across availability zones.
2. Set listeners on ports 5000 - 5002.
3. Create 3 target groups, each belonging to a respective microservice on the respective port and forwarding the traffic from the listeners to the ip addresses created by Fargate service cluster in the private subnets. Eg. booking 5000 etc.

- ECS
1. Create a cluster (Fargate) in your VPC
2. Create a task definition (Fargate) for each of the services (booking, login, register)
  1. Task memory allocation : 0.5 GB
  2. Task vCPU              : 0.25 vCPU
  3. Add container specifying the respective image from your ECR (Using Image URI)
  4. Map the port that your application runs on
  5. Add in your environment variables (Key : dbURL, Value : mysql+mysqlconnector://`username`:`password`@`your RDS endpoint`/itsa)
3. From within your cluster, create a service (Fargate)
  1. Type : REPLICA
  2. Select your VPC and the private subnets
  3. Select the ALB you have created and add your container to the ALB (*Ensure your ports are mapped properly*)
  4. Configure your auto scaling to your required setup (Min : 2, Max : 6 etc)

- WAF
1. Create a new WAF web ACL
2. Resource type should be set to CloudFront distributions
3. Rules to be added are:
  - AWS-AWSManagedRulesKnownBadInputsRuleSet
  - AWS-AWSManagedRulesLinuxRuleSet
  - AWS-AWSManagedRulesSQLiRuleSet
  - AWS-AWSManagedRulesCommonRuleSet

- API Gateway (ECS)
1. Using the already created api gateway, add new resource "/backend"
2. Create "/login" resource within "/backend" with CORS enabled, METHOD: POST
  1. For the Request Validator, set to "Validate body, query string parameters, and headers"
  2. Integration should be set to HTTP, with HTTP Proxy integration checked
  3. Endpoint URL to be set to ALB endpoint with specific port. (eg. http://itsa-backend-alb-1436285058.ap-southeast-1.elb.amazonaws.com:5002/login )
3. Create a HTTP Proxy resource
  1. Name it "/{registration+} with CORS enabled
  2. Set integration type to be HTTP with HTTP Proxy integration checked
  3. Endpoint URL to be set to ALB endpoint with specific port. (eg. http://itsa-backend-alb-1436285058.ap-southeast-1.elb.amazonaws.com:5001/{registration} )
4. Create "/booking" resource and a GET method and enable CORS.
  1. Add a Required HTTP Request Header -> Name: Authorization
  2. For the Request Validator, set to "Validate body, query string parameters, and headers"
  3. Integration should be set to HTTP, with HTTP Proxy integration checked
  4. Endpoint URL to be set to ALB endpoint with specific port. (eg. http://itsa-backend-alb-1436285058.ap-southeast-1.elb.amazonaws.com:5000/booking )
5. Under "/booking" create a new HTTP Proxy resource
  1. Name it "/{proxy+} with CORS enabled
  2. Set integration type to be HTTP with HTTP Proxy integration checked
  3. Endpoint URL to be set to ALB endpoint with specific port. (eg. http://itsa-backend-alb-1436285058.ap-southeast-1.elb.amazonaws.com:5000/booking/{proxy} )
