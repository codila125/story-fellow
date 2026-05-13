# Story Fellow: Technical Overview

## Architecture
Story Fellow is a serverless async text-to-audio pipeline on AWS:
- API Gateway for job creation and status endpoints
- Lambda functions for upload URL generation, synthesis orchestration, status retrieval, and task updates
- S3 input/output buckets for content and generated audio artifacts
- Amazon Polly async synthesis tasks for MP3 and speech marks
- EventBridge + SNS for task completion signaling
- DynamoDB for job metadata and lifecycle state
- CloudWatch for logs and operational visibility
- AWS SAM for infrastructure packaging/deployment

## Lambda Components
- `GeneratePresignedUploadUrlLambda`: creates job and upload URL
- `StartNarrationJobLambda`: triggered by S3 upload, starts Polly tasks
- `CheckNarrationStatusLambda`: returns current job state and output URLs
- `PollyTaskStatusUpdaterLambda`: processes Polly task state change events
- `CreateJobFromUrlLambda`: fetches article content from URL and starts pipeline

## API Surface
- `POST /jobs/upload-url`
- `GET /jobs/{jobId}`
- `POST /jobs/from-url`

## Runtime Flow
1. Client requests upload URL.
2. Client uploads text input to S3.
3. S3 event triggers narration Lambda.
4. Polly async tasks create audio and speech marks.
5. EventBridge event triggers status updater.
6. DynamoDB stores final status and output references.
7. Client polls status endpoint and retrieves generated outputs.

## Security Controls
- Private buckets with controlled access
- Presigned URLs with time-limited access
- Least-privilege Lambda IAM permissions
- No credentials in source code

## Local Engineering Workflow
```bash
uv sync --all-groups
uv run ruff format .
uv run ruff check .
```

## Deploy
```bash
sam build
sam deploy --guided
```

## Operations
Use the existing Cloudcraft guide for visual system mapping:
- `docs-cloudcraft-architecture-guide.md`
