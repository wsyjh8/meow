import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { DevStore } from './dev-store';
import { DevStorePersistence } from './persistence';

function tmpFilePath(): string {
  return path.join(os.tmpdir(), `meow-test-${Date.now()}-${Math.random().toString(36).slice(2)}.json`);
}

describe('DevStore Persistence', () => {
  let filePath: string;

  beforeEach(() => {
    filePath = tmpFilePath();
  });

  afterEach(() => {
    // Cleanup
    try { fs.unlinkSync(filePath); } catch {}
    try { fs.unlinkSync(filePath + '.tmp'); } catch {}
  });

  it('purchase survives simulated restart', () => {
    // Store 1: make a purchase
    const store1 = new DevStore(filePath);
    store1.reset();

    // Earn via settlements: each effective_new_word gives 2 coins + 1 exp
    for (let i = 0; i < 30; i++) {
      const { sourceEvent } = store1.createOrGetSourceEvent(
        'effective_new_word',
        `persist-attempt-${i}`,
        `persist-idem-se-${i}`,
      );
      store1.createSettlement(sourceEvent.source_event_id, `persist-idem-st-${i}`);
    }

    const balanceBefore = store1.getBalanceSnapshot();
    expect(balanceBefore.coins).toBe(60);

    // Purchase
    const purchaseResult = store1.purchaseItem('cat_hat_red', 'persist-purchase-key');
    expect(purchaseResult.status).toBe('succeeded');

    const invBefore = store1.getInventory();
    expect(invBefore.owned_items.length).toBe(1);
    expect(invBefore.coins_balance).toBe(0);

    // Store 2: simulate restart by loading from same file
    const store2 = new DevStore(filePath);

    const invAfter = store2.getInventory();
    expect(invAfter.owned_items.length).toBe(1);
    expect(invAfter.owned_items[0].item_id).toBe('cat_hat_red');
    expect(invAfter.coins_balance).toBe(0);

    // Cleanup
    store2.reset();
  });

  it('equipment survives simulated restart', () => {
    const store1 = new DevStore(filePath);
    store1.reset();

    // Earn coins + purchase + equip
    for (let i = 0; i < 30; i++) {
      const { sourceEvent } = store1.createOrGetSourceEvent(
        'effective_new_word', `equip-persist-${i}`, `equip-idem-se-${i}`,
      );
      store1.createSettlement(sourceEvent.source_event_id, `equip-idem-st-${i}`);
    }
    store1.purchaseItem('cat_hat_red', 'equip-purchase-key');
    const equipResult = store1.equipItem('cat_hat_red', 'equip-equip-key');
    expect(equipResult.status).toBe('succeeded');

    const snapshotBefore = store1.getEquippedSnapshot();
    expect(snapshotBefore.outfit['head']).toBe('cat_hat_red');

    // Restart
    const store2 = new DevStore(filePath);
    const snapshotAfter = store2.getEquippedSnapshot();
    expect(snapshotAfter.outfit['head']).toBe('cat_hat_red');

    store2.reset();
  });

  it('feed / growth state survives simulated restart', () => {
    const store1 = new DevStore(filePath);
    store1.reset();

    // Earn a fish treat via review_group_completed settlement
    const { sourceEvent } = store1.createOrGetSourceEvent(
      'review_group_completed', 'feed-persist-group-1', 'feed-idem-se-1',
    );
    store1.createSettlement(sourceEvent.source_event_id, 'feed-idem-st-1');

    // Feed
    const feedResult = store1.feedCat('fish_treat', 'feed-persist-key');
    expect(feedResult.status).toBe('succeeded');

    const summaryBefore = store1.getSecondarySummary();
    const moodBefore = summaryBefore.cat_summary.mood;
    const expBefore = summaryBefore.exp;

    // Restart
    const store2 = new DevStore(filePath);
    const summaryAfter = store2.getSecondarySummary();
    expect(summaryAfter.cat_summary.mood).toBe(moodBefore);
    expect(summaryAfter.exp).toBe(expBefore);

    store2.reset();
  });

  it('idempotency key survives simulated restart', () => {
    const store1 = new DevStore(filePath);
    store1.reset();

    // Earn + purchase with specific key
    for (let i = 0; i < 30; i++) {
      const { sourceEvent } = store1.createOrGetSourceEvent(
        'effective_new_word', `idem-persist-${i}`, `idem-se-${i}`,
      );
      store1.createSettlement(sourceEvent.source_event_id, `idem-st-${i}`);
    }

    const idemKey = 'idem-purchase-survive';
    store1.purchaseItem('cat_hat_red', idemKey);
    store1.setIdempotencyKey(idemKey, 'shop/purchases', {
      item_id: 'cat_hat_red',
      coins_spent: 60,
    });

    // Restart
    const store2 = new DevStore(filePath);

    // Replay same idempotency key
    const replay = store2.purchaseItem('cat_hat_red', idemKey);
    expect(replay.status).toBe('succeeded');
    expect(replay.alreadyExists).toBe(true);

    // Still only 1 owned item (not duplicated)
    expect(store2.getInventory().owned_items.length).toBe(1);

    store2.reset();
  });

  it('reset clears persistence file', () => {
    const store = new DevStore(filePath);
    store.reset();

    // Do some writes
    const { sourceEvent } = store.createOrGetSourceEvent(
      'effective_new_word', 'reset-test-1', 'reset-idem-1',
    );
    store.createSettlement(sourceEvent.source_event_id, 'reset-settle-1');

    expect(fs.existsSync(filePath)).toBe(true);

    // Reset
    store.reset();
    expect(fs.existsSync(filePath)).toBe(false);

    // New store from same path should be empty
    const store2 = new DevStore(filePath);
    expect(store2.getBalanceSnapshot().coins).toBe(0);
    expect(store2.getInventory().owned_items.length).toBe(0);
    store2.reset();
  });
});
