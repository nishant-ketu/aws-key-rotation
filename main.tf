provider "aws" {
  region = var.aws_region
}

# AWS Lambda Function
resource "aws_lambda_function" "key_rotation_function" {
  function_name    = var.lambda_function_name
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  filename         = var.lambda_zip_file
  role             = aws_iam_role.lambda_role.arn
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
}

# AWS IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = var.lambda_policy_attachment_name
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# AWS EventBridge Rule
resource "aws_cloudwatch_event_rule" "key_rotation_rule" {
  name                = var.eventbridge_rule_name
  description         = var.eventbridge_rule_description
  event_pattern       = var.eventbridge_event_pattern
}

# AWS EventBridge Rule Target
resource "aws_cloudwatch_event_target" "key_rotation_target" {
  rule             = aws_cloudwatch_event_rule.key_rotation_rule.name
  target_id        = var.eventbridge_target_id
  arn              = aws_lambda_function.key_rotation_function.arn
}

# AWS Lambda Permission to allow EventBridge rule to invoke Lambda
resource "aws_lambda_permission" "eventbridge_lambda_permission" {
  statement_id  = var.lambda_permission_statement_id
  action        = var.lambda_permission_action
  function_name = aws_lambda_function.key_rotation_function.function_name
  principal     = var.lambda_permission_principal
  source_arn    = aws_cloudwatch_event_rule.key_rotation_rule.arn
}
