'use strict';

import fs from 'fs';
import { checkAndExit } from './utils/checkAndExit.js';

export const validatePreBuild = () => {
    checkAndExit(
        fs.existsSync('local.config.php'),
        'Error: local.config.php committed. Exiting.'
    );

    const allFiles = fs.readdirSync(process.cwd(), { withFileTypes: true });
    const invalidEnvTemplates = allFiles
        .filter(
            (entry) =>
                entry.isFile() &&
                entry.name.startsWith('.env.') &&
                entry.name !== '.env.dist'
        )
        .map(entry => entry.name);
    checkAndExit(
        invalidEnvTemplates.length > 0,
        `Error: Invalid env file(s) found: ${invalidEnvTemplates.join(', ')}. Only .env.dist is allowed.`
    );

    const stage = process.env.STAGE;
    checkAndExit(
        !stage,
        'Error: STAGE is not set. Exiting.'
    );

    const branch = process.env.BRANCH;
    checkAndExit(
        branch === 'dev',
        'dev branches are no longer supported!'
    );

    checkAndExit(
        fs.existsSync('config/parameters.json'),
        'Error: .apprc configs not supported anymore. Migrate to .env'
    );
};
