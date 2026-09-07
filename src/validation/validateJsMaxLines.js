'use strict';

import fs from 'fs';
import path from 'path';
import { checkAndExit } from './utils/checkAndExit.js';

const DEFAULT_MAX_LINES = 250;
const HARD_MAX_LINES = 900;
const DEFAULT_JS_EXCLUDE_DIRS = ['node_modules', '.next', 'dist', '.git'];
const DEFAULT_PHP_EXCLUDE_DIRS = ['vendor', 'node_modules', '.next', 'dist', '.git'];

const collectFilesOverLimit = (rootDir, maxLines, excludeDirs, fileExtensions, baseDir = rootDir, results = []) => {
    if (!fs.existsSync(rootDir)) {
        return results;
    }
    const entries = fs.readdirSync(rootDir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(rootDir, entry.name);
        const relativePath = path.relative(baseDir, fullPath);
        if (entry.isDirectory()) {
            if (excludeDirs.includes(entry.name)) {
                continue;
            }
            collectFilesOverLimit(fullPath, maxLines, excludeDirs, fileExtensions, baseDir, results);
        } else if (entry.isFile() && fileExtensions.some(ext => entry.name.endsWith(ext))) {
            try {
                const content = fs.readFileSync(fullPath, 'utf-8');
                const lines = content.split('\n').length;
                if (lines > maxLines) {
                    results.push({ path: relativePath, lines });
                }
            } catch {
                // Skip unreadable files (e.g. symlinks, permissions)
            }
        }
    }
    return results;
};

export const warnIfJsFilesExceedMaxLines = (
    rootDir = process.cwd(),
    maxLines = DEFAULT_MAX_LINES,
    excludeDirs = DEFAULT_JS_EXCLUDE_DIRS
) => {
    const offenders = collectFilesOverLimit(rootDir, maxLines, excludeDirs, ['.js']);
    if (offenders.length > 0) {
        console.warn('⚠️ The following JS files exceed 250 lines (source limit):');
        offenders.forEach(({ path: filePath, lines }) => {
            console.warn(`  ${filePath} (${lines} lines)`);
        });
    }
};

export const enforceJsMaxLines = (
    rootDir = process.cwd(),
    maxLines = HARD_MAX_LINES,
    excludeDirs = DEFAULT_JS_EXCLUDE_DIRS
) => {
    const offenders = collectFilesOverLimit(rootDir, maxLines, excludeDirs, ['.js']);
    if (offenders.length > 0) {
        const fileList = offenders.map(({ path: p, lines }) => `  ${p} (${lines} lines)`).join('\n');
        checkAndExit(
            true,
            `🚫 Error: The following JS source files exceed ${maxLines} lines and are not allowed:\n${fileList}\nExiting.`
        );
    }
};

export const enforcePhpMaxLines = (
    rootDir = process.cwd(),
    maxLines = HARD_MAX_LINES,
    excludeDirs = DEFAULT_PHP_EXCLUDE_DIRS
) => {
    const offenders = collectFilesOverLimit(rootDir, maxLines, excludeDirs, ['.php']);
    if (offenders.length > 0) {
        const fileList = offenders.map(({ path: p, lines }) => `  ${p} (${lines} lines)`).join('\n');
        checkAndExit(
            true,
            `🚫 Error: The following PHP source files exceed ${maxLines} lines and are not allowed:\n${fileList}\nExiting.`
        );
    }
};
