# Define CloudWatch Alarms for Autoscaling Groups

# Autoscaling - Scaling Policy for High CPU
resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "asg-policy"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.dev_autoscaling_group.name
}

# Cloud Watch Alarm to trigger the above scaling policy when CPU Utilization is above 80%
# Also send the notificaiton email to users present in SNS Topic Subscription
resource "aws_cloudwatch_metric_alarm" "asg_cwa_cpu" {
  alarm_name          = "ASG-CWA-CPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.dev_autoscaling_group.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization and triggers the ASG Scaling policy to scale-out if CPU is above 80%"

  ok_actions = [aws_sns_topic.asg_sns_topic.arn]
  alarm_actions = [
    aws_autoscaling_policy.asg_policy.arn,
    aws_sns_topic.asg_sns_topic.arn
  ]
}
