'use strict';

const { expect } = require('chai');
const {
  STEM_COLORS, GENRE_COLORS, STATE_COLORS,
  hexToLaunchpadRgb, genreColor, scaleBrightness,
} = require('../../src/shared/color-palette');

describe('color-palette', () => {
  describe('STEM_COLORS', () => {
    it('has all 4 stems', () => {
      expect(STEM_COLORS).to.have.keys('drums', 'bass', 'other', 'vox');
    });

    it('each stem has soft and bright variants', () => {
      for (const stem of Object.values(STEM_COLORS)) {
        expect(stem.soft).to.be.an('array').with.lengthOf(3);
        expect(stem.bright).to.be.an('array').with.lengthOf(3);
      }
    });
  });

  describe('GENRE_COLORS', () => {
    it('has expected genres', () => {
      expect(GENRE_COLORS).to.have.keys('hiphop', 'idm', 'ambient', 'rock', 'funk');
    });
  });

  describe('hexToLaunchpadRgb', () => {
    it('converts #ff8c5a to Launchpad range', () => {
      const rgb = hexToLaunchpadRgb('#ff8c5a');
      expect(rgb[0]).to.equal(Math.round(0xff / 2)); // 128
      expect(rgb[1]).to.equal(Math.round(0x8c / 2)); // 70
      expect(rgb[2]).to.equal(Math.round(0x5a / 2)); // 45
    });

    it('handles missing hash', () => {
      const rgb = hexToLaunchpadRgb('ff8c5a');
      expect(rgb).to.be.an('array').with.lengthOf(3);
    });

    it('returns empty color for null input', () => {
      expect(hexToLaunchpadRgb(null)).to.deep.equal(STATE_COLORS.empty);
    });

    it('returns empty color for invalid hex', () => {
      expect(hexToLaunchpadRgb('#xyz')).to.deep.equal(STATE_COLORS.empty);
    });
  });

  describe('genreColor', () => {
    it('returns known genre color', () => {
      expect(genreColor('hiphop')).to.deep.equal(GENRE_COLORS.hiphop);
    });

    it('falls back to custom color_hue', () => {
      const rgb = genreColor('unknown', '#00ff00');
      expect(rgb[1]).to.equal(Math.round(0xff / 2));
    });

    it('returns empty for unknown genre and no hue', () => {
      expect(genreColor('unknown')).to.deep.equal(STATE_COLORS.empty);
    });
  });

  describe('scaleBrightness', () => {
    it('full energy returns original', () => {
      const rgb = [100, 50, 25];
      const scaled = scaleBrightness(rgb, 1.0);
      expect(scaled).to.deep.equal(rgb);
    });

    it('zero energy returns dimmed', () => {
      const rgb = [100, 50, 25];
      const scaled = scaleBrightness(rgb, 0);
      // minScale = 0.3
      expect(scaled[0]).to.equal(30);
      expect(scaled[1]).to.equal(15);
      expect(scaled[2]).to.equal(8); // Math.round(25 * 0.3) = 8
    });

    it('clamps energy above 1', () => {
      const rgb = [100, 100, 100];
      const scaled = scaleBrightness(rgb, 2.0);
      expect(scaled).to.deep.equal(rgb);
    });
  });
});
