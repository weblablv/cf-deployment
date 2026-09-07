'use strict';

export const checkAndExit = (condition, errorMessage) => {
    if (condition) {
        console.error(errorMessage);
        process.exit(1);
    }
};