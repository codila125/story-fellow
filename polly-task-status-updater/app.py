import json
import os
from datetime import UTC, datetime

import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

TABLE_NAME = os.environ["JOB_TABLE_NAME"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def handler(event, context):
    detail = event.get("detail", {})
    task_id = detail.get("taskId")
    task_status = detail.get("taskStatus")
    output_uri = detail.get("outputUri")
    task_output_format = detail.get("outputFormat")

    if not task_id or not task_status:
        return {"statusCode": 200, "body": json.dumps({"message": "No actionable Polly event."})}

    table = dynamodb.Table(TABLE_NAME)
    scan_response = table.scan(
        FilterExpression=Attr("pollyTaskId").eq(task_id) | Attr("speechMarksTaskId").eq(task_id)
    )
    items = scan_response.get("Items", [])
    if not items:
        return {"statusCode": 200, "body": json.dumps({"message": "No job matched Polly task."})}

    item = items[0]
    job_id = item["jobId"]
    now = datetime.now(UTC).isoformat()

    update_expression = ["SET updatedAt=:updatedAt"]
    expression_values = {":updatedAt": now}
    expression_names = {}

    if task_status == "completed":
        if task_output_format == "mp3":
            audio_key = output_uri.split(".amazonaws.com/")[-1]
            update_expression.append("audioKey=:audioKey")
            expression_values[":audioKey"] = audio_key
        elif task_output_format == "json":
            captions_key = output_uri.split(".amazonaws.com/")[-1]
            update_expression.append("captionsKey=:captionsKey")
            expression_values[":captionsKey"] = captions_key

        if item.get("audioKey") or task_output_format == "mp3":
            update_expression.append("#status=:status")
            expression_names["#status"] = "status"
            expression_values[":status"] = "COMPLETED"

    elif task_status in ["failed", "timed_out"]:
        update_expression.append("#status=:status")
        expression_names["#status"] = "status"
        expression_values[":status"] = "FAILED"
        expression_values[":errorMessage"] = detail.get("taskStatusReason", "Polly task failed")
        update_expression.append("errorMessage=:errorMessage")

    if len(update_expression) > 1:
        table.update_item(
            Key={"jobId": job_id},
            UpdateExpression=", ".join(update_expression),
            ExpressionAttributeNames=expression_names or None,
            ExpressionAttributeValues=expression_values,
        )

    if task_status == "completed" and task_output_format == "mp3":
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="AI StoryCast audio ready",
            Message=json.dumps(
                {
                    "jobId": job_id,
                    "status": "COMPLETED",
                    "audioUri": output_uri,
                }
            ),
        )

    return {"statusCode": 200, "body": json.dumps({"message": "Status processed."})}
