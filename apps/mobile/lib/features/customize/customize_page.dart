import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/meow_card.dart';
import '../../shared/widgets/meow_chip.dart';
import '../../shared/widgets/resource_badge.dart';
import '../../shared/widgets/preview_container.dart';

/// CustomizePage — Option B Phase 4 redesign + B2-2C content enhancement.
///
/// Structure: Preview Area → Resource Bar → Save-up Goal → Owned-not-equipped → Tabs → Item List
/// B2-2C: compare hints, owned-not-equipped detail, slot summary, save-up cue.
class CustomizePage extends StatefulWidget {
  const CustomizePage({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> with SingleTickerProviderStateMixin {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();
  late final TabController _tabController;

  CatalogResponse? _catalog;
  InventoryStateData? _inventory;
  EquippedSnapshotData? _equipped;
  bool _isLoading = true;
  String? _error;
  bool _isActing = false;

  // Purchase/equip feedback copy pools (B2-1A)
  static const _purchaseSuccessCopies = [
    '买到了~ 🎉',
    '入手成功！🛍️',
    '新物品到手~',
    '太好了，收入囊中！',
    '购买成功~ 快去装备吧！',
  ];
  static const _equipSuccessCopies = [
    '已装备~ ✨',
    '穿上了！好看~ ✨',
    '换装成功~ 看看效果吧！',
    '新造型上线~ ✨',
    '装扮更新！很适合你~',
  ];

  static const _itemEmoji = <String, String>{
    'cat_hat_red': '🎩',
    'cat_bow_blue': '🎀',
    'cat_scarf_pink': '🧣',
    'room_lamp_warm': '💡',
    'room_rug_soft': '🏠',
    // B2-2A new items
    'cat_hat_straw': '👒',
    'cat_bow_yellow': '🌻',
    'cat_scarf_stripe': '🧶',
    'room_plant_small': '🌿',
    'room_cushion_cloud': '☁️',
  };

  static const _slotEmoji = <String, String>{
    'head': '👒',
    'neck': '🎀',
    'decor': '💡',
    'floor': '🏠',
  };

  // Slot display names (B2-2C — pure frontend content layer)
  static const _slotDisplayNames = <String, String>{
    'head': '头饰',
    'neck': '颈饰',
    'decor': '装饰',
    'floor': '地面',
  };

  // Compare hint copy pools (B2-2C — pure frontend, not backend truth)
  static const _compareReplaceCopies = [
    '将替换当前',
    '换掉现有的',
    '替代目前的',
  ];
  static const _compareEmptySlotCopies = [
    '空闲槽位，装上就生效~',
    '这个位置还空着，试试看~',
    '空槽位，直接装上吧~',
  ];
  static const _saveUpCopies = [
    '再攒一点就能入手~',
    '快够了，加油攒~',
    '离目标好近了~',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _apiClient.getShopCatalog(),
        _apiClient.getInventory(),
        _apiClient.getEquipment(),
      ]);
      setState(() {
        _catalog = results[0] as CatalogResponse;
        _inventory = results[1] as InventoryStateData;
        _equipped = (results[2] as EquipmentResponse).equippedSnapshot;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _purchase(CatalogItemData item) async {
    if (_isActing) return;
    setState(() => _isActing = true);
    try {
      final key = 'purchase-${item.itemId}-${DateTime.now().millisecondsSinceEpoch}';
      final resp = await _apiClient.purchaseItem(itemId: item.itemId, idempotencyKey: key);
      if (!mounted) return;
      if (resp.purchaseResult.isSuccess) {
        setState(() => _inventory = resp.inventory);
        final purchaseCopy = _purchaseSuccessCopies[Random().nextInt(_purchaseSuccessCopies.length)];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$purchaseCopy「${item.name}」')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_purchaseError(resp.purchaseResult.errorCode))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('购买失败: $e')));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _equip(CatalogItemData item) async {
    if (_isActing) return;
    setState(() => _isActing = true);
    try {
      final key = 'equip-${item.itemId}-${DateTime.now().millisecondsSinceEpoch}';
      final resp = await _apiClient.equipItem(itemId: item.itemId, idempotencyKey: key);
      if (!mounted) return;
      if (resp.equipResult.isSuccess) {
        setState(() => _equipped = resp.equippedSnapshot);
        final equipCopy = _equipSuccessCopies[Random().nextInt(_equipSuccessCopies.length)];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$equipCopy「${item.name}」')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_equipError(resp.equipResult.errorCode))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('装备失败: $e')));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  String _purchaseError(String? code) {
    switch (code) {
      case 'COINS_NOT_ENOUGH': return '金币不够啦，多学几个单词吧~';
      case 'ITEM_ALREADY_OWNED': return '已经拥有这个啦~';
      case 'ITEM_LEVEL_LOCKED': return '等级还不够，继续加油~';
      default: return '购买失败';
    }
  }

  String _equipError(String? code) {
    switch (code) {
      case 'ITEM_NOT_OWNED': return '还没有这个物品哦';
      case 'ITEM_NOT_FOUND': return '找不到这个物品';
      default: return '装备失败';
    }
  }

  bool _isEquipped(String itemId) {
    if (_equipped == null) return false;
    return _equipped!.outfit.values.contains(itemId) ||
        _equipped!.room.values.contains(itemId);
  }

  bool _isOwned(String itemId) {
    return _inventory?.ownedItems.any((o) => o.itemId == itemId) ?? false;
  }

  /// Get the currently equipped item_id for a given slot (B2-2C helper).
  String? _getEquippedInSlot(String slot) {
    if (_equipped == null) return null;
    // Check outfit slots (head, neck) and room slots (decor, floor)
    return _equipped!.outfit[slot] ?? _equipped!.room[slot];
  }

  /// Get display name for an item_id from catalog (B2-2C helper).
  String _catalogName(String itemId) {
    final item = _catalog?.items.where((i) => i.itemId == itemId).firstOrNull;
    return item?.name ?? itemId;
  }

  /// Build slot-based summary of what's filled vs empty (B2-2C helper).
  Map<String, String?> _getAllSlotState() {
    final result = <String, String?>{};
    for (final slot in ['head', 'neck', 'decor', 'floor']) {
      result[slot] = _getEquippedInSlot(slot);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeowColors.background,
      appBar: AppBar(
        title: const Text('装扮与小窝'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: MeowColors.error, size: 48),
          const SizedBox(height: 16),
          Text('加载失败', style: MeowTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(_error!, style: MeowTextStyles.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final catalog = _catalog!;
    final inv = _inventory!;

    return Column(
      children: [
        // ===== 1. Preview Area (B2-2C: enhanced slot summary) =====
        _buildPreviewArea(),

        // ===== 2. Resource Bar =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MeowSpacing.lg, vertical: MeowSpacing.sm),
          child: Row(
            children: [
              ResourceBadge(
                icon: Icons.monetization_on,
                value: '${inv.coinsBalance}',
                color: MeowColors.coinGold,
                label: '金币',
                compact: true,
              ),
              const SizedBox(width: 8),
              MeowChip(
                label: '已拥有 ${inv.ownedItems.length}/${catalog.items.length} 件',
                variant: MeowChipVariant.primary,
                small: true,
              ),
              const Spacer(),
              _buildEquippedCountChip(),
            ],
          ),
        ),

        // ===== 3. Save-up goal cue (B2-2C) =====
        _buildSaveUpGoalCue(catalog, inv),

        // ===== 4. Owned-not-equipped detail (B2-2C: enhanced from B2-1C) =====
        _buildOwnedNotEquippedDetail(inv),

        // ===== 5. Tabs =====
        Container(
          margin: const EdgeInsets.symmetric(horizontal: MeowSpacing.lg),
          decoration: BoxDecoration(
            color: MeowColors.surfaceWarm,
            borderRadius: MeowRadius.buttonRadius,
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: MeowColors.primary,
              borderRadius: MeowRadius.buttonRadius,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: MeowColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            dividerHeight: 0,
            tabs: const [
              Tab(text: '全部'),
              Tab(text: '已拥有'),
              Tab(text: '已装备'),
            ],
          ),
        ),
        const SizedBox(height: MeowSpacing.sm),

        // ===== 6. Item List =====
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildItemList(catalog.items),
              _buildItemList(catalog.items.where((i) => _isOwned(i.itemId)).toList()),
              _buildItemList(catalog.items.where((i) => _isEquipped(i.itemId)).toList()),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== Equipped count chip (B2-2C) ====================

  Widget _buildEquippedCountChip() {
    final slotState = _getAllSlotState();
    final filledCount = slotState.values.where((v) => v != null).length;
    return MeowChip(
      label: '已装备 $filledCount/4 槽',
      variant: filledCount >= 3
          ? MeowChipVariant.success
          : filledCount >= 1
              ? MeowChipVariant.info
              : MeowChipVariant.neutral,
      small: true,
    );
  }

  // ==================== Save-up Goal Cue (B2-2C) ====================
  // Pure frontend content layer — based on catalog prices + current balance.
  // Not a backend commitment or frozen recommendation.

  Widget _buildSaveUpGoalCue(CatalogResponse catalog, InventoryStateData inv) {
    // Find cheapest unowned item the user can't yet afford
    final unownedItems = catalog.items
        .where((i) => !_isOwned(i.itemId))
        .toList()
      ..sort((a, b) => a.coinPrice.compareTo(b.coinPrice));

    // Find the nearest affordable goal (can't afford yet, but closest)
    CatalogItemData? goalItem;
    for (final item in unownedItems) {
      if (item.coinPrice > inv.coinsBalance) {
        goalItem = item;
        break;
      }
    }

    // If user can afford all unowned items, or owns everything — no goal
    if (goalItem == null) return const SizedBox.shrink();

    final diff = goalItem.coinPrice - inv.coinsBalance;
    final emoji = _itemEmoji[goalItem.itemId] ?? '🎁';
    final copy = _saveUpCopies[Random().nextInt(_saveUpCopies.length)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeowSpacing.lg, vertical: MeowSpacing.xs),
      child: MeowCardWarm(
        padding: const EdgeInsets.symmetric(horizontal: MeowSpacing.md, vertical: MeowSpacing.sm),
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$copy 还差 ',
                      style: MeowTextStyles.caption.copyWith(color: MeowColors.textSecondary),
                    ),
                    TextSpan(
                      text: '$diff 金币',
                      style: MeowTextStyles.caption.copyWith(
                        color: MeowColors.coinGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' 就能买「${goalItem.name}」',
                      style: MeowTextStyles.caption.copyWith(color: MeowColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Owned-Not-Equipped Detail (B2-2C, enhanced from B2-1C) ====================
  // Shows specific owned-but-not-equipped items with slot context + equip CTA.
  // Pure frontend content layer — reads existing backend fields only.

  Widget _buildOwnedNotEquippedDetail(InventoryStateData inv) {
    final ownedIds = inv.ownedItems.map((o) => o.itemId).toSet();
    final equippedIds = <String>{};
    if (_equipped != null) {
      equippedIds.addAll(_equipped!.outfit.values.whereType<String>());
      equippedIds.addAll(_equipped!.room.values.whereType<String>());
    }
    final ownedNotEquippedIds = ownedIds.difference(equippedIds);

    if (ownedNotEquippedIds.isEmpty) return const SizedBox.shrink();

    // Get catalog items for these ids
    final items = _catalog?.items
        .where((i) => ownedNotEquippedIds.contains(i.itemId))
        .take(3) // Show max 3 items
        .toList() ?? [];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeowSpacing.lg, vertical: MeowSpacing.xs),
      child: MeowCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(MeowSpacing.md),
        borderColor: MeowColors.success.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '已拥有但还没装上 (${ownedNotEquippedIds.length}件)',
                  style: MeowTextStyles.caption.copyWith(
                    color: MeowColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) {
              final emoji = _itemEmoji[item.itemId] ?? '✨';
              final slotName = _slotDisplayNames[item.slot] ?? item.slot;
              final currentInSlot = _getEquippedInSlot(item.slot);
              final hint = currentInSlot != null
                  ? '替换「${_catalogName(currentInSlot)}」'
                  : '空槽位可直接装备';

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: MeowTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '$slotName · $hint',
                            style: MeowTextStyles.caption.copyWith(
                              color: MeowColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: _isActing ? null : () => _equip(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MeowColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('装备'),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (ownedNotEquippedIds.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '还有 ${ownedNotEquippedIds.length - 3} 件，切到"已拥有"查看~',
                  style: MeowTextStyles.caption.copyWith(
                    color: MeowColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== Preview Area (B2-2C: enhanced slot summary) ====================

  Widget _buildPreviewArea() {
    final slotState = _getAllSlotState();
    final activeItems = slotState.entries.where((e) => e.value != null).toList();
    final emptySlots = slotState.entries.where((e) => e.value == null).toList();

    return PreviewContainer(
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cat with equipped indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🐱', style: TextStyle(fontSize: 44)),
              if (activeItems.isNotEmpty) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: activeItems.map((e) {
                    final emoji = _itemEmoji[e.value] ?? _slotEmoji[e.key] ?? '✨';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (activeItems.isEmpty)
            Text('还没有装扮，去挑选一件吧~', style: MeowTextStyles.bodySmall)
          else ...[
            // Equipped item chips
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: activeItems.map((e) {
                final slotName = _slotDisplayNames[e.key] ?? e.key;
                final name = _catalogName(e.value!);
                return MeowChip(label: '$slotName: $name', variant: MeowChipVariant.primary, small: true);
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              _getStyleHint(activeItems.length),
              style: MeowTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          // B2-2C: Show empty slot hints
          if (emptySlots.isNotEmpty && activeItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 4,
                children: emptySlots.map((e) {
                  final slotName = _slotDisplayNames[e.key] ?? e.key;
                  final emoji = _slotEmoji[e.key] ?? '·';
                  return MeowChip(label: '$emoji $slotName 空', variant: MeowChipVariant.neutral, small: true);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Style hint copy (B2-1C — pure frontend static content)
  String _getStyleHint(int equippedCount) {
    if (equippedCount >= 3) {
      const tips = ['搭配很丰富呢~', '看起来很有个性！', '装扮控上线~'];
      return tips[Random().nextInt(tips.length)];
    } else if (equippedCount >= 1) {
      const tips = ['还可以再搭配更多哦~', '再换几件试试？', '越搭越好看~'];
      return tips[Random().nextInt(tips.length)];
    }
    return '';
  }

  // ==================== Item List ====================

  Widget _buildItemList(List<CatalogItemData> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MeowSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 40)),
              const SizedBox(height: MeowSpacing.md),
              Text('这里还没有东西哦~', style: MeowTextStyles.bodySmall),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: MeowSpacing.lg, vertical: MeowSpacing.sm),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(CatalogItemData item) {
    final owned = _isOwned(item.itemId);
    final equipped = _isEquipped(item.itemId);
    final emoji = _itemEmoji[item.itemId] ?? (item.itemType == 'outfit' ? '👗' : '🏠');
    final slotName = _slotDisplayNames[item.slot] ?? item.slot;

    return MeowCard(
      margin: const EdgeInsets.only(bottom: MeowSpacing.sm),
      borderColor: equipped
          ? MeowColors.primary.withValues(alpha: 0.4)
          : owned
              ? MeowColors.success.withValues(alpha: 0.3)
              : null,
      child: Row(
        children: [
          // Item icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: equipped
                  ? MeowColors.primaryLight.withValues(alpha: 0.3)
                  : owned
                      ? MeowColors.success.withValues(alpha: 0.1)
                      : MeowColors.surfaceWarm,
              borderRadius: MeowRadius.buttonRadius,
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: MeowSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.name, style: MeowTextStyles.subtitle)),
                    if (equipped)
                      const MeowChip(label: '已装备', icon: Icons.check_circle, variant: MeowChipVariant.primary, small: true)
                    else if (owned)
                      const MeowChip(label: '已拥有', variant: MeowChipVariant.success, small: true),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MeowChip(
                      label: '${item.coinPrice} 💰',
                      variant: MeowChipVariant.warning,
                      small: true,
                    ),
                    const SizedBox(width: 4),
                    MeowChip(
                      label: 'Lv.${item.requiredLevel}+',
                      variant: MeowChipVariant.neutral,
                      small: true,
                    ),
                    const SizedBox(width: 4),
                    MeowChip(
                      label: '$slotName ${_slotEmoji[item.slot] ?? ""}',
                      variant: MeowChipVariant.info,
                      small: true,
                    ),
                  ],
                ),
                // B2-2C: Compare hint — shows slot context (not backend truth)
                if (!equipped) _buildCompareHint(item, owned),
              ],
            ),
          ),

          // Action button
          const SizedBox(width: MeowSpacing.sm),
          _buildActionButton(item, owned, equipped),
        ],
      ),
    );
  }

  // ==================== Compare Hint (B2-2C) ====================
  // Pure frontend content layer. Shows what would change if you equip this.
  // This is a UI hint / preview, NOT a backend-confirmed change.

  Widget _buildCompareHint(CatalogItemData item, bool owned) {
    final currentInSlot = _getEquippedInSlot(item.slot);
    final balance = _inventory?.coinsBalance ?? 0;

    String hint;
    IconData icon;
    Color color;

    if (owned) {
      // Owned but not equipped — show what it would replace
      if (currentInSlot != null) {
        final replaceCopy = _compareReplaceCopies[Random().nextInt(_compareReplaceCopies.length)];
        final currentName = _catalogName(currentInSlot);
        final currentEmoji = _itemEmoji[currentInSlot] ?? '✨';
        hint = '$replaceCopy $currentEmoji $currentName';
        icon = Icons.swap_horiz;
        color = MeowColors.info;
      } else {
        final emptyCopy = _compareEmptySlotCopies[Random().nextInt(_compareEmptySlotCopies.length)];
        hint = emptyCopy;
        icon = Icons.add_circle_outline;
        color = MeowColors.success;
      }
    } else {
      // Not owned — show affordability + slot context
      if (balance >= item.coinPrice) {
        // Can afford
        if (currentInSlot != null) {
          final currentName = _catalogName(currentInSlot);
          hint = '买后可替换「$currentName」';
          icon = Icons.swap_horiz;
          color = MeowColors.info;
        } else {
          hint = '买后直接装上~';
          icon = Icons.add_circle_outline;
          color = MeowColors.success;
        }
      } else {
        final diff = item.coinPrice - balance;
        hint = '还差 $diff 金币';
        icon = Icons.savings_outlined;
        color = MeowColors.coinGold;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              hint,
              style: MeowTextStyles.caption.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(CatalogItemData item, bool owned, bool equipped) {
    if (equipped) {
      return const SizedBox(width: 50); // No action needed — already equipped
    }

    if (owned) {
      return SizedBox(
        width: 60,
        child: ElevatedButton(
          key: Key('equip-btn-${item.itemId}'),
          onPressed: _isActing ? null : () => _equip(item),
          style: ElevatedButton.styleFrom(
            backgroundColor: MeowColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          child: const Text('装备'),
        ),
      );
    }

    return SizedBox(
      width: 72,
      child: ElevatedButton(
        key: Key('buy-btn-${item.itemId}'),
        onPressed: _isActing ? null : () => _purchase(item),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text('${item.coinPrice} 购买'),
      ),
    );
  }
}
