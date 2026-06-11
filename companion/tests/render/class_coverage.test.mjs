/**
 * Guard A — class coverage: every class="…" token used in render fns
 * must have a matching selector in style.css.
 *
 * Run: node --test companion/tests/render/class_coverage.test.mjs
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const APP_DIR = resolve(__dirname, '../../app');
const RENDER_DIR = resolve(APP_DIR, 'render');
const CSS_PATH = resolve(APP_DIR, 'style.css');

function extractClassTokens(jsSource) {
  // Match class="token1 token2" and class="${expr} token" patterns
  // Strip ${...} interpolations, then split on whitespace
  const tokens = new Set();
  const classRe = /class="([^"]*)"/g;
  let m;
  while ((m = classRe.exec(jsSource)) !== null) {
    let val = m[1];
    // Remove ${...} interpolations
    val = val.replace(/\$\{[^}]*\}/g, '');
    for (const tok of val.trim().split(/\s+/)) {
      if (tok && tok.length > 0 && !tok.includes('$')) {
        tokens.add(tok);
      }
    }
  }
  return tokens;
}

describe('class coverage guard', () => {
  it('every class token in render JS has a CSS selector', () => {
    const css = readFileSync(CSS_PATH, 'utf-8');

    // Collect all class tokens from render/*.js + app.js
    const allTokens = new Set();
    const jsFiles = readdirSync(RENDER_DIR).filter(f => f.endsWith('.js'));
    for (const f of jsFiles) {
      const src = readFileSync(resolve(RENDER_DIR, f), 'utf-8');
      for (const t of extractClassTokens(src)) allTokens.add(t);
    }
    const appSrc = readFileSync(resolve(APP_DIR, 'app.js'), 'utf-8');
    for (const t of extractClassTokens(appSrc)) allTokens.add(t);

    // Check each token has a selector in CSS (lenient: .token substring)
    const missing = [];
    for (const tok of allTokens) {
      if (!css.includes(`.${tok}`)) {
        missing.push(tok);
      }
    }

    assert.deepEqual(missing, [],
      `Unstyled class tokens found in render JS but not in style.css: ${missing.join(', ')}`);
  });
});
