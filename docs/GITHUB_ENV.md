# GitHub Environment inventory

Confirmed in AWS `eu-central-1` (profile `cf-prod`):

| CodeDeploy application | Deployment group |
|------------------------|------------------|
| `landing-app` | `DG1` |
| `booking-app` | `DG1` |
| `crm-app` | `DG1` |

GitHub repos: `weblablv/cf-landing`, `weblablv/cf-booking`, `weblablv/cf-crm`.
Workflows must set `APP_NAME` to the CodeDeploy slug above, not the GitHub repo name.

## Shared CI / CodeDeploy (Environment `prod`)

| Name | Kind | Known value |
|------|------|-------------|
| `APP_NAME` | variable | `landing-app` / `booking-app` / `crm-app` |
| `STAGE` | variable | `prod` |
| `S3_BUCKET` | variable | `630969833829-ci` (from landing Bitbucket YAML) |
| `APP_AWS_REGION` | variable | `eu-central-1` |
| AWS auth | OIDC | Role `github-actions-cf-deploy`. No static AWS keys in GitHub. |
| `S3_LOG_BUCKET` | variable | optional; copy from Bitbucket if set |
| `CLOUDFRONT_DISTRIBUTION_ID` | variable | landing: `EJ7BR3IMLAUCD`. Confirm booking/crm in Bitbucket. |

## Per-app `.env.dist` keys (must exist in Environment `prod`)

Treat empty-in-dist keys as secrets unless they are public URLs.

### landing (`landing-app`)

`DB_NAME`, `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_PORT`, `APP_AWS_S3_MIRROR`, `RECAPTCHA_PUBLIC_KEY`, `RECAPTCHA_PRIVATE_KEY`, `CRM_URL`, `CRM_TOKEN`

### booking (`booking-app`)

`DB_NAME`, `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_PORT`, `APP_AWS_S3_BUCKET`, `GEO_IP_ON`, `GEO_DEFAULT_COUNTRY`, `LANDING_URL`, `CRM_URL`, `CRM_TOKEN`, `CRM_CHAT_ENCRYPT_KEYS`, `META_SYSTEM_USER`

### crm (`crm-app`)

`DB_NAME`, `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_PORT`, `MAILER_SMTP_USER`, `MAILER_SMTP_PASSWORD`, `APP_AWS_S3_BUCKET`, `APP_AWS_S3_BUCKET_MAILER`, `APP_AWS_S3_MIRROR`, `GEO_IP_ON`, `SECURE_STORAGE_AUTH`, `LANDING_URL`, `MAILER_LITE_API_KEY`, `WITHPERSONA_API_KEY`, `AUTHORIZE_NET_MERCHANT_LOGIN_ID`, `AUTHORIZE_NET_MERCHANT_TRANSACTION_KEY`, `CRM_CHAT_ENCRYPT_KEYS`, `API_FLIGHT_AWARE`, `API_CHAT_GPT`, `DIAL_PAD_KEY`, `DIALPAD_SMS_KEY`, `DIALPAD_SMS_WEBHOOK_SECRET`

Prod Environment **variables** are set on each GitHub repo (`APP_NAME`, `STAGE`, `S3_BUCKET`, `APP_AWS_REGION`, landing `CLOUDFRONT_DISTRIBUTION_ID`).

AWS CI uses GitHub OIDC and role `github-actions-cf-deploy`. App `.env.dist` keys stay as Environment `prod` secrets. Do not put IAM user access keys in GitHub.

App workflows pull `ghcr.io/weblablv/cf-deployment:<DEPLOY_REF>` (full git SHA). The image job on `cf-deployment` `main` publishes that tag. The first public publish must be set once in the GitHub package UI (`weblablv/cf-deployment` → Packages → `cf-deployment` → Change visibility → Public). `GITHUB_TOKEN` cannot do that (API 404).
