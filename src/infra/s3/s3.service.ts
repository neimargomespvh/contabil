import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { createHash } from 'crypto';
import { Readable } from 'stream';

@Injectable()
export class S3Service {
  private readonly logger = new Logger(S3Service.name);
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(config: ConfigService) {
    this.bucket = config.get<string>('aws.s3Bucket')!;
    this.client = new S3Client({
      region: config.get<string>('aws.region')!,
      endpoint: config.get<string>('aws.endpoint'),
      forcePathStyle: config.get<boolean>('aws.forcePathStyle'),
      credentials: {
        accessKeyId: config.get<string>('aws.accessKeyId') ?? '',
        secretAccessKey: config.get<string>('aws.secretAccessKey') ?? '',
      },
    });
  }

  async upload(key: string, body: Buffer | Readable | string, contentType = 'application/octet-stream') {
    const buffer = Buffer.isBuffer(body) ? body
      : typeof body === 'string' ? Buffer.from(body)
      : await this.streamToBuffer(body);
    const hash = createHash('sha256').update(buffer).digest('hex');
    await this.client.send(new PutObjectCommand({
      Bucket: this.bucket, Key: key, Body: buffer, ContentType: contentType, Metadata: { hash },
    }));
    return { key, hash };
  }

  async download(key: string): Promise<Buffer> {
    const res = await this.client.send(new GetObjectCommand({ Bucket: this.bucket, Key: key }));
    return this.streamToBuffer(res.Body as Readable);
  }

  async exists(key: string): Promise<boolean> {
    try { await this.client.send(new HeadObjectCommand({ Bucket: this.bucket, Key: key })); return true; }
    catch { return false; }
  }

  async delete(key: string): Promise<void> {
    await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
  }

  async presignedUrl(key: string, expiresIn = 3600): Promise<string> {
    return getSignedUrl(this.client, new GetObjectCommand({ Bucket: this.bucket, Key: key }), { expiresIn });
  }

  private async streamToBuffer(stream: Readable): Promise<Buffer> {
    const chunks: Buffer[] = [];
    for await (const c of stream) chunks.push(Buffer.isBuffer(c) ? c : Buffer.from(c));
    return Buffer.concat(chunks);
  }
}
