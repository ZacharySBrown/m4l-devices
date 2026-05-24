'use strict';

/**
 * Fixture loader — loads fixture manifests and sets for testing.
 */

const path = require('path');
const fs = require('fs');

const FIXTURES_DIR = path.join(__dirname, '..', 'fixtures', 'manifests');
const EXPECTED_DIR = path.join(__dirname, '..', 'fixtures', 'expected');

/**
 * Load a fixture manifest by name.
 * @param {string} name - e.g. 'hiphop_v3' loads hiphop_v3.manifest.json
 * @returns {object}
 */
function loadManifest(name) {
  const filePath = path.join(FIXTURES_DIR, `${name}.manifest.json`);
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

/**
 * Load a fixture set by name.
 * @param {string} name - e.g. 'hiphop_v3' loads hiphop_v3.set.json
 * @returns {object}
 */
function loadSet(name) {
  const filePath = path.join(FIXTURES_DIR, `${name}.set.json`);
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

/**
 * Load expected chop-math output by track ID.
 * @param {string} trackId
 * @returns {object}
 */
function loadExpectedChops(trackId) {
  const filePath = path.join(EXPECTED_DIR, 'chop-math', `${trackId}.json`);
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

/**
 * Create a mock filesystem for override-writer tests.
 */
function createMockFs() {
  const files = {};
  return {
    writeFileSync(filePath, content) {
      files[filePath] = content;
    },
    renameSync(oldPath, newPath) {
      files[newPath] = files[oldPath];
      delete files[oldPath];
    },
    readFileSync(filePath) {
      if (files[filePath] === undefined) {
        throw new Error(`ENOENT: ${filePath}`);
      }
      return files[filePath];
    },
    existsSync(filePath) {
      return files[filePath] !== undefined;
    },
    getFiles() {
      return { ...files };
    },
    reset() {
      for (const key of Object.keys(files)) delete files[key];
    },
  };
}

module.exports = {
  FIXTURES_DIR,
  EXPECTED_DIR,
  loadManifest,
  loadSet,
  loadExpectedChops,
  createMockFs,
};
