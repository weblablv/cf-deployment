# EC2 PHP app deployment

How crm, landing, and booking are packaged and installed on EC2 via AWS CodeDeploy.

`config.php` in the app root is required. Runtime config is `.env` (from `.env.dist` + CI env). TLS is terminated at CloudFront; this image does not copy SSL certs or `local.config.php` from S3.

```
CI container
  1. Validate repo + env
  2. Strip Git / pipeline files
  3. Write .env, CodeDeploy hooks, root crontab
  4. Upload tarball to S3
  5. Trigger CodeDeploy (boto3) and wait
  6. Optionally invalidate CloudFront
            │
            ▼
EC2 (CodeDeploy agent)
  7. Install files → /home/production/prod/app
  8. AfterInstall → afterinstall.sh (production)
                 → afterinstallRoot.sh (root)
```

## CI container

Validation (`src/validation/index.js`):

- `local.config.php` must not be committed
- Only `.env.dist` is allowed as an env template
- `STAGE` must be set
- Branch `dev` is blocked
- `config/parameters.json` is rejected
- PHP files over 900 lines fail; JS over 900 fail, over 250 warn
- If `.env.dist` exists, every listed key must be present in the CI environment

Then `.git`, `.gitignore`, and `bitbucket-pipelines.yml` are removed.

`php-env.sh` writes `.env` from `.env.dist` (excluding AWS keys), then `.env.dist` is deleted from the artifact.

Artifact upload:

```text
s3://{S3_BUCKET}/{APP_NAME}/latest.tar.gz
```

`APP_NAME` must match the existing CodeDeploy application name (`landing-app` / `booking-app` / `crm-app`). Group `DG1`, region `eu-central-1`. On success the tarball is deleted.

If `CLOUDFRONT_DISTRIBUTION_ID` is set, `/*` is invalidated.

## On the EC2 instance

AfterInstall (production): Composer, Doctrine migrate, optional `crontab`, optional `npm ci` / gulp, then cleanup of `migrations/` and the hook script.

AfterInstall (root): `files/` ACLs, install `www.nginx` and reload nginx (no SSL files), install GeoIP updater + root crontab, optional CloudWatch / awslogs configs, cleanup of hooks.

## Required env

| Variable | Role |
|----------|------|
| `APP_NAME` | CodeDeploy app name and S3 key prefix |
| `STAGE` | Stage label |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | AWS API |
| `S3_BUCKET` | Artifact + CI log bucket |

Plus every key in `.env.dist`. Optional: `S3_LOG_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`, `BRANCH`, `BUILD_ID`, `COMMIT`.

`VALIDATE_ONLY=1` (or `true`) runs validation only, then exits. It does not delete `.git`, upload logs, package, or call CodeDeploy.
