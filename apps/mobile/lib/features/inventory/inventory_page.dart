import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

/// InventoryPage - P2 Phase 2D minimal readiness UI.
///
/// Shows owned items and coins balance. Allows purchasing from catalog.
/// This is NOT the full Phase 3 shop/outfit UI — it's a minimal debug/readiness page.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  CatalogResponse? _catalog;
  InventoryStateData? _inventory;
  bool _isLoading = true;
  String? _error;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiClient.getShopCatalog(),
        _apiClient.getInventory(),
      ]);
      setState(() {
        _catalog = results[0] as CatalogResponse;
        _inventory = results[1] as InventoryStateData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _purchase(CatalogItemData item) async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      final key = 'purchase-${item.itemId}-${DateTime.now().millisecondsSinceEpoch}';
      final response = await _apiClient.purchaseItem(
        itemId: item.itemId,
        idempotencyKey: key,
      );

      if (!mounted) return;

      if (response.purchaseResult.isSuccess) {
        setState(() => _inventory = response.inventory);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('买到了「${item.name}」~')),
        );
      } else {
        final msg = _errorMessage(response.purchaseResult.errorCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('购买失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  String _errorMessage(String? code) {
    switch (code) {
      case 'COINS_NOT_ENOUGH':
        return '金币不够啦，多学几个单词吧~';
      case 'ITEM_ALREADY_OWNED':
        return '已经拥有这个啦~';
      case 'ITEM_LEVEL_LOCKED':
        return '等级还不够，继续加油~';
      case 'ITEM_NOT_FOUND':
        return '找不到这个物品';
      default:
        return '购买失败';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏与商店'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('加载失败：$_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final inv = _inventory!;
    final catalog = _catalog!;
    final ownedIds = inv.ownedItems.map((o) => o.itemId).toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance card
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '金币余额: ${inv.coinsBalance}',
                    key: const Key('inventory-coins-balance'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '已拥有: ${inv.ownedItems.length}',
                    key: const Key('inventory-owned-count'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Owned items
          if (inv.ownedItems.isNotEmpty) ...[
            Text(
              '我的收藏',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...inv.ownedItems.map((item) => Card(
                  child: ListTile(
                    leading: Icon(
                      item.itemType == 'outfit'
                          ? Icons.checkroom
                          : Icons.chair,
                      color: Colors.deepOrange,
                    ),
                    title: Text(item.itemId),
                    subtitle: Text('${item.itemType} / ${item.slot}'),
                    trailing: const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          // Catalog
          Text(
            '商店',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...catalog.items.map((item) {
            final owned = ownedIds.contains(item.itemId);
            return Card(
              child: ListTile(
                leading: Icon(
                  item.itemType == 'outfit'
                      ? Icons.checkroom
                      : Icons.chair,
                  color: owned ? Colors.grey : Colors.orange,
                ),
                title: Text(item.name),
                subtitle: Text(
                  '${item.coinPrice} 金币 · Lv.${item.requiredLevel}+',
                ),
                trailing: owned
                    ? const Text('已拥有',
                        style: TextStyle(color: Colors.grey))
                    : ElevatedButton(
                        onPressed: _isPurchasing
                            ? null
                            : () => _purchase(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('购买'),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
