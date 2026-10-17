/// The household inventory as plain immutable data, with JSON round-tripping.
/// The app stores one [HomeData] per household (a JSON file in guest mode).
library;

enum ItemCategory { food, household, tools, medicine, other }

enum LogType { add, move, use, usedUp, edit, remove }

class Space {
  const Space({required this.id, required this.name, required this.code, this.photoPath, this.icon, this.outside = false});

  final String id;
  final String name;

  /// Prefix such as `LIV`, fixed at creation.
  final String code;
  final String? photoPath;

  /// Icon key from [iconKeys]; null draws the default room icon.
  final String? icon;

  /// A place outside the home: the car, the office, someone things are lent to.
  final bool outside;

  Space copyWith({String? name, String? photoPath, bool clearPhoto = false, String? icon}) => Space(
    id: id,
    name: name ?? this.name,
    code: code,
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    icon: icon ?? this.icon,
    outside: outside,
  );

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'code': code, 'photoPath': photoPath, 'icon': icon, 'outside': outside};

  factory Space.fromJson(Map<String, Object?> j) => Space(
    id: j['id'] as String,
    name: j['name'] as String,
    code: j['code'] as String,
    photoPath: j['photoPath'] as String?,
    icon: j['icon'] as String?,
    outside: j['outside'] as bool? ?? false,
  );
}

/// A storage spot (drawer, shelf, box). Items sit in numbered squares that
/// wrap to the screen width; there is no fixed size, a free square is always
/// available after the last one.
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

  Storage copyWith({
    String? name,
    String? photoPath,
    bool clearPhoto = false,
    String? icon,
    DateTime? returnBy,
    bool clearReturnBy = false,
  }) => Storage(
    id: id,
    spaceId: spaceId,
    parentId: parentId,
    name: name ?? this.name,
    code: code,
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
  });

  final String id;
  final String batchId;
  final LogType type;
  final String itemName;
  final int qty;
  final DateTime at;
  final String? fromContainerId;
  final String? toContainerId;

  Map<String, Object?> toJson() => {
    'id': id,
    'batchId': batchId,
    'type': type.name,
    'itemName': itemName,
    'qty': qty,
    'at': at.toIso8601String(),
    'from': fromContainerId,
    'to': toContainerId,
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
