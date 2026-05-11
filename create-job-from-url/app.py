import json
import os
import re
import uuid
from datetime import UTC, datetime
from html import unescape
from html.parser import HTMLParser
from urllib.parse import urlparse
from urllib.request import Request, urlopen

import boto3

s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["JOB_TABLE_NAME"]
INPUT_BUCKET = os.environ["INPUT_BUCKET_NAME"]


class ParagraphExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self._capture_stack = []
        self._chunks = []

    def handle_starttag(self, tag, attrs):
        if tag in {"p", "article", "h1", "h2", "h3", "li"}:
            self._capture_stack.append(tag)

    def handle_endtag(self, tag):
        if self._capture_stack and self._capture_stack[-1] == tag:
            self._capture_stack.pop()
            self._chunks.append("\n")

    def handle_data(self, data):
        if self._capture_stack:
            text = data.strip()
            if text:
                self._chunks.append(text)
                self._chunks.append(" ")

    def get_text(self):
        raw = unescape("".join(self._chunks))
        raw = re.sub(r"\s+", " ", raw)
        raw = re.sub(r" ?\n ?", "\n", raw)
        return raw.strip()


def _response(status_code: int, payload: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(payload),
    }


def _validate_url(url: str) -> bool:
    parsed = urlparse(url)
    return parsed.scheme in {"http", "https"} and bool(parsed.netloc)


def _extract_article_text(html: str) -> str:
    parser = ParagraphExtractor()
    parser.feed(html)
    text = parser.get_text()
    return text[:100000]


def _fetch_html(url: str) -> str:
    req = Request(
        url,
        headers={
            "User-Agent": "AI-StoryCast/1.0 (+serverless-polly-pipeline)",
        },
    )
    with urlopen(req, timeout=20) as response:  # nosec B310
        content_type = response.headers.get("Content-Type", "")
        if "text/html" not in content_type:
            raise ValueError(f"URL did not return HTML content. Content-Type: {content_type}")
        return response.read().decode("utf-8", errors="ignore")


def handler(event, context):
    body = json.loads(event.get("body") or "{}")
    source_url = body.get("url")
    voice_id = body.get("voiceId", "Joanna")
    language_code = body.get("languageCode", "en-US")
    use_ssml = bool(body.get("useSsml", False))

    if not source_url or not _validate_url(source_url):
        return _response(400, {"message": "A valid http/https URL is required."})

    try:
        html = _fetch_html(source_url)
        extracted_text = _extract_article_text(html)
    except Exception as exc:
        return _response(400, {"message": "Failed to fetch or parse URL.", "error": str(exc)})

    if len(extracted_text) < 50:
        return _response(422, {"message": "Not enough article text could be extracted."})

    job_id = str(uuid.uuid4())
    object_key = f"input/{job_id}.txt"
    now = datetime.now(UTC).isoformat()

    table = dynamodb.Table(TABLE_NAME)
    table.put_item(
        Item={
            "jobId": job_id,
            "status": "UPLOADED_FROM_URL",
            "inputKey": object_key,
            "filename": f"article-{job_id}.txt",
            "sourceUrl": source_url,
            "voiceId": voice_id,
            "languageCode": language_code,
            "useSsml": use_ssml,
            "createdAt": now,
            "updatedAt": now,
        }
    )

    s3_client.put_object(
        Bucket=INPUT_BUCKET,
        Key=object_key,
        Body=extracted_text.encode("utf-8"),
        ContentType="text/plain",
    )

    return _response(
        202,
        {
            "jobId": job_id,
            "status": "UPLOADED_FROM_URL",
            "inputKey": object_key,
            "sourceUrl": source_url,
            "extractedCharacters": len(extracted_text),
            "message": "Article text stored. Polly pipeline will start via S3 trigger.",
        },
    )
