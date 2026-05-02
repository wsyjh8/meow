/// 需求12 — 屋内布置画布 v1
///
/// 已摆放家具的本地数据模型。坐标 (x, y) 是场景画布坐标系，
/// 不是手机屏幕坐标系。
class PlacedFurniture {
  final String instanceId;
  final String furnitureId;
  double x;
  double y;
  int zIndex;

  PlacedFurniture({
    required this.instanceId,
    required this.furnitureId,
    required this.x,
    required this.y,
    this.zIndex = 0,
  });

  PlacedFurniture copyWith({double? x, double? y, int? zIndex}) {
    return PlacedFurniture(
      instanceId: instanceId,
      furnitureId: furnitureId,
      x: x ?? this.x,
      y: y ?? this.y,
      zIndex: zIndex ?? this.zIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'instance_id': instanceId,
        'furniture_id': furnitureId,
        'x': x,
        'y': y,
        'z_index': zIndex,
      };

  factory PlacedFurniture.fromJson(Map<String, dynamic> json) {
    return PlacedFurniture(
      instanceId: json['instance_id'] as String,
      furnitureId: json['furniture_id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 场景画布固定逻辑尺寸（v1 不可配置）。
class RoomCanvasGeometry {
  static const double sceneWidth = 1200.0;
  static const double sceneHeight = 900.0;

  /// 把家具中心点 clamp 到场景内（允许部分超出，但中心必须在场景内）。
  static (double, double) clampFurnitureCenter(double x, double y) {
    return (
      x.clamp(0.0, sceneWidth),
      y.clamp(0.0, sceneHeight),
    );
  }

  /// 把视野左上角 offset clamp 到合法范围。
  static (double, double) clampViewport(
    double dx,
    double dy,
    double viewportWidth,
    double viewportHeight,
  ) {
    final maxDx = (sceneWidth - viewportWidth).clamp(0.0, sceneWidth);
    final maxDy = (sceneHeight - viewportHeight).clamp(0.0, sceneHeight);
    return (
      dx.clamp(0.0, maxDx),
      dy.clamp(0.0, maxDy),
    );
  }
}
