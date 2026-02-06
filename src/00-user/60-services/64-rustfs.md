# RustFS (S3)

[RustFS](https://rustfs.com/) offers open source S3 compatible object storage, taking over the space that MinIO used to fill.

See [tests/rustfs](https://github.com/MaayanLab/k8s-docs/tree/main/tests/rustfs) for complete template.

## Adding rustfs to your app's docker-compose.yaml

```yaml
services:
  # ...
  yourapp-rustfs:
    image: rustfs/rustfs:latest
    pull_policy: missing
    restart: unless-stopped
    environment:
    - RUSTFS_ACCESS_KEY=rustfs
    # this should be in your .env file and set to a long random string
    - RUSTFS_SECRET_KEY
    - RUSTFS_CONSOLE_ENABLE=true
    - RUSTFS_SERVER_DOMAINS=s3.yourapp.k8s.dev.maayanlab.cloud
    ports:
    - target: 9000
      published: 9000
      x-kubernetes:
        annotations:
          maayanlab.cloud/ingress: https://s3.yourapp.k8s.dev.maayanlab.cloud
    - target: 9001
      published: 9001
      x-kubernetes:
        annotations:
          maayanlab.cloud/ingress: https://console.s3.yourapp.k8s.dev.maayanlab.cloud
    volumes:
    - yourapp-rustfs-data:/data

volumes:
  yourapp-rustfs-data:
    x-kubernetes:
      size: 1Gi
      class: local-path
```

## Transfering your local database to the production database
```bash
# copy file from docker rustfs onto your system
docker compose cp yourapp-rustfs:/data data
# copy file from your system up to the cloud (the -T option is necessary for this particular image)
kube-compose cp -T data yourapp-rustfs:/data

# copy file from cluster rustfs onto your system
kube-compose cp -T yourapp-rustfs:/data data
# copy file from your system up to the cloud (the -T option is necessary for this particular image)
docker compose cp data yourapp-rustfs:/data
```

## Accessing the database in your app

The database will be accessible at the hostname corresponding to your service name, but it's best practice to set up an environment variable to specify the location. For example, in python:

- `.env`:
  ```
  # so you can test accessing the database locally
  S3_URL=http://rustfs:RUSTFS_SECRET_KEY@localhost:9000/yourbucket
  PUBLIC_S3_URL=http://localhost:9000/yourbucket
  ```
- `docker-compose.yaml`:
  ```yaml
  services:
    yourapp-app:
      environment:
      # so your app container goes to the right location, **NOT localhost**
      - S3_URL=http://rustfs:${RUSTFS_SECRET_KEY}$@yourapp-rustfs:9000/yourbucket
      - PUBLIC_S3_URL=https://s3.yourapp.k8s.dev.maayanlab.cloud
  ```
- `app.py`:
  ```python
  import os
  import io
  import json
  import dotenv
  from minio import Minio
  from urllib.parse import urlparse

  dotenv.load_dotenv()

  # connect to db
  S3_URL_parsed = urlparse(os.environ['S3_URL'])
  s3 = Minio(
    f"{S3_URL_parsed.hostname}:{S3_URL_parsed.port}",
    access_key=f"{S3_URL_parsed.username}",
    secret_key=f"{S3_URL_parsed.password}",
    secure=S3_URL_parsed.scheme == 'https',
  )

  # create the bucket if it doesn't exist
  bucket, _, _ = S3_URL_parsed.path[1:].partition('/')
  if not s3.bucket_exists(bucket):
    s3.make_bucket(bucket)
    # enable anonymous downloading of files in this bucket
    s3.set_bucket_policy(bucket, json.dumps({
      'Version': '2012-10-17',
      'Statement': [
        {'Effect': 'Allow', 'Principal': {'AWS': '*'}, 'Action': 's3:GetBucketLocation', 'Resource': f"arn:aws:s3:::{bucket}"},
        {'Effect': 'Allow', 'Principal': {'AWS': '*'}, 'Action': 's3:GetObject', 'Resource': f"arn:aws:s3:::{bucket}/*"},
      ],
    }))
    # create a file
    content = b'Hello World!'
    s3.put_object(bucket, 'test.txt', io.BytesIO(content), len(content), content_type='plain/text')
    print(f"File available at <{os.environ['PUBLIC_S3_URL']}/test.txt>")

  # ... use s3 in your app deal with files ...
  ```

## Configuring public file access through the console

Visit
<https://console.s3.yourapp.k8s.dev.maayanlab.cloud> (replacing with your url)

Log in with your RUSTFS_ACCESS_KEY & RUSTFS_SECRET_KEY.

Under the bucket settings, edit the "Access Policy," select custom and put:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "s3:GetBucketLocation",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::yourbucket/*"
      ]
    }
  ]
}
```
