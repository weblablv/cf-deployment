/* eslint-env jest */
'use strict';

import fs from 'fs';
import path from 'path';
import { validateEnvVars } from '../../../src/validation/validateEnvVars.js';
import { jest } from '@jest/globals';

const envPath = path.resolve('tests/fixtures/.env.dist');
const envDistContent = fs.readFileSync(envPath, 'utf-8');

describe('validateEnvVars', () => {
    it('should not throw when all required env vars are present', () => {
        process.env.DB_HOST = 'value';
        process.env.API_KEY = 'value';

        expect(() => validateEnvVars(envDistContent)).not.toThrow();
    });

    it('should throw when required env vars are missing', () => {
        delete process.env.DB_HOST;
        delete process.env.API_KEY;

        const mockExit = jest.spyOn(process, 'exit').mockImplementation(() => { throw new Error('process.exit called'); });
        const mockError = jest.spyOn(console, 'error').mockImplementation(() => {});

        expect(() => validateEnvVars(envDistContent)).toThrow('process.exit called');

        mockExit.mockRestore();
        mockError.mockRestore();
    });
});