part of 'item_form_screen.dart';

/// The square left of the name: the photo, else the icon on its category's
/// colour, with a small camera mark.
class _IconSquare extends StatelessWidget {
  const _IconSquare({super.key, this.photoPath, this.iconKey, required this.category, required this.onTap});

  final String? photoPath;
  final String? iconKey;
  final ItemCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).photo,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ItemThumb(category: category, photoPath: photoPath, iconKey: iconKey, size: 60),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(Icons.photo_camera_rounded, size: 14, color: c.mutedFg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable line: icon, text, and "바꾸기" at the end (넣을 곳, 수량).
class _Row extends StatelessWidget {
  const _Row({super.key, required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
          child: Row(
            children: [
              Icon(icon, color: c.primaryInk, size: 20),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(text, style: t.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text(AppLocalizations.of(context).change, style: t.labelLarge?.copyWith(color: c.link)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the four "더 적기" tiles: icon, name, and what is set now.
class _MoreTile extends StatelessWidget {
  const _MoreTile({super.key, required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: c.fg),
              const SizedBox(height: 2),
              FitText(label, style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelSmall?.copyWith(color: c.mutedFg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon over label; four of these share one row.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.label, required this.selected, required this.onTap});

  final ItemCategory category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final (bg, ink) = categoryColors(context, category);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? bg : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categoryIcon(category), color: selected ? ink : c.mutedFg, size: 24),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: selected ? ink : c.fg, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

List<List<T>> _rowsOf3<T>(List<T> xs) => [for (var i = 0; i < xs.length; i += 3) xs.skip(i).take(3).toList()];
