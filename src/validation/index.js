'use strict';

import { ensureEnvDistExists } from '../helper/checkEnvDist.js';
import fs from 'fs';
import { validateEnvVars } from './validateEnvVars.js';
import { validatePreBuild } from './validatePreBuild.js';
import { enforceJsMaxLines, enforcePhpMaxLines, warnIfJsFilesExceedMaxLines } from './validateJsMaxLines.js';

validatePreBuild();
warnIfJsFilesExceedMaxLines();
enforceJsMaxLines();
enforcePhpMaxLines();

const envDistPath = ensureEnvDistExists();

if (!envDistPath) {
    console.warn('⚠️ .env.dist file not found. Skipping environment validation.');
    process.exit(0);
}

const envDistContent = fs.readFileSync(envDistPath, 'utf-8');
validateEnvVars(envDistContent);
