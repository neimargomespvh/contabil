export default () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  database: { url: process.env.DATABASE_URL },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '15m',
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '7d',
  },
  aws: {
    region: process.env.AWS_REGION ?? 'sa-east-1',
    endpoint: process.env.AWS_ENDPOINT,
    s3Bucket: process.env.AWS_S3_BUCKET ?? 'contabil-docs',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    forcePathStyle: process.env.AWS_FORCE_PATH_STYLE === 'true',
  },
  redis: {
    url: process.env.REDIS_URL ?? 'redis://localhost:6379',
    prefix: process.env.REDIS_PREFIX ?? 'contabil:',
  },
  throttle: {
    ttl: parseInt(process.env.THROTTLE_TTL ?? '60', 10),
    limit: parseInt(process.env.THROTTLE_LIMIT ?? '120', 10),
  },
  cors: { origin: (process.env.CORS_ORIGIN ?? '*').split(',') },
});
