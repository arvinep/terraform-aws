resource "aws_iam_role" "test_role" {
    name = "test_role"
    assume_role_policy = <<EOF
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
EOF
}

resource "aws_lambda_function" "test_lambda" {
    filename = "hello_world.zip"
    function_name = "terraform_lambda_hello_world"
    role = "${aws_iam_role.test_role.arn}"
    handler = "hello_world.lambda_handler"
    runtime = "python2.7"
    timeout = "3"
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