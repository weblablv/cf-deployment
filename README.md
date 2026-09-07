# CEO Flights PHP EC2 deployer

CI image that packages crm, landing, and booking and deploys them to EC2 via AWS CodeDeploy.

Runtime config comes from `.env` generated from `.env.dist` + CI env vars. TLS is terminated at CloudFront; this image does not copy SSL certs or `local.config.php` from S3.

Validate an app without deploying (uses `git archive` + dummy env keys):

```bash
npm run validate:app -- landing
npm run validate:app -- booking
npm run validate:app -- crm
```
