'use strict';

import {
  CloudFrontClient,
  CreateInvalidationCommand,
  GetInvalidationCommand,
} from '@aws-sdk/client-cloudfront';

const distributionId = process.env.CLOUDFRONT_DISTRIBUTION_ID;

if (!distributionId) {
  console.log('CLOUDFRONT_DISTRIBUTION_ID not set. Nothing to invalidate.');
  process.exit(0);
}

const client = new CloudFrontClient({ region: 'us-east-1' });

const run = async () => {
  try {
    const createCommand = new CreateInvalidationCommand({
      DistributionId: distributionId,
      InvalidationBatch: {
        CallerReference: `invalidation-${Date.now()}`,
        Paths: {
          Quantity: 1,
          Items: ['/*'],
        },
      },
    });

    const result = await client.send(createCommand);
    const invalidationId = result.Invalidation?.Id;

    console.log(`✅ Invalidation ${invalidationId} created. Waiting for completion...`);

    let status = result.Invalidation?.Status;
    while (status !== 'Completed') {
      await new Promise(resolve => setTimeout(resolve, 5000)); // wait 5 seconds
      const check = await client.send(new GetInvalidationCommand({
        DistributionId: distributionId,
        Id: invalidationId,
      }));
      status = check.Invalidation.Status;
      console.log(`⌛ Invalidation status: ${status}`);
    }

    console.log(`🎉 Invalidation ${invalidationId} completed.`);
  } catch (err) {
    console.error('❌ CloudFront invalidation failed:', err);
    process.exit(1);
  }
};

run();