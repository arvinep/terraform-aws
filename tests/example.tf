# variable "region" {
#     default = "eu-west-1"
# }
# variable "amis" {
# 	default = {}
# }
#
# output "ami" {
#   value = "${lookup(var.amis, var.region)}"
# }
#
# resource "aws_instance" "example" {
#   ami           = "ami-b0ac25c3"
#   instance_type = "t2.micro"
# }

# variable "access_key" {}
# variable "secret_key" {}
# variable "region" {}
# variable "puppetmaster" {}
# variable "aws_vpc-portal-id" {}
# variable "aws_vpc-portal-cidr_block" {}
# variable "aws_subnet-public1-id" {}
# variable "aws_subnet-public2-id" {}
# variable "aws_subnet-private1-id" {}
# variable "aws_subnet-private2-id" {}
# variable "aws_key_pair-ops-key-key_name" {}
# variable "aws_route53_ttl" { default = "60" }
# variable "aws_route53_zone-portal1-zone_id" {}
# variable "aws_route53_zone-portal1-domain" {}
# variable "aws_route53_zone-portal2-zone_id" {}
# variable "aws_route53_zone-portal2-domain" {}
# variable "aws_subnet-private1-availability_zone" {}
# variable "aws_subnet-private2-availability_zone" {}
# variable "berlin_office_ips" { default = "145.253.109.240/29" }

# provider "aws" {
#     access_key = "${var.access_key}"
#     secret_key = "${var.secret_key}"
#     region     = "${var.region}"
# }


resource "aws_s3_bucket_object" "object" {
    bucket = "arvinep"
    key = "new_object_key"
    source = "/vagrant/check_foo2.zip"
    etag = "${md5(file("/vagrant/check_foo2.zip"))}"
}


resource "aws_iam_role" "iam_for_lambda_foo" {
    name = "iam_for_lambda_foo"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# resource "aws_lambda_function" "ecs_ecs_autoscale_lambda" {
#   s3_bucket = "${aws_s3_bucket.lambda_bucket.id}"
#   s3_key = "ecs_autoscale.zip"
#   function_name = "issues_ecs_service_autoscale"
#   role = "${aws_iam_role.issues_ecs_autoscale_lambda_role.arn}"
#   runtime = "nodejs"
#   timeout = "8"
#   handler = "example.handler"
# }

resource "aws_lambda_function" "check_foo" {
	# filename - (Optional) A zip file containing your lambda function source code. If defined, The s3_* options cannot be used.
	# s3_bucket - (Optional) The S3 bucket location containing your lambda function source code. Conflicts with filename.
	# s3_key - (Optional) The S3 key containing your lambda function source code. Conflicts with filename.
	# s3_object_version - (Optional) The object version of your lambda function source code. Conflicts with filename.
	# function_name - (Required) A unique name for your Lambda Function.
	# handler - (Required) The function entrypoint in your code.
	# role - (Required) IAM role attached to the Lambda Function. This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details.
	# description - (Optional) Description of what your Lambda Function does.
	# memory_size - (Optional) Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128. See Limits
	# runtime - (Optional) Defaults to nodejs. See Runtimes for valid values.
	# timeout - (Optional) The amount of time your Lambda Function has to run in seconds. Defaults to 3. See Limits
	# vpc_config - (Optional) Provide this to allow your function to access your VPC. Fields documented below. See Lambda in VPC
	# source_code_hash - (Optional) Used to trigger updates. This is only useful in conjuction with filename. The only useful value is ${base64sha256(file("file.zip"))}.
    # filename = "/vagrant/check_foo.zip"
    s3_bucket = "arvinep"
    s3_key = "check_foo.zip"
    function_name = "checkFoo"
    description = "my desctipt2"
    # role = "arn:aws:iam::424242:role/something"
    role = "${aws_iam_role.iam_for_lambda_foo.arn}"
    # handler = "index.handler"
    # handler = "lambda_function.lambda_handler"
    handler = "hello_world.lambda_handler"
    runtime = "python2.7"
}

resource "aws_lambda_permission" "allow_api_gateway" {
    function_name = "${aws_lambda_function.test_lambda.function_name}"
    statement_id = "AllowExecutionFromApiGateway"
    action = "lambda:InvokeFunction"
    principal = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.test_api.id}/*/${aws_api_gateway_integration.test_test-get-integration.integration_http_method}${aws_api_gateway_resource.test_test.path}"
}

#resource "aws_lambda_alias" "test_alias" {
#    name = "testalias"
#    description = "a sample description"
#    function_name = "${aws_lambda_function.test_lambda.arn}"
#    function_version = "$LATEST"
#}

resource "aws_api_gateway_rest_api" "test_api" {
  name = "TestAPI"
  description = "This is the Test API"
}

resource "aws_api_gateway_resource" "test" {
  rest_api_id = "${aws_api_gateway_rest_api.test_api.id}"
  parent_id = "${aws_api_gateway_rest_api.test_api.root_resource_id}"
  path_part = "test"
}

resource "aws_api_gateway_resource" "test_test" {
  rest_api_id = "${aws_api_gateway_rest_api.test_api.id}"
  parent_id = "${aws_api_gateway_resource.test.id}"
  path_part = "test"
}

resource "aws_api_gateway_method" "test_test-get" {
  rest_api_id = "${aws_api_gateway_rest_api.test_api.id}"
  resource_id = "${aws_api_gateway_resource.test_test.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test_test-get-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.test_api.id}"
  resource_id = "${aws_api_gateway_resource.test_test.id}"
  http_method = "${aws_api_gateway_method.test_test-get.http_method}"
  type = "AWS"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${aws_lambda_function.test_lambda.function_name}/invocations"
  integration_http_method = "${aws_api_gateway_method.test_test-get.http_method}"
}


# resource "aws_cloudwatch_event_rule" "every_five_minutes" {
#     name = "every-five-minutes"
#     description = "Fires every five minutes"
#     schedule_expression = "rate(5 minutes)"
# }

# resource "aws_cloudwatch_event_target" "check_foo_every_five_minutes" {
#     rule = "${aws_cloudwatch_event_rule.every_five_minutes.name}"
#     target_id = "check_foo"
#     arn = "${aws_lambda_function.check_foo.arn}"
# }

# resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
#     statement_id = "AllowExecutionFromCloudWatch"
#     action = "lambda:InvokeFunction"
#     function_name = "${aws_lambda_function.check_foo.function_name}"
#     principal = "events.amazonaws.com"
#     source_arn = "${aws_cloudwatch_event_rule.every_five_minutes.arn}"
# }
