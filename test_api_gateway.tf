resource "aws_iam_role" "test_role" {
    name               = "test_role"
    count              = "${var.enable_redirect-lambda}"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "test-policy" {
    name   = "test-policy"
    role   = "${aws_iam_role.test_role.id}"
    count  = "${var.enable_redirect-lambda}"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_lambda_function" "test_role" {
    function_name    = "test"
    description      = "Sample Desctiptopn"
    role             = "${aws_iam_role.test_role.arn}"
    handler          = "file_name.handler"
    memory_size      = "128"
    timeout          = "3"
    filename         = "file_name.zip"
    source_code_hash = "${base64sha256(file("file_name.zip"))}"
    runtime          = "nodejs4.3"
    count            = "${var.enable_redirect-lambda}"
}

resource "aws_lambda_permission" "allow_api_gateway" {
    function_name = "${aws_lambda_function.test.function_name}"
    statement_id  = "AllowExecutionFromApiGateway"
    action        = "lambda:InvokeFunction"
    principal     = "apigateway.amazonaws.com"
    source_arn    = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.test_api.id}/*/${aws_api_gateway_integration.test-integration.integration_http_method}${aws_api_gateway_resource.test_resource.path}"
    count         = "${var.enable_redirect-lambda}"
}

resource "aws_api_gateway_rest_api" "test_api" {
  name        = "test_api"
  description = "API for test"
  count       = "${var.enable_redirect-lambda}"
}

resource "aws_api_gateway_resource" "test_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.test_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.test_api.root_resource_id}"
  path_part   = "test_resource"
  count       = "${var.enable_redirect-lambda}"
}

resource "aws_api_gateway_method" "test-get" {
  rest_api_id   = "${aws_api_gateway_rest_api.test_api.id}"
  resource_id   = "${aws_api_gateway_resource.test_resource.id}"
  http_method   = "GET"
  authorization = "NONE"
  count         = "${var.enable_redirect-lambda}"
}

resource "aws_api_gateway_integration" "test-integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.test_api.id}"
  resource_id             = "${aws_api_gateway_resource.test_resource.id}"
  http_method             = "${aws_api_gateway_method.test-get.http_method}"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${aws_lambda_function.test.function_name}/invocations"
  credentials             = "arn:aws:iam::${var.account_id}:role/test_role"
  integration_http_method = "${aws_api_gateway_method.test-get.http_method}"
  count                   = "${var.enable_redirect-lambda}"
}

resource "aws_api_gateway_method_response" "302" {
  rest_api_id                 = "${aws_api_gateway_rest_api.test_api.id}"
  resource_id                 = "${aws_api_gateway_resource.test_resource.id}"
  http_method                 = "${aws_api_gateway_method.test-get.http_method}"
  status_code                 = "302"
  count                       = "${var.enable_redirect-lambda}"
  response_parameters_in_json = <<PARAMS
  {
    "method.response.header.Location": true
  }
PARAMS
}

resource "aws_api_gateway_integration_response" "test_IntegrationResponse" {
  rest_api_id                 = "${aws_api_gateway_rest_api.test_api.id}"
  resource_id                 = "${aws_api_gateway_resource.test_resource.id}"
  http_method                 = "${aws_api_gateway_method.test-get.http_method}"
  status_code                 = "${aws_api_gateway_method_response.302.status_code}"
  count                       = "${var.enable_redirect-lambda}"
  depends_on                  = ["aws_api_gateway_integration.test-integration"]
  response_parameters_in_json = <<PARAMS
  {
    "method.response.header.Location": "integration.response.body.location"
  }
PARAMS
}

resource "aws_api_gateway_deployment" "test_deploy" {
  depends_on  = ["aws_api_gateway_integration.test-integration"]
  stage_name  = "beta"
  rest_api_id = "${aws_api_gateway_rest_api.test_api.id}"
  count       = "${var.enable_redirect-lambda}"
}
