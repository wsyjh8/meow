import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../spec/theme/tokens.dart';
import '../../spec/widgets/spec_back_to_study_chip.dart';

/// RoomPage — 我的小窝
///
/// 只展示 itemType == 'room_item' 的物品（decor / floor 槽位）。
/// 副机制纪律（CLAUDE.md §3.2）：房间装饰不产生学习收益。
class RoomPage extends StatefulWidget {
  const RoomPage({super.key, this.apiClient});
  final ApiClient? apiClient;

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with SingleTickerProviderStateMixin {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();
  late final TabController _tabController;

  CatalogResponse? _catalog;
  InventoryStateData? _inventory;
  EquippedSnapshotData? _equipped;
  bool _isLoading = true;
  String? _error;
  bool _isActing = false;

  static const _purchaseSuccessCopies = [
    '买到啦！小窝更温馨了喵~',
    '新物件到手喵！',
    '收入囊中喵~',
    '快摆进小窝看看喵！',
  ];
  static const _equipSuccessCopies = [
    '摆好了喵 ✨',
    '小窝焕然一新喵~',
    '好看！很有家的感觉喵~',
    '温馨小窝上线喵 ✨',
  ];

  // 房间槽位标签
  static const _slotLabel = <String, String>{
    'decor': '饰品',
    'floor': '地板',
  };

  // 房间物品 emoji 映射
  static const _itemEmoji = <String, String>{
    'room_lamp_warm':    '💡',
    'room_rug_soft':     '🟫',
    'room_plant_small':  '🌿',
    'room_cushion_cloud':'☁️',
  };

  // 房间装饰图层（emoji 场景）
  static const _roomDecorEmoji = <String, String>{
    'room_lamp_warm':    '💡',
    'room_plant_small':  '🌿',
  };
  static const _roomFloorEmoji = <String, String>{
    'room_rug_soft':     '🟫',
    'room_cushion_cloud':'☁️',
  };

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

  // ==================== 数据加载 ====================

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

  // ==================== 购买 / 装备 ====================

  Future<void> _purchase(CatalogItemData item) async {
    if (_isActing) return;
    setState(() => _isActing = true);
    try {
      final key = 'purchase-${item.itemId}-${DateTime.now().millisecondsSinceEpoch}';
      final resp = await _apiClient.purchaseItem(itemId: item.itemId, idempotencyKey: key);
      if (!mounted) return;
      if (resp.purchaseResult.isSuccess) {
        setState(() => _inventory = resp.inventory);
        final copy = _purchaseSuccessCopies[Random().nextInt(_purchaseSuccessCopies.length)];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$copy「${item.name}」')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_purchaseError(resp.purchaseResult.errorCode))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('购买失败: $e')));
      }
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
        final copy = _equipSuccessCopies[Random().nextInt(_equipSuccessCopies.length)];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$copy「${item.name}」')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_equipError(resp.equipResult.errorCode))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('装备失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  // ==================== helpers ====================

  String _purchaseError(String? code) {
    switch (code) {
      case 'COINS_NOT_ENOUGH': return '装扮币不够啦，多学几个单词吧～';
      case 'ITEM_ALREADY_OWNED': return '已经拥有这个啦喵~';
      case 'ITEM_LEVEL_LOCKED': return '等级还不够，继续加油～';
      default: return '购买失败';
    }
  }

  String _equipError(String? code) {
    switch (code) {
      case 'ITEM_NOT_OWNED': return '还没有这个物品哦';
      default: return '装备失败';
    }
  }

  bool _isEquipped(String itemId) =>
      _equipped?.room.values.contains(itemId) ?? false;

  bool _isOwned(String itemId) =>
      _inventory?.ownedItems.any((o) => o.itemId == itemId) ?? false;

  String? _getEquippedInSlot(String slot) => _equipped?.room[slot];

  /// 只取 room_item 类型
  List<CatalogItemData> get _roomItems =>
      _catalog?.items.where((i) => i.itemType == 'room_item').toList() ?? [];

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final coins = _inventory?.coinsBalance ?? 0;

    return Scaffold(
      backgroundColor: SpecBg.canvas,
      appBar: AppBar(
        backgroundColor: SpecBg.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          '我的小窝',
          style: TextStyle(
            fontSize: SpecTypo.sizeCardTitle,
            fontWeight: SpecTypo.medium,
            color: SpecText.primary,
          ),
        ),
        actions: [
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '🪙 $coins',
                  style: const TextStyle(
                    fontSize: SpecTypo.sizeLabelSmall,
                    fontWeight: SpecTypo.medium,
                    color: SpecText.purple,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SpecBrand.mochiRose))
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
          const Text('😿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('加载失败了喵',
              style: TextStyle(fontSize: SpecTypo.sizeCardBody, color: SpecText.primary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9A825),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('重试',
                  style: TextStyle(fontSize: 13, fontWeight: SpecTypo.medium, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        Column(
          children: [
            // ===== 1. 房间预览 =====
            _buildRoomPreview(),
            const SizedBox(height: 12),

            // ===== 2. §3.2 提示条 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SpecSpacing.pageH),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/study'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Text('🏠', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '小窝装饰不会变成学习进度，主线在首页 → 去学习',
                          style: TextStyle(
                            fontSize: SpecTypo.sizeTiny,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ===== 3. Tabs =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SpecSpacing.pageH),
              child: Container(
                decoration: BoxDecoration(
                  color: SpecBg.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerHeight: 0,
                  indicator: BoxDecoration(
                    color: const Color(0xFFF9A825),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: SpecText.secondary,
                  labelStyle: const TextStyle(
                    fontSize: SpecTypo.sizeLabelSmall,
                    fontWeight: SpecTypo.medium,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: SpecTypo.sizeLabelSmall,
                    fontWeight: SpecTypo.regular,
                  ),
                  tabs: const [
                    Tab(text: '全部'),
                    Tab(text: '已拥有'),
                    Tab(text: '已装备'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ===== 4. 物品网格 =====
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildItemGrid(_roomItems),
                  _buildItemGrid(_roomItems.where((i) => _isOwned(i.itemId)).toList()),
                  _buildItemGrid(_roomItems.where((i) => _isEquipped(i.itemId)).toList()),
                ],
              ),
            ),
          ],
        ),

        // ===== 5. 回到学习 chip =====
        const Positioned(
          top: 0,
          right: SpecSpacing.pageH,
          child: SpecBackToStudyChip(),
        ),
      ],
    );
  }

  // ==================== 房间预览 ====================

  Widget _buildRoomPreview() {
    final decorId  = _getEquippedInSlot('decor');
    final floorId  = _getEquippedInSlot('floor');
    final decorEmoji = decorId != null ? (_roomDecorEmoji[decorId] ?? '✨') : null;
    final floorEmoji = floorId != null ? (_roomFloorEmoji[floorId] ?? '🟫') : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpecSpacing.pageH),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          // 暖米色背景，营造"房间"感
          color: const Color(0xFFFAF3E8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            // 地板纹理提示
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEE0C8),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
              ),
            ),

            // 地板物品（floor slot）
            if (floorEmoji != null)
              Positioned(
                bottom: 10,
                left: 24,
                child: Text(floorEmoji, style: const TextStyle(fontSize: 28)),
              ),

            // 猫咪（主角始终在中央）
            const Center(
              child: Text('🐱', style: TextStyle(fontSize: 72)),
            ),

            // 装饰物品（decor slot — 右上角）
            if (decorEmoji != null)
              Positioned(
                top: 18,
                right: 24,
                child: Text(decorEmoji, style: const TextStyle(fontSize: 28)),
              ),

            // 槽位 chips（左上）
            Positioned(
              top: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _slotLabel.entries.map((e) {
                  final id = _getEquippedInSlot(e.key);
                  final filled = id != null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: filled
                            ? const Color(0xFFF9A825).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: SpecRadius.pillRadius,
                        border: Border.all(
                          color: filled
                              ? const Color(0xFFF9A825).withValues(alpha: 0.4)
                              : const Color(0xFFE8DFCF),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: SpecTypo.sizeTiny,
                          fontWeight: SpecTypo.medium,
                          color: filled ? const Color(0xFF5D4037) : SpecText.tertiary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 无装备时的提示
            if (decorId == null && floorId == null)
              const Positioned(
                bottom: 12,
                right: 14,
                child: Text(
                  '小窝还空空的喵~',
                  style: TextStyle(fontSize: SpecTypo.sizeTiny, color: SpecText.tertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 物品网格 ====================

  Widget _buildItemGrid(List<CatalogItemData> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏠', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              '这里还没有东西喵~',
              style: TextStyle(fontSize: SpecTypo.sizeLabel, color: SpecText.secondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 4, SpecSpacing.pageH, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildItemCard(items[i]),
    );
  }

  Widget _buildItemCard(CatalogItemData item) {
    final owned    = _isOwned(item.itemId);
    final equipped = _isEquipped(item.itemId);
    final emoji    = _itemEmoji[item.itemId] ?? '🏠';

    return GestureDetector(
      onTap: owned && !equipped
          ? () => _equip(item)
          : (!owned ? () => _purchase(item) : null),
      child: Container(
        decoration: BoxDecoration(
          color: SpecBg.card,
          borderRadius: BorderRadius.circular(14),
          border: equipped
              ? Border.all(color: const Color(0xFFF9A825).withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 缩略图
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 6),

            // 物品名
            Text(
              item.name,
              style: const TextStyle(
                fontSize: SpecTypo.sizeLabelSmall,
                fontWeight: SpecTypo.medium,
                color: SpecText.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),

            // 状态文案
            _buildStatusLabel(item, owned, equipped),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLabel(CatalogItemData item, bool owned, bool equipped) {
    if (equipped) {
      return const Text(
        '已摆放',
        style: TextStyle(
          fontSize: SpecTypo.sizeTiny,
          fontWeight: SpecTypo.medium,
          color: Color(0xFFF9A825),
        ),
      );
    }
    if (owned) {
      return GestureDetector(
        onTap: _isActing ? null : () => _equip(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF9A825),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '摆放',
            style: TextStyle(
              fontSize: SpecTypo.sizeTiny,
              fontWeight: SpecTypo.medium,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return Text(
      '${item.coinPrice} 币',
      style: const TextStyle(
        fontSize: SpecTypo.sizeTiny,
        color: SpecText.tertiary,
      ),
    );
  }
}
