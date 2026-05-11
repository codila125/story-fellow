import json
import os
import uuid
from datetime import UTC, datetime

import boto3

s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["JOB_TABLE_NAME"]
INPUT_BUCKET = os.environ["INPUT_BUCKET_NAME"]


def _response(status_code: int, payload: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(payload),
    }


def handler(event, context):
    body = json.loads(event.get("body") or "{}")
    filename = body.get("filename", "story.txt")
    voice_id = body.get("voiceId", "Joanna")
    language_code = body.get("languageCode", "en-US")
    use_ssml = bool(body.get("useSsml", False))

    if not filename.endswith(".txt"):
        return _response(400, {"message": "Only .txt uploads are supported."})

    job_id = str(uuid.uuid4())
    object_key = f"input/{job_id}.txt"
    now = datetime.now(UTC).isoformat()

    table = dynamodb.Table(TABLE_NAME)
    table.put_item(
        Item={
            "jobId": job_id,
            "status": "UPLOAD_URL_GENERATED",
            "inputKey": object_key,
            "filename": filename,
            "voiceId": voice_id,
            "languageCode": language_code,
            "useSsml": use_ssml,
            "createdAt": now,
            "updatedAt": now,
        }
    )

    upload_url = s3_client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": INPUT_BUCKET,
            "Key": object_key,
            "ContentType": "text/plain",
        },
        ExpiresIn=900,
    )

    return _response(
        200,
        {
            "jobId": job_id,
            "uploadUrl": upload_url,
            "inputKey": object_key,
            "expiresInSeconds": 900,
        },
    )
