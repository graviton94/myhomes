/// The household inventory as plain immutable data, with JSON round-tripping.
/// The app stores one [HomeData] per household (a JSON file in guest mode).
library;

enum ItemCategory { food, household, tools, medicine, other }

enum LogType { add, move, use, usedUp, edit, remove }

/// A room's place on the floor plan, in 0.5 m squares from the plan's top left.
class PlanRect {
  const PlanRect(this.x, this.y, this.w, this.h);

  final int x, y, w, h;

  int get right => x + w;
  int get bottom => y + h;

  bool overlaps(PlanRect o) => x < o.right && o.x < right && y < o.bottom && o.y < bottom;

  List<int> toJson() => [x, y, w, h];

  static PlanRect? fromJson(Object? j) {
    if (j is! List || j.length != 4) return null;
    return PlanRect(j[0] as int, j[1] as int, j[2] as int, j[3] as int);
  }

  @override
  bool operator ==(Object other) => other is PlanRect && other.x == x && other.y == y && other.w == w && other.h == h;

  @override
  int get hashCode => Object.hash(x, y, w, h);

  @override
  String toString() => 'PlanRect($x, $y, $w, $h)';
}

class Space {
  const Space({required this.id, required this.name, required this.code, this.photoPath, this.icon, this.outside = false, this.plan});

  final String id;
  final String name;

  /// Prefix such as `LIV`, fixed at creation.
  final String code;
  final String? photoPath;

  /// Icon key from [iconKeys]; null draws the default room icon.
  final String? icon;

  /// A place outside the home: the car, the office, someone things are lent to.
  final bool outside;

  /// Where the room sits on the floor plan; null = not placed yet.
  final PlanRect? plan;

  Space copyWith({String? name, String? photoPath, bool clearPhoto = false, String? icon, PlanRect? plan, bool clearPlan = false}) => Space(
    id: id,
    name: name ?? this.name,
    code: code,
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    icon: icon ?? this.icon,
    outside: outside,
    plan: clearPlan ? null : (plan ?? this.plan),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'photoPath': photoPath,
    'icon': icon,
    'outside': outside,
    'plan': ?plan?.toJson(),
  };

  factory Space.fromJson(Map<String, Object?> j) => Space(
    id: j['id'] as String,
    name: j['name'] as String,
    code: j['code'] as String,
    photoPath: j['photoPath'] as String?,
    icon: j['icon'] as String?,
    outside: j['outside'] as bool? ?? false,
    plan: PlanRect.fromJson(j['plan']),
  );
}

/// A storage spot (drawer, shelf, box). Items sit in numbered squares that
/// wrap to the screen width; there is no fixed size, a free square is always
/// available after the last one.
/// How a storage spot holds things (v0.7):
/// - [furniture]: stays put (fridge, wardrobe, TV stand); split into [section]s
///   (shelves, drawers) listed top to bottom.
/// - [box]: moved as a whole (box, basket, toolbox); numbered; sits in a
///   section, another box or on a room's floor.
/// - [spot]: just a place (under the sofa, car boot, a friend's home).
enum StorageKind { spot, furniture, section, box }

class Storage {
  const Storage({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.code,
    this.parentId,
    this.photoPath,
    this.icon,
    this.returnBy,
    this.kind = StorageKind.spot,
    this.number,
  });

  final String id;
  final String spaceId;
  final String? parentId;
  final String name;
  final String code;
  final String? photoPath;

  /// Icon key from [iconKeys]; null draws the default storage icon.
  final String? icon;

  /// For things lent out: the day they should come back.
  final DateTime? returnBy;

  final StorageKind kind;

  /// Box number, written on the box with a marker ("상자 3").
  final int? number;

