import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth.dart';
import '../../features/room_canvas/models/placed_furniture.dart';
import '../../features/room_canvas/storage/room_canvas_storage.dart';
import '../../features/room_canvas/widgets/furniture_bottom_panel.dart';
import '../../features/room_canvas/widgets/room_canvas_view.dart';
import '../theme/tokens.dart';

/// 需求12 — 屋内布置画布 v1
///
/// 一个独立的布置页：用户可以拖动 1200×900 的场景画布、把已购入的
/// room_item 摆到画布上、拖动调整位置、删除。布局保存在本地
/// SharedPreferences，关卡重启后可恢复。
///
/// §3.2 副机制纪律：本页面纯展示+互动，不产生任何学习收益。
class RoomCanvasPage extends StatefulWidget {
  const RoomCanvasPage({
    super.key,
    this.apiClient,
    this.storage,
  });

  /// 注入用：测试时传入 stub
  final ApiClient? apiClient;
  final RoomCanvasStorage? storage;

  @override
  State<RoomCanvasPage> createState() => _RoomCanvasPageState();
}

class _RoomCanvasPageState extends State<RoomCanvasPage> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  RoomCanvasStorage? _storage;
  bool _ownsApiClient = false;

  bool _isLoading = true;
  String? _error;

  List<OwnedItemData> _ownedRoomItems = [];
  List<PlacedFurniture> _placed = [];
  String? _selectedInstanceId;

  Offset _viewportOffset = Offset.zero;
  Size _viewportSize = Size.zero;

  static int _instanceCounter = 0;

  @override
  void initState() {
    super.initState();
    _ownsApiClient = widget.apiClient == null;
    _bootstrap();
  }

  @override
  void dispose() {
    if (_ownsApiClient) {
      _apiClient.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // PR-C-β: RoomCanvasStorage is per-user. Tests inject `storage`
      // explicitly; production reads the bound user from AuthScope.
      final userId = AuthScope.currentUserIdOf(context);
      _storage = widget.storage ?? await RoomCanvasStorage.open(userId: userId);
      final inventory = await _apiClient.getInventory();
      final placed = await _storage!.load();
      if (!mounted) return;
      setState(() {
        _ownedRoomItems = inventory.ownedItems
            .where((i) => i.itemType == 'room_item')
            .toList();
        _placed = placed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _persist() async {
    if (_storage == null) return;
    await _storage!.save(_placed);
  }

  String _newInstanceId() {
    _instanceCounter += 1;
    return 'pf-${DateTime.now().microsecondsSinceEpoch}-$_instanceCounter';
  }

  // ==================== 操作 ====================

  void _addFurniture(OwnedItemData item) {
    // 默认放在当前视野中心
    final center = _viewportSize == Size.zero
        ? const Offset(
            RoomCanvasGeometry.sceneWidth / 2,
            RoomCanvasGeometry.sceneHeight / 2,
          )
        : _viewportOffset +
            Offset(_viewportSize.width / 2, _viewportSize.height / 2);

    final clamped = RoomCanvasGeometry.clampFurnitureCenter(
      center.dx,
      center.dy,
    );

    final newItem = PlacedFurniture(
      instanceId: _newInstanceId(),
      furnitureId: item.itemId,
      x: clamped.$1,
      y: clamped.$2,
      zIndex: _placed.length,
    );
    setState(() {
      _placed = [..._placed, newItem];
      _selectedInstanceId = newItem.instanceId;
    });
    _persist();
  }

  void _moveFurniture(String instanceId, double dx, double dy) {
    final idx = _placed.indexWhere((p) => p.instanceId == instanceId);
    if (idx == -1) return;
    final f = _placed[idx];
    final clamped = RoomCanvasGeometry.clampFurnitureCenter(f.x + dx, f.y + dy);
    setState(() {
      _placed = [..._placed];
      _placed[idx] = f.copyWith(x: clamped.$1, y: clamped.$2);
    });
    _persist();
  }

  void _deleteFurniture(String instanceId) {
    setState(() {
      _placed = _placed.where((p) => p.instanceId != instanceId).toList();
      if (_selectedInstanceId == instanceId) {
        _selectedInstanceId = null;
      }
    });
    _persist();
  }

  void _selectFurniture(String instanceId) {
    if (_selectedInstanceId != instanceId) {
      setState(() => _selectedInstanceId = instanceId);
    }
  }

  void _deselect() {
    if (_selectedInstanceId != null) {
      setState(() => _selectedInstanceId = null);
    }
  }

  void _onViewportChanged(Offset offset, Size size) {
    _viewportOffset = offset;
    _viewportSize = size;
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpecBg.canvas,
      appBar: AppBar(
        backgroundColor: SpecBg.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          '布置小窝',
          style: TextStyle(
            fontSize: SpecTypo.sizeCardTitle,
            fontWeight: SpecTypo.medium,
            color: SpecText.primary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SpecBrand.mochiRose),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            '加载失败了喵',
            style: TextStyle(
              fontSize: SpecTypo.sizeCardBody,
              color: SpecText.primary,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _bootstrap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9A825),
                borderRadius: BorderRadius.circular(SpecRadius.small),
              ),
              child: const Text(
                '重试',
                style: TextStyle(
                  fontSize: SpecTypo.sizeCardSmall,
                  fontWeight: SpecTypo.medium,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: RoomCanvasView(
            placed: _placed,
            selectedInstanceId: _selectedInstanceId,
            onSelect: _selectFurniture,
            onDeselect: _deselect,
            onMoveFurniture: _moveFurniture,
            onDeleteFurniture: _deleteFurniture,
            onViewportChanged: _onViewportChanged,
          ),
        ),
        FurnitureBottomPanel(
          ownedRoomItems: _ownedRoomItems,
          onPick: _addFurniture,
        ),
      ],
    );
  }
}
