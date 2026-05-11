import json
import os
import urllib.parse
from datetime import UTC, datetime

import boto3
from botocore.exceptions import ClientError

s3_client = boto3.client("s3")
polly_client = boto3.client("polly")
dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["JOB_TABLE_NAME"]
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET_NAME"]
POLLY_OUTPUT_PREFIX = os.environ.get("POLLY_OUTPUT_PREFIX", "output/")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def handler(event, context):
    table = dynamodb.Table(TABLE_NAME)

    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
        if not key.startswith("input/") or not key.endswith(".txt"):
            continue

        job_id = key.replace("input/", "").replace(".txt", "")
        now = datetime.now(UTC).isoformat()

        table.update_item(
            Key={"jobId": job_id},
            UpdateExpression="SET #status=:status, updatedAt=:updatedAt",
            ExpressionAttributeNames={"#status": "status"},
            ExpressionAttributeValues={
                ":status": "PROCESSING",
                ":updatedAt": now,
            },
        )

        response = s3_client.get_object(Bucket=bucket, Key=key)
        raw_text = response["Body"].read().decode("utf-8")

        item = table.get_item(Key={"jobId": job_id}).get("Item", {})
        voice_id = item.get("voiceId", "Joanna")
        language_code = item.get("languageCode", "en-US")
        use_ssml = item.get("useSsml", False)

        text_type = "ssml" if use_ssml else "text"
        speech_text = raw_text if use_ssml else raw_text[:100000]

        output_key_prefix = f"{POLLY_OUTPUT_PREFIX}{job_id}/"

        try:
            task = polly_client.start_speech_synthesis_task(
                Engine="neural",
                LanguageCode=language_code,
                OutputFormat="mp3",
                OutputS3BucketName=OUTPUT_BUCKET,
                OutputS3KeyPrefix=output_key_prefix,
                SnsTopicArn=SNS_TOPIC_ARN,
                Text=speech_text,
                TextType=text_type,
                VoiceId=voice_id,
            )

            speech_marks_task = polly_client.start_speech_synthesis_task(
                Engine="neural",
                LanguageCode=language_code,
                OutputFormat="json",
                OutputS3BucketName=OUTPUT_BUCKET,
                OutputS3KeyPrefix=output_key_prefix,
                SpeechMarkTypes=["sentence", "word"],
                SnsTopicArn=SNS_TOPIC_ARN,
                Text=speech_text,
                TextType=text_type,
                VoiceId=voice_id,
            )

            table.update_item(
                Key={"jobId": job_id},
                UpdateExpression=(
                    "SET #status=:status, pollyTaskId=:pollyTaskId, "
                    "speechMarksTaskId=:speechMarksTaskId, "
                    "outputPrefix=:outputPrefix, updatedAt=:updatedAt"
                ),
                ExpressionAttributeNames={"#status": "status"},
                ExpressionAttributeValues={
                    ":status": "POLLY_TASK_SUBMITTED",
                    ":pollyTaskId": task["SynthesisTask"]["TaskId"],
                    ":speechMarksTaskId": speech_marks_task["SynthesisTask"]["TaskId"],
                    ":outputPrefix": output_key_prefix,
                    ":updatedAt": now,
                },
            )
        except ClientError as error:
            table.update_item(
                Key={"jobId": job_id},
                UpdateExpression=(
                    "SET #status=:status, errorMessage=:errorMessage, updatedAt=:updatedAt"
                ),
                ExpressionAttributeNames={"#status": "status"},
                ExpressionAttributeValues={
                    ":status": "FAILED",
                    ":errorMessage": str(error),
                    ":updatedAt": now,
                },
            )
            raise

    return {"statusCode": 200, "body": json.dumps({"message": "Polly jobs started."})}
