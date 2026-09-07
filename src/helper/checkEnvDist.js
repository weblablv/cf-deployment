'use strict';

import fs from 'fs';
import path from 'path';

export const ensureEnvDistExists = () => {
    const envDistPath = path.resolve('.env.dist');
    return fs.existsSync(envDistPath) ? envDistPath : null;
};