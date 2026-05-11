import json
import os

import boto3

s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["JOB_TABLE_NAME"]
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET_NAME"]


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
    job_id = (event.get("pathParameters") or {}).get("jobId")
    if not job_id:
        return _response(400, {"message": "jobId is required."})

    table = dynamodb.Table(TABLE_NAME)
    item = table.get_item(Key={"jobId": job_id}).get("Item")

    if not item:
        return _response(404, {"message": "Job not found."})

    audio_url = None
    captions_url = None

    audio_key = item.get("audioKey")
    captions_key = item.get("captionsKey")

    if audio_key:
        audio_url = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": OUTPUT_BUCKET, "Key": audio_key},
            ExpiresIn=3600,
        )

    if captions_key:
        captions_url = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": OUTPUT_BUCKET, "Key": captions_key},
            ExpiresIn=3600,
        )

    payload = {
        "jobId": job_id,
        "status": item.get("status"),
        "voiceId": item.get("voiceId"),
        "languageCode": item.get("languageCode"),
        "audioUrl": audio_url,
        "captionsUrl": captions_url,
        "errorMessage": item.get("errorMessage"),
        "createdAt": item.get("createdAt"),
        "updatedAt": item.get("updatedAt"),
    }

    return _response(200, payload)
