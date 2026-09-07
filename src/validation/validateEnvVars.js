/* eslint-env jest */
'use strict';

export const validateEnvVars = (envDistContent) => {
  const requiredEnvVars = envDistContent
      .split('\n')
      .map(line => line.trim())
      .filter(line => line && !line.startsWith('#'))
      .map(line => line.split('=')[0].trim());

  console.log(`Required environment variables: ${requiredEnvVars.join(', ')}`);

  const missingVars = requiredEnvVars.filter(key => !process.env[key]);

  if (missingVars.length > 0) {
    console.error(`Missing required environment variables: ${missingVars.join(', ')}`);
    process.exit(1);
  }
};