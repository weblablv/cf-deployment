export default {
    transform: {}, // Disable Babel if not needed
    testEnvironment: 'node',
    moduleNameMapper: {
        '^(\\.{1,2}/.*)\\.js$': '$1',
    },
};