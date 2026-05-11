# AI StoryCast

Serverless Text-to-Audio publishing platform using Amazon Polly async synthesis.

## Services Used

- Amazon S3 (`input/` and `output/` prefixes)
- AWS Lambda (4 functions)
- IAM (least-privilege Lambda execution roles)
- Amazon Polly (`StartSpeechSynthesisTask`)
- API Gateway (upload URL + status APIs)
- DynamoDB (job metadata)
- SNS + EventBridge (completion signaling)
- CloudWatch Logs
- Optional CloudFront (audio distribution)

## Architecture

```text
[Web UI / Client]
    |
    | POST /jobs/upload-url
    v
[API Gateway] -> [GeneratePresignedUploadUrlLambda] -> [DynamoDB Jobs]
    |
    | presigned PUT URL
    v
[Client uploads .txt] -> [S3 Input Bucket: input/*.txt]
                              |
                              | S3 Event
                              v
                      [StartNarrationJobLambda]
                              |
                              | StartSpeechSynthesisTask (mp3 + speech marks)
                              v
                           [Amazon Polly]
                              |
                              | writes artifacts
                              v
                    [S3 Output Bucket: output/{jobId}/...]
                              |
                              | Polly Task State Change
                              v
                     [EventBridge Rule]
                              |
                              v
                  [PollyTaskStatusUpdaterLambda]
                    |                |
                    v                v
             [DynamoDB Jobs]      [SNS Notification]

[Client] -> GET /jobs/{jobId} -> [CheckNarrationStatusLambda] -> job status + presigned audio URL
```

## Lambda Functions

1. `GeneratePresignedUploadUrlLambda`
- API: `POST /jobs/upload-url`
- Creates `jobId`
- Stores initial metadata in DynamoDB
- Returns presigned S3 PUT URL

2. `StartNarrationJobLambda`
- Trigger: S3 `ObjectCreated` on `input/*.txt`
- Reads text file
- Starts Polly async task for MP3
- Starts Polly async task for speech marks JSON
- Updates DynamoDB job record

3. `CheckNarrationStatusLambda`
- API: `GET /jobs/{jobId}`
- Returns current status
- Returns presigned output URLs when available

4. `PollyTaskStatusUpdaterLambda` (supporting)
- Trigger: EventBridge (`Polly Synthesis Task State Change`)
- Updates job to `COMPLETED` / `FAILED`
- Publishes SNS notification on completion

## API

### 1) Create upload URL
`POST /jobs/upload-url`

Request body:

```json
{
  "filename": "my-story.txt",
  "voiceId": "Joanna",
  "languageCode": "en-US",
  "useSsml": false
}
```

Response:

```json
{
  "jobId": "uuid",
  "uploadUrl": "https://...",
  "inputKey": "input/uuid.txt",
  "expiresInSeconds": 900
}
```

### 2) Check status
`GET /jobs/{jobId}`

Response:

```json
{
  "jobId": "uuid",
  "status": "COMPLETED",
  "voiceId": "Joanna",
  "languageCode": "en-US",
  "audioUrl": "https://...",
  "captionsUrl": "https://...",
  "errorMessage": null,
  "createdAt": "...",
  "updatedAt": "..."
}
```

## Deploy

Prerequisites:
- AWS CLI configured
- SAM CLI installed
- `uv` installed

```bash
cd /Users/prabesh/Developer/ai-storycast
uv sync --all-groups
uv run ruff check .
sam build
sam deploy --guided
```

Suggested `sam deploy --guided` values:
- Stack Name: `ai-storycast`
- AWS Region: e.g. `us-east-1`
- Parameter `ProjectName`: `ai-storycast`
- Parameter `EnableCloudFront`: `false` (enable later if needed)
- Confirm changeset: `Y`
- Save arguments: `Y`

Get outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name ai-storycast \
  --query "Stacks[0].Outputs"
```

## Run End-to-End

1. Open `web/index.html` in browser.
2. Paste `ApiBaseUrl` stack output.
3. Enter text + voice options.
4. Submit job.
5. Wait for status to become `COMPLETED`.
6. Play generated MP3 in embedded player.

## Portfolio Features Included

- Voice selection (`Joanna`, `Matthew`, `Amy`)
- Language selection (`en-US`, `en-GB`)
- SSML mode toggle (podcast mode)
- Speech marks JSON generation (captions timing metadata)
- SNS notification on audio completion
- Public-player-ready static page (`web/index.html`)
- Optional CloudFront distribution for output bucket

## Security Notes

- Buckets use SSE-S3 encryption and block public access.
- Uploads are only through short-lived presigned URLs.
- Output access is via presigned GET URLs or optional CloudFront.
- Lambda permissions are scoped to required actions/resources.

### 3) Bonus: Create podcast from blog URL
`POST /jobs/from-url`

Request body:

```json
{
  "url": "https://example.com/blog-post",
  "voiceId": "Joanna",
  "languageCode": "en-US",
  "useSsml": false
}
```

Behavior:
- Lambda fetches and parses the article HTML.
- Extracted text is saved to `input/{jobId}.txt`.
- Existing S3-triggered Polly workflow runs automatically.

## Cleanup

```bash
sam delete --stack-name ai-storycast
```

If buckets are not empty, empty them first:

```bash
aws s3 rm s3://<input-bucket-name> --recursive
aws s3 rm s3://<output-bucket-name> --recursive
```

## Bonus Implemented: Blog URL to Podcast

- New Lambda: `CreateJobFromUrlLambda`
- New endpoint: `POST /jobs/from-url`
- URL validation + HTML fetch + text extraction
- Stores source URL in DynamoDB metadata
- Reuses the same Polly async pipeline through S3 event trigger