  Storage copyWith({
    String? name,
    String? photoPath,
    bool clearPhoto = false,
    String? icon,
    DateTime? returnBy,
    bool clearReturnBy = false,
    String? spaceId,
    String? parentId,
    bool clearParent = false,
    String? code,
  }) => Storage(
    id: id,
    spaceId: spaceId ?? this.spaceId,
    parentId: clearParent ? null : (parentId ?? this.parentId),
    name: name ?? this.name,
    code: code ?? this.code,
    kind: kind,
    number: number,
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    icon: icon ?? this.icon,
    returnBy: clearReturnBy ? null : (returnBy ?? this.returnBy),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'spaceId': spaceId,
    'parentId': parentId,
    'name': name,
    'code': code,
    'photoPath': photoPath,
    'icon': icon,
    'returnBy': returnBy?.toIso8601String(),
    if (kind != StorageKind.spot) 'kind': kind.name,
    'number': ?number,
  };

  factory Storage.fromJson(Map<String, Object?> j) => Storage(
    id: j['id'] as String,
    spaceId: j['spaceId'] as String,
    parentId: j['parentId'] as String?,
    name: j['name'] as String,
    code: j['code'] as String,
    photoPath: j['photoPath'] as String?,
    icon: j['icon'] as String?,
    returnBy: j['returnBy'] == null ? null : DateTime.parse(j['returnBy'] as String),
    kind: StorageKind.values.where((k) => k.name == j['kind']).firstOrNull ?? StorageKind.spot,
    number: j['number'] as int?,
  );
}

class Item {
  const Item({
    required this.id,
    required this.containerId,
    required this.slot,
    required this.name,
    this.category = ItemCategory.other,
    this.qty = 1,
    this.expiresOn,
    this.photoPath,
    this.note = '',
    this.icon,
    this.minQty,
    required this.updatedAt,
  });

  final String id;
  final String containerId;

  /// 0-based cell index in the container grid.
  final int slot;
  final String name;
  final ItemCategory category;
  final int qty;
  final DateTime? expiresOn;
  final String? photoPath;
  final String note;

  /// Icon key from [iconKeys]; null draws the category icon.
  final String? icon;

  /// Consumables: below this many it goes on the shopping list (null = not tracked).
  final int? minQty;
  final DateTime updatedAt;

  Item copyWith({
    String? containerId,
    int? slot,
    String? name,
    ItemCategory? category,
    int? qty,
    DateTime? expiresOn,
    bool clearExpiry = false,
    String? photoPath,
    String? note,
    String? icon,
    int? minQty,
    bool clearMinQty = false,
    required DateTime updatedAt,
  }) => Item(
    id: id,
    containerId: containerId ?? this.containerId,
    slot: slot ?? this.slot,
    name: name ?? this.name,
    category: category ?? this.category,
    qty: qty ?? this.qty,
    expiresOn: clearExpiry ? null : (expiresOn ?? this.expiresOn),
    photoPath: photoPath ?? this.photoPath,
    note: note ?? this.note,
    icon: icon ?? this.icon,
    minQty: clearMinQty ? null : (minQty ?? this.minQty),
    updatedAt: updatedAt,
  );

  /// Same kind of thing: merged into one stack when moved together.
  bool sameKindAs(Item o) =>
      name.trim().toLowerCase() == o.name.trim().toLowerCase() && category == o.category && _sameDay(expiresOn, o.expiresOn);

  Map<String, Object?> toJson() => {
    'id': id,
    'containerId': containerId,
    'slot': slot,
    'name': name,
    'category': category.name,
    'qty': qty,
    'expiresOn': expiresOn?.toIso8601String(),
    'photoPath': photoPath,
    'note': note,
    'icon': icon,
    'minQty': ?minQty,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Item.fromJson(Map<String, Object?> j) => Item(
    id: j['id'] as String,
    containerId: j['containerId'] as String,
    slot: j['slot'] as int,
    name: j['name'] as String,
    category: ItemCategory.values.byName(j['category'] as String? ?? 'other'),
    qty: j['qty'] as int? ?? 1,
    expiresOn: j['expiresOn'] == null ? null : DateTime.parse(j['expiresOn'] as String),
    photoPath: j['photoPath'] as String?,
    note: j['note'] as String? ?? '',
    icon: j['icon'] as String?,
    minQty: j['minQty'] as int?,
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );
}

bool _sameDay(DateTime? a, DateTime? b) => a == null ? b == null : (b != null && a.year == b.year && a.month == b.month && a.day == b.day);

/// One line of the activity history. Batch actions share a [batchId].
class LogEntry {
  const LogEntry({
    required this.id,
    required this.batchId,
    required this.type,
    required this.itemName,
    required this.qty,
    required this.at,
    this.fromContainerId,
    this.toContainerId,
    this.by,
  });

