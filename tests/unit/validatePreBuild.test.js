/* eslint-env jest */

'use strict';

import fs from 'fs';
import path from 'path';
import { validatePreBuild } from '../../src/validation/validatePreBuild.js';

const forbiddenFiles = [
    'local.config.php',
    'config/parameters.json',
];

const allowedFiles = ['.env.dist'];

const originalExit = process.exit;

const withWorkspace = (setupEnv, run) => {
    const originalEnv = { ...process.env };

    forbiddenFiles.forEach((file) => {
        const filePath = path.resolve(file);
        if (fs.existsSync(filePath)) {
            fs.renameSync(filePath, `${filePath}.bak`);
        }
    });

    allowedFiles.forEach((file) => {
        const filePath = path.resolve(file);
        if (!fs.existsSync(filePath)) {
            fs.writeFileSync(filePath, '# dummy .env.dist');
        }
    });

    delete process.env.STAGE;
    delete process.env.BRANCH;
    setupEnv();

    try {
        run();
    } finally {
        process.exit = originalExit;
        process.env = originalEnv;

        forbiddenFiles.forEach((file) => {
            const filePath = path.resolve(file);
            const backupPath = `${filePath}.bak`;
            if (fs.existsSync(backupPath)) {
                fs.renameSync(backupPath, filePath);
            }
        });

        allowedFiles.forEach((file) => {
            const filePath = path.resolve(file);
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
            }
        });
    }
};

describe('validatePreBuild', () => {
    it('should not throw when STAGE and BRANCH are set', () => {
        withWorkspace(() => {
            process.env.STAGE = 'prod';
            process.env.BRANCH = 'release/prod';
        }, () => {
            expect(() => validatePreBuild()).not.toThrow();
        });
    });

    it('should fail when STAGE is not set', () => {
        withWorkspace(() => {
            process.env.BRANCH = 'release/prod';
        }, () => {
            process.exit = () => {
                throw new Error('process.exit called');
            };
            expect(() => validatePreBuild()).toThrow('process.exit called');
        });
    });
});
