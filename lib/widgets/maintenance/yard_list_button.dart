import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/device_config.dart';
import '../../models/lift.dart';
import '../../models/yard_list_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/lift_assets.dart';
import '../../views/inventory_check_screen.dart';
import '../action_ribbon.dart';
import '../hold_to_select_row.dart';

// Mobile counterpart to the JavaFX Lifts scene's "Predictive Yard List"
// report: lifts not currently out on rent, pulled from the same
// /maintenance/yard-list endpoint. Unlike the desktop report, each row here
// also shows whether the lift's maintenance is up to date, and holding a
// row selects that lift (same as picking it from the selector panel).
class YardListButton extends StatelessWidget {
  final ValueChanged<Lift> onLiftSelected;
  final String currentUserId;

  const YardListButton({
    super.key,
    required this.onLiftSelected,
    required this.currentUserId,
  });

  void _open(BuildContext context) {
    // Captured before the sheet opens: the sheet's own builder context gets
    // unmounted when it pops, so the inventory-check navigation (which
    // happens after that pop) has to push from this context instead.
    final outerContext = context;

    showModalBottomSheet(
      context: outerContext,
      backgroundColor: AppColors.main,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: FutureBuilder<List<YardListItem>>(
              future: ApiService().fetchYardList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.yellow),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Failed to load the yard list.',
                        style: TextStyle(color: AppColors.red),
                      ),
                    ),
                  );
                }

                return _YardListSheet(
                  items: snapshot.data ?? [],
                  onLiftSelected: onLiftSelected,
                  onOpenInventoryCheck: () {
                    Navigator.of(outerContext).pop();
                    Navigator.of(outerContext).push(
                      MaterialPageRoute(
                        builder: (_) => InventoryCheckScreen(
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.list_alt, color: AppColors.yellow),
        label: const Text(
          'Yard List',
          style: TextStyle(
            color: AppColors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Sheet body: title, a horizontal strip of lift-type icons that acts as a
// scroll position indicator (the icon for the section currently in view
// grows), and the grouped list itself.
class _YardListSheet extends StatefulWidget {
  final List<YardListItem> items;
  final ValueChanged<Lift> onLiftSelected;
  final VoidCallback onOpenInventoryCheck;

  const _YardListSheet({
    required this.items,
    required this.onLiftSelected,
    required this.onOpenInventoryCheck,
  });

  @override
  State<_YardListSheet> createState() => _YardListSheetState();
}

class _YardListSheetState extends State<_YardListSheet> {
  // Fixed row heights let the scroll position map directly to a section
  // index without measuring rendered widgets. The row height grows with
  // DeviceConfig.yardListRowTextScale so the bigger row text still fits.
  static const double _headerHeight = 40;
  static double get _rowHeight => 52 * DeviceConfig.yardListRowTextScale;

  // The remaining lift types top out at a handful of units each, so their
  // scroll position is close enough to a neighboring type here that they
  // don't need their own banner icon.
  static const Set<String> _bannerCodes = {'19s', '26', '26s', '32'};

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String?> _activeType = ValueNotifier<String?>(null);

  // Tapping the title swaps the whole row (title + dots/banner) for a
  // centered action ribbon, with the title itself becoming one of the
  // buttons — new actions just join that ribbon instead of each one
  // permanently claiming more of the title line.
  bool _optionsOpen = false;

  late List<Object> _entries;
  late List<String> _types;
  late List<double> _headerOffsets;
  late List<String> _bannerTypes;

  @override
  void initState() {
    super.initState();
    _buildEntries();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _YardListSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _buildEntries();
      _onScroll();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _activeType.dispose();
    super.dispose();
  }

  void _buildEntries() {
    _entries = [];
    _types = [];
    _headerOffsets = [];

    String? lastType;
    double offset = 0;

    for (final item in widget.items) {
      final type = item.liftType ?? 'Unknown';
      if (type != lastType) {
        _entries.add(type);
        _types.add(type);
        _headerOffsets.add(offset);
        offset += _headerHeight;
        lastType = type;
      }
      _entries.add(item);
      offset += _rowHeight;
    }

    _bannerTypes = _types
        .where((t) => _bannerCodes.contains(t.trim().toLowerCase()))
        .toList();

    _activeType.value = _bannerTypes.isNotEmpty ? _bannerTypes.first : null;
  }

  // Sections whose type isn't in the banner keep whichever banner icon
  // precedes them highlighted, so the icon approximates the scroll
  // position of its low-count neighbors too.
  void _onScroll() {
    if (_bannerTypes.isEmpty) return;
    final pos = _scrollController.offset;

    String active = _bannerTypes.first;
    for (var i = 0; i < _headerOffsets.length; i++) {
      if (_headerOffsets[i] > pos + 1) break;
      if (_bannerTypes.contains(_types[i])) {
        active = _types[i];
      }
    }

    if (active != _activeType.value) {
      _activeType.value = active;
    }
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Yard List';
    final countSuffix =
        DeviceConfig.isIphone ? '' : ' (${widget.items.length})';
    final titleChars = '$title$countSuffix';
    const titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

    // Small chevron sits right after the title text as the affordance that
    // it's tappable; its width is folded into the gradient math the same
    // way the title's own width is.
    const chevronWidth = 18.0;

    // Measured pixel widths, not character counts, so a char's gradient
    // color reflects where it actually lands on screen.
    final charWidths = [
      for (final ch in titleChars.split(''))
        (TextPainter(
          text: TextSpan(text: ch, style: titleStyle),
          textDirection: TextDirection.ltr,
        )..layout())
            .width,
    ];
    final titleWidth = charWidths.fold<double>(0, (a, b) => a + b);

    // First icon has no leading inset (flush against the dots); the rest
    // are spaced 8px apart.
    final bannerWidth = _bannerTypes.isEmpty
        ? 0.0
        : _bannerTypes.length * _LiftTypeBanner._baseSize +
            (_bannerTypes.length - 1) * 8;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            // Toggled open, the title collapses into a button matching the
            // Inventory Check one instead of sitting fixed to one side, so
            // the whole line becomes a single centered action ribbon —
            // reusing the rental-card widget gives future additions here
            // paging arrows and consistent styling for free.
            child: _optionsOpen
                ? ActionRibbon(
                    key: const ValueKey('options'),
                    color: AppColors.yellow,
                    buttonWidthScale: DeviceConfig.isIpad ? 0.75 : 1.0,
                    actions: [
                      ActionItem(
                        label: 'Yard List',
                        icon: Icons.expand_less,
                        color: AppColors.yellow,
                        onPressed: () =>
                            setState(() => _optionsOpen = false),
                      ),
                      ActionItem(
                        label: 'Inventory Check',
                        icon: Icons.fact_check_outlined,
                        color: AppColors.green,
                        onPressed: widget.onOpenInventoryCheck,
                      ),
                    ],
                  )
                : LayoutBuilder(
                    key: const ValueKey('browse'),
                    builder: (context, constraints) {
                      // t = 0 at the left edge of this row, 1 at the right edge, so
                      // true green sits at the row's true horizontal midpoint and
                      // true red only at the row's right edge, matching how the
                      // title and banner are actually laid out on screen.
                      final rowWidth = constraints.maxWidth;
                      final dotsStartX = titleWidth + chevronWidth;
                      final dotsWidth =
                          (rowWidth - titleWidth - chevronWidth - bannerWidth)
                              .clamp(0.0, rowWidth);

                      double cursor = 0;
                      final charColors = <Color>[];
                      for (final w in charWidths) {
                        final centerX = cursor + w / 2;
                        charColors.add(
                          _gradientColorAt(
                            rowWidth <= 0
                                ? 0
                                : (centerX / rowWidth).clamp(0.0, 1.0),
                          ),
                        );
                        cursor += w;
                      }

                      double bannerCursor = 0;
                      final bannerColors = [
                        for (var k = 0; k < _bannerTypes.length; k++)
                          _gradientColorAt(() {
                            if (k > 0) bannerCursor += 8;
                            final iconCenter =
                                bannerCursor + _LiftTypeBanner._baseSize / 2;
                            bannerCursor += _LiftTypeBanner._baseSize;
                            return rowWidth <= 0
                                ? 1.0
                                : ((dotsStartX + dotsWidth + iconCenter) /
                                        rowWidth)
                                    .clamp(0.0, 1.0);
                          }()),
                      ];

                      return Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                setState(() => _optionsOpen = !_optionsOpen),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      for (var i = 0;
                                          i < titleChars.length;
                                          i++)
                                        TextSpan(
                                          text: titleChars[i],
                                          style: titleStyle.copyWith(
                                              color: charColors[i]),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: chevronWidth,
                                  child: const Icon(
                                    Icons.expand_more,
                                    size: 18,
                                    color: AppColors.yellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _GradientDots(
                                    rowWidth: rowWidth,
                                    startX: dotsStartX,
                                  ),
                                ),
                                if (_bannerTypes.isNotEmpty)
                                  _LiftTypeBanner(
                                    types: _bannerTypes,
                                    colors: bannerColors,
                                    activeType: _activeType,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: widget.items.isEmpty
              ? const Center(
                  child: Text(
                    'No lifts currently in the yard.',
                    style: TextStyle(color: AppColors.yellow),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final entry = _entries[i];

                    if (entry is String) {
                      return SizedBox(
                        height: _headerHeight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              entry,
                              style: const TextStyle(
                                color: AppColors.yellow,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final item = entry as YardListItem;
                    final flagged = item.needsRepair || !item.upToDate;
                    final statusLabel = item.needsRepair
                        ? 'Needs Repair'
                        : (item.upToDate ? 'Up to date' : 'Needs PM');
                    final rowTextScale = DeviceConfig.yardListRowTextScale;

                    return SizedBox(
                      height: _rowHeight,
                      child: HoldToSelectRow(
                        onConfirmed: () {
                          Navigator.of(context).pop();
                          widget.onLiftSelected(Lift(
                            liftId: item.liftId ?? 0,
                            liftType: item.liftType,
                            serialNumber: item.serialNumber,
                            upToDate: item.upToDate,
                          ));
                        },
                        child: MediaQuery.withNoTextScaling(
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.circle,
                              size: 12 * rowTextScale,
                              color: flagged ? AppColors.red : AppColors.green,
                            ),
                            title: Text(
                              item.serialNumber ?? '',
                              style: TextStyle(
                                color: AppColors.yellow,
                                fontSize: 16 * rowTextScale,
                              ),
                            ),
                            trailing: Text(
                              statusLabel,
                              style: TextStyle(
                                color: flagged ? AppColors.red : AppColors.green,
                                fontSize: 12 * rowTextScale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// Yellow -> green -> red at position `t` (0 = left, 1 = right), matching
// the gradient used elsewhere for the lift serial selector.
Color _gradientColorAt(double t) {
  if (t <= .5) {
    return Color.lerp(AppColors.yellow, AppColors.green, t * 2)!;
  }
  return Color.lerp(AppColors.green, AppColors.red, (t - .5) * 2)!;
}

// Small circles at slightly varied size/spacing/altitude filling the gap
// between the title and the lift-type banner, colored by their actual x
// position in the row so the two anchored elements read as one connected
// gradient run instead of leaving a gap.
class _GradientDots extends StatelessWidget {
  final double rowWidth;
  final double startX;

  const _GradientDots({required this.rowWidth, required this.startX});

  static const double _baseSpacing = 13;
  static const double _minSize = 3;
  static const double _maxSize = 9;
  static const double _maxAltitude = 4;
  static const double _height = 24;
  // Keeps the first dot clear of the title text; the last dot still
  // reaches the full right edge, flush against the banner.
  static const double _leftMargin = 12;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final localWidth = constraints.maxWidth;
          final usableWidth =
              (localWidth - _leftMargin).clamp(0.0, localWidth);
          final dotCount =
              (usableWidth / _baseSpacing).floor().clamp(0, 40);
          if (dotCount == 0) return const SizedBox.shrink();

          // Re-seeded on every build so the jitter is stable across
          // rebuilds instead of drifting each time.
          final random = Random(7);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < dotCount; i++)
                _dot(i, dotCount, localWidth, usableWidth, random),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(
    int i,
    int dotCount,
    double localWidth,
    double usableWidth,
    Random random,
  ) {
    final size = _minSize + random.nextDouble() * (_maxSize - _minSize);
    final dx = (random.nextDouble() - 0.5) * 6;
    final dy = (random.nextDouble() - 0.5) * 2 * _maxAltitude;

    final slotCenter = _leftMargin +
        (dotCount <= 1 ? usableWidth : i / (dotCount - 1) * usableWidth);
    final t = rowWidth <= 0
        ? 0.5
        : ((startX + slotCenter) / rowWidth).clamp(0.0, 1.0);

    return Positioned(
      left: slotCenter + dx - size / 2,
      top: _height / 2 + dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _gradientColorAt(t),
        ),
      ),
    );
  }
}

// Row of lift-type icons above the list. The icon for whichever section is
// currently scrolled into view grows, acting as a "you are here" indicator.
class _LiftTypeBanner extends StatelessWidget {
  final List<String> types;
  final List<Color> colors;
  final ValueNotifier<String?> activeType;

  const _LiftTypeBanner({
    required this.types,
    required this.colors,
    required this.activeType,
  });

  static const double _baseSize = 26;
  static const double _activeSize = 44;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ValueListenableBuilder<String?>(
        valueListenable: activeType,
        builder: (context, active, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < types.length; i++)
                Padding(
                  // No leading inset on the first icon so the banner sits
                  // flush against the dots, matching the title's flush
                  // edge on the other side.
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width: types[i] == active ? _activeSize : _baseSize,
                      height: types[i] == active ? _activeSize : _baseSize,
                      child: Image.asset(
                        liftAssetPath(types[i]),
                        fit: BoxFit.contain,
                        color: types[i] == active
                            ? colors[i]
                            : colors[i].withOpacity(0.4),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
