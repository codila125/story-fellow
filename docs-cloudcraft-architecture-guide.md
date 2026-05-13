# Cloudcraft Architecture Drawing Guide - AI StoryCast

Use this exact layout in Cloudcraft.

## Canvas Grid

1. Top row = Client/API
2. Middle row = Processing
3. Bottom row = Storage/Delivery

## Top Row (left to right)

1. `User / Web Client` (custom text/icon) at top-left
2. `API Gateway` at top-center
3. `CloudFront (Optional)` at top-right

Connections:

1. `User -> API Gateway` label: `POST /jobs/upload-url, POST /jobs/from-url, GET /jobs/{jobId}`
2. `User -> CloudFront` label: `Play/Download MP3 (optional CDN)`

## Middle Row (left to right)

1. `GeneratePresignedUploadUrlLambda` under API Gateway (left-middle)
2. `CreateJobFromUrlLambda` next to it (mid-left)
3. `StartNarrationJobLambda` center-middle
4. `Amazon Polly` right-middle
5. `EventBridge` far-right-middle
6. `PollyTaskStatusUpdaterLambda` below EventBridge (right-lower-middle)
7. `CheckNarrationStatusLambda` below API Gateway (mid-lower)

Connections:

1. `API Gateway -> GeneratePresignedUploadUrlLambda` label: `POST /jobs/upload-url`
2. `API Gateway -> CreateJobFromUrlLambda` label: `POST /jobs/from-url`
3. `API Gateway -> CheckNarrationStatusLambda` label: `GET /jobs/{jobId}`
4. `CreateJobFromUrlLambda -> S3 Input` label: `PutObject input/{jobId}.txt`
5. `S3 Input -> StartNarrationJobLambda` label: `ObjectCreated input/*.txt`
6. `StartNarrationJobLambda -> Polly` label: `StartSpeechSynthesisTask (mp3 + speech marks)`
7. `Polly -> EventBridge` label: `Polly Synthesis Task State Change`
8. `EventBridge -> PollyTaskStatusUpdaterLambda`
9. `CheckNarrationStatusLambda -> DynamoDB Jobs` label: `GetItem`
10. `CheckNarrationStatusLambda -> S3 Output` label: `Presigned GET URL`

## Bottom Row (left to right)

1. `S3 Input Bucket` bottom-left, name: `...-input` + note `prefix: input/`
2. `DynamoDB` bottom-center-left, name: `ai-storycast-jobs`
3. `S3 Output Bucket` bottom-center-right, name: `...-output` + note `prefix: output/`
4. `SNS Topic` bottom-right, name: `ai-storycast-notifications`
5. `CloudWatch Logs` bottom-far-right (or side note)

Connections:

1. `GeneratePresignedUploadUrlLambda -> DynamoDB Jobs` label: `PutItem (job metadata)`
2. `GeneratePresignedUploadUrlLambda -> S3 Input` label: `Presigned PUT URL generated`
3. `StartNarrationJobLambda -> DynamoDB Jobs` label: `UpdateItem (PROCESSING/SUBMITTED)`
4. `Polly -> S3 Output` label: `Write MP3 + speech marks JSON`
5. `PollyTaskStatusUpdaterLambda -> DynamoDB Jobs` label: `UpdateItem (COMPLETED/FAILED)`
6. `PollyTaskStatusUpdaterLambda -> SNS Topic` label: `Publish completion event`
7. `S3 Output -> CloudFront (Optional)` label: `Origin for audio delivery`
8. `All Lambdas -> CloudWatch Logs` (can be one grouped arrow or annotation)

## Visual Polish

1. Color group boxes:
- Blue: API/Ingress
- Orange: Compute/Orchestration
- Green: Storage/Data
- Purple: Notifications/Observability
2. Add a legend:
- Solid arrows = synchronous calls
- Dashed arrows = events/async
3. Add one security note box:
- "Least privilege IAM roles, encrypted S3, presigned URLs, private buckets"
