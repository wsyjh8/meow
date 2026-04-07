import { computeLevelFromExp } from './dev-store';

describe('computeLevelFromExp', () => {
  it('exp=0 → level=1', () => {
    expect(computeLevelFromExp(0)).toBe(1);
  });

  it('exp=19 → level=1', () => {
    expect(computeLevelFromExp(19)).toBe(1);
  });

  it('exp=20 → level=2', () => {
    expect(computeLevelFromExp(20)).toBe(2);
  });

  it('exp=49 → level=2', () => {
    expect(computeLevelFromExp(49)).toBe(2);
  });

  it('exp=50 → level=3', () => {
    expect(computeLevelFromExp(50)).toBe(3);
  });

  it('exp=89 → level=3', () => {
    expect(computeLevelFromExp(89)).toBe(3);
  });

  it('exp=90 → level=4', () => {
    expect(computeLevelFromExp(90)).toBe(4);
  });

  it('exp=145 → level=5', () => {
    expect(computeLevelFromExp(145)).toBe(5);
  });

  it('exp=744 → level=9', () => {
    expect(computeLevelFromExp(744)).toBe(9);
  });

  it('exp=745 → level=10 (cap)', () => {
    expect(computeLevelFromExp(745)).toBe(10);
  });

  it('exp=9999 → level=10 (stays capped)', () => {
    expect(computeLevelFromExp(9999)).toBe(10);
  });
});
