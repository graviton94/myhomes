import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

/// Opens the room board on [item]'s room with its square flashing.
void openItem(BuildContext context, HomeData d, Item item) {
  final spaceId = d.container(item.containerId)?.spaceId;
  if (spaceId == null) return;
  context.push('/space/$spaceId?item=${item.id}');
}
