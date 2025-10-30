const config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    'bin/**/*.ts',
    'lib/**/*.ts',
    '!**/node_modules/**',
    '!**/vendor/**',
    '!**/*.d.ts',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  setupFilesAfterEnv: [],
  testTimeout: 30000, // 30 seconds for integration tests
  // Transform TypeScript files
  transform: {
    '^.+\\.ts$': [
      'ts-jest',
      {
        tsconfig: 'tsconfig.json',
      },
    ],
  },
  // Module file extensions
  moduleFileExtensions: ['ts', 'js', 'json'],
  // Ignore node_modules
  testPathIgnorePatterns: ['/node_modules/'],
};

module.exports = config;