  final String id;
  final String batchId;
  final LogType type;
  final String itemName;
  final int qty;
  final DateTime at;
  final String? fromContainerId;
  final String? toContainerId;

  /// Member uid who made the change, in a shared home.
  final String? by;

  Map<String, Object?> toJson() => {
    'id': id,
    'batchId': batchId,
    'type': type.name,
    'itemName': itemName,
    'qty': qty,
    'at': at.toIso8601String(),
    'from': fromContainerId,
    'to': toContainerId,
    'by': ?by,
  };

  factory LogEntry.fromJson(Map<String, Object?> j) => LogEntry(
    id: j['id'] as String,
    batchId: j['batchId'] as String,
    type: LogType.values.byName(j['type'] as String),
    itemName: j['itemName'] as String,
    qty: j['qty'] as int,
    at: DateTime.parse(j['at'] as String),
    fromContainerId: j['from'] as String?,
    toContainerId: j['to'] as String?,
    by: j['by'] as String?,
  );
}

class HomeData {
  const HomeData({this.spaces = const [], this.containers = const [], this.items = const [], this.log = const []});

  static const int schemaVersion = 1;

  final List<Space> spaces;
  final List<Storage> containers;
  final List<Item> items;

  /// Newest first.
  final List<LogEntry> log;

  bool get isEmpty => spaces.isEmpty;

  HomeData copyWith({List<Space>? spaces, List<Storage>? containers, List<Item>? items, List<LogEntry>? log}) =>
      HomeData(spaces: spaces ?? this.spaces, containers: containers ?? this.containers, items: items ?? this.items, log: log ?? this.log);

  Space? space(String id) => spaces.where((s) => s.id == id).firstOrNull;
  Storage? container(String id) => containers.where((c) => c.id == id).firstOrNull;
  Item? item(String id) => items.where((i) => i.id == id).firstOrNull;

  List<Storage> containersIn(String spaceId) => containers.where((c) => c.spaceId == spaceId && c.parentId == null).toList();
  List<Storage> childrenOf(String containerId) => containers.where((c) => c.parentId == containerId).toList();
  List<Item> itemsIn(String containerId) => items.where((i) => i.containerId == containerId).toList();

  /// Items in a space, including nested containers.
  int itemCountInSpace(String spaceId) {
    final ids = containers.where((c) => c.spaceId == spaceId).map((c) => c.id).toSet();
    return items.where((i) => ids.contains(i.containerId)).length;
  }

  /// "Living room › TV stand › Left drawer".
  List<String> pathOf(String containerId) {
    final parts = <String>[];
    var c = container(containerId);
    while (c != null) {
      parts.insert(0, c.name);
      c = c.parentId == null ? null : container(c.parentId!);
    }
    final first = container(containerId);
    final s = first == null ? null : space(first.spaceId);
    if (s != null) parts.insert(0, s.name);
    return parts;
  }

  Map<String, Object?> toJson() => {
    'v': schemaVersion,
    'spaces': [for (final s in spaces) s.toJson()],
    'containers': [for (final c in containers) c.toJson()],
    'items': [for (final i in items) i.toJson()],
    'log': [for (final l in log) l.toJson()],
  };

  factory HomeData.fromJson(Map<String, Object?> j) {
    List<T> list<T>(String key, T Function(Map<String, Object?>) f) => [
      for (final e in (j[key] as List? ?? const [])) f((e as Map).cast<String, Object?>()),
    ];
    return HomeData(
      spaces: list('spaces', Space.fromJson),
      containers: list('containers', Storage.fromJson),
      items: list('items', Item.fromJson),
      log: list('log', LogEntry.fromJson),
    );
  }
}
