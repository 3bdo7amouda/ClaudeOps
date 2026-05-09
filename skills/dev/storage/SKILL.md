# skill: dev/storage
# triggers: storage, s3, upload, file, presigned url, cdn, cloudfront, image processing, object storage, supabase storage

## S3 — Presigned Upload (recommended pattern)
```typescript
import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'

const s3 = new S3Client({ region: process.env.AWS_REGION! })
const BUCKET = process.env.S3_BUCKET!

// 1. Client requests upload URL
export async function getUploadUrl(key: string, contentType: string, maxBytes = 10_485_760) {
  const cmd = new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    ContentType: contentType,
    ContentLengthRange: [1, maxBytes],   // enforce size limit
  })
  return getSignedUrl(s3, cmd, { expiresIn: 300 })  // 5 min
}

// 2. Client uploads directly to S3 (no bandwidth through your server)
// PUT <presigned-url>  Content-Type: image/jpeg  Body: <file>

// 3. Confirm upload and save reference
export async function confirmUpload(key: string, userId: string) {
  const head = await s3.send(new HeadObjectCommand({ Bucket: BUCKET, Key: key }))
  await db.files.create({ data: { key, userId, size: head.ContentLength, mimeType: head.ContentType } })
  return { url: `${process.env.CDN_URL}/${key}` }
}
```

## Key Naming Strategy
```typescript
// Structure: {orgId}/{resource}/{date}/{uuid}.{ext}
const key = `${orgId}/avatars/${format(new Date(), 'yyyy/MM')}/${crypto.randomUUID()}.jpg`

// Public assets: behind CDN
const publicKey  = `public/${key}`
// Private assets: require signed URLs to access
const privateKey = `private/${orgId}/${key}`
```

## CloudFront CDN Setup
```hcl
# terraform
resource "aws_cloudfront_distribution" "assets" {
  origin {
    domain_name = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id   = "S3-assets"
    s3_origin_config { origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path }
  }
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-assets"
    forwarded_values { query_string = false; cookies { forward = "none" } }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }
}
```

## Image Processing (Sharp)
```typescript
import sharp from 'sharp'

export async function processUploadedImage(inputBuffer: Buffer, options = { width: 1200, quality: 85 }) {
  const [full, thumb] = await Promise.all([
    sharp(inputBuffer).resize(options.width).webp({ quality: options.quality }).toBuffer(),
    sharp(inputBuffer).resize(300, 300, { fit: 'cover' }).webp({ quality: 75 }).toBuffer(),
  ])
  return { full, thumb }
}

// Upload variants
await Promise.all([
  s3.send(new PutObjectCommand({ Bucket: BUCKET, Key: `${key}/full.webp`, Body: full, ContentType: 'image/webp' })),
  s3.send(new PutObjectCommand({ Bucket: BUCKET, Key: `${key}/thumb.webp`, Body: thumb, ContentType: 'image/webp' })),
])
```

## Private File Access (signed download URL)
```typescript
export async function getDownloadUrl(key: string, userId: string, expiresIn = 900) {
  const file = await db.files.findFirst({ where: { key, userId } })  // ownership check
  if (!file) throw new Error('Not found or unauthorized')
  return getSignedUrl(s3, new GetObjectCommand({ Bucket: BUCKET, Key: key }), { expiresIn })
}
```

## Rules
- Never upload through your server — use presigned URLs (saves bandwidth + cost)
- Always validate file type server-side (not just extension) using `file-type` package
- Set `ContentLengthRange` on presigned URLs to enforce size limits
- Separate buckets for public assets (CDN) and private files (signed URLs)
- Enable S3 versioning for user-generated content
- Lifecycle rules: delete incomplete multipart uploads after 7 days
```typescript
// File type validation (server-side)
import { fileTypeFromBuffer } from 'file-type'
const type = await fileTypeFromBuffer(buffer)
if (!['image/jpeg', 'image/png', 'image/webp'].includes(type?.mime ?? '')) {
  throw new Error('Invalid file type')
}
```
