import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'timeline/timeline_event.dart';
import '../../config/device_config.dart';
import '../../theme/app_colors.dart';
import '../date_label.dart';

class MaintenanceTimeline extends StatelessWidget {
  final List<TimelineEvent> events;

  // Fixed so every row's date(s) - and everything to their right - line up
  // on the same x coordinate regardless of card type or date text width.
  // Sized with headroom for the widest case at _dateFontSize (double-digit
  // month/day/year, e.g. "12·31·26") - a tighter width let that text
  // overflow into the card next to it on roughly half of all dates,
  // whichever happened to land on double digits.
  static const double _dateColumnWidth = 108;

  static const double _dateFontSize = 18;

  const MaintenanceTimeline({
    super.key,
    required this.events,
  });

  Widget _dateColumn(TimelineEvent event) {
    final dates = event.displayDates;

    return SizedBox(
      width: _dateColumnWidth,
      // Safety net: a Row/Column of Text doesn't self-limit to the width
      // it's given, so if a date's actual rendered width ever exceeds
      // _dateColumnWidth despite the headroom above, clip rather than let
      // it paint into the card sitting to its right.
      child: ClipRect(
      child: Padding(
        // iPad gets more breathing room off the timeline's circle node too
        // - the default 8px reads as cramped once the node itself grows
        // via DeviceConfig.timelineNodeScale.
        padding: EdgeInsets.only(left: DeviceConfig.isIpad ? 16 : 8),
        // Shrink-wraps to the widest date line, so the "to" row below -
        // stretched to fill that same width - centers itself over the
        // actual date text rather than the fixed date column.
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < dates.length; i++) ...[
                if (i > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.yellow.withOpacity(.7),
                        fontSize: _dateFontSize,
                      ),
                    ),
                  ),
                ],
                DateLabel(
                  date: dates[i],
                  color: AppColors.yellow,
                  fontSize: _dateFontSize,
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  // iPhone screens are narrow enough that the left-hand date column ate
  // meaningfully into the card's own width, so on iPhone (DeviceConfig.
  // isIphone) the date sits in its own row above the card instead - other
  // devices (iPad, moto_g) keep the side-by-side layout since their extra
  // width doesn't have that problem.
  Widget _dateHeader(TimelineEvent event) {
    final dates = event.displayDates;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < dates.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'to',
                  style: TextStyle(
                    color: AppColors.yellow.withOpacity(.7),
                    fontSize: _dateFontSize,
                  ),
                ),
              ),
            ],
            DateLabel(
              date: dates[i],
              color: AppColors.yellow,
              fontSize: _dateFontSize,
            ),
          ],
        ],
      ),
    );
  }

  Widget _indicatorIcon(TimelineEventType type, double nodeScale) {
    final style = TextStyle(
      fontSize: 14 * nodeScale,
      fontWeight: FontWeight.bold,
      color: AppColors.main,
    );

    switch (type) {
      case TimelineEventType.pm:
        return Text('PM', style: TextStyle(
          fontSize: 15 * nodeScale,
          fontWeight: FontWeight.bold,
          color: AppColors.main,
        ));
      case TimelineEventType.annual:
        return Text('AN', style: style);
      case TimelineEventType.rental:
        // The glyph sits visibly low in the fixed 30px circle on iPad
        // specifically - nudge it back up rather than touching the shared
        // vertical centering every other node relies on.
        final dollarSign = Text('\$', style: TextStyle(
          fontSize: 20 * nodeScale,
          fontWeight: FontWeight.bold,
          color: AppColors.main,
        ));

        return DeviceConfig.isIpad
            ? Transform.translate(
                offset: const Offset(0, -2),
                child: dollarSign,
              )
            : dollarSign;
      case TimelineEventType.issue:
        return Icon(Icons.build, size: 17 * nodeScale, color: AppColors.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Timeline.tileBuilder(
        // nodePosition: 0 sits the indicator flush against the scroll
        // viewport's left edge, and its glow shadow bleeds a few px past
        // that. The fix is this left padding, which is inside the clip
        // boundary (it's the scrollable's own `padding`, not an outer
        // wrapper) so the shadow has room without needing to touch
        // clipBehavior - the default Clip.hardEdge stays on, which is what
        // keeps scrolled-past tiles from bleeding above/below this fixed-
        // height box into whatever sits next to it on the page.
        padding: const EdgeInsets.only(left: 8),
        theme: TimelineThemeData(
            nodePosition: 0,
            color: AppColors.yellow,
        ),
          builder: TimelineTileBuilder(
            itemCount: events.length,
            contentsAlign: ContentsAlign.basic,

            indicatorBuilder: (context, index) {
                final nodeScale = DeviceConfig.timelineNodeScale;

                return Container(
                width: 30 * nodeScale,
                height: 30 * nodeScale,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: AppColors.yellow,

                    boxShadow: [
                    BoxShadow(
                        color: AppColors.yellow.withOpacity(.85),
                        blurRadius: 3,
                        spreadRadius: 1,
                    ),

                    BoxShadow(
                        color: AppColors.green.withOpacity(.35),
                        blurRadius: 2,
                        spreadRadius: 1,
                    ),
                    ],
                ),

                // iOS's "Bold Text" accessibility setting (on by default on
                // the iPads this app is tested on) silently merges
                // FontWeight.bold and a larger text scale onto every Text
                // widget - "PM" then no longer fits this fixed 30px circle
                // and gets clipped down to just "P". Same fix as
                // base_card.dart's _noAccessibilityTextStyling: force both
                // off for this node's label.
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.noScaling,
                    boldText: false,
                  ),
                  child: Center(
                      child: _indicatorIcon(events[index].type, nodeScale),
                  ),
                ),
                );
            },

            startConnectorBuilder: (context, index) =>
                const SolidLineConnector(),

            endConnectorBuilder: (context, index) =>
                const SolidLineConnector(),

            contentsBuilder: (context,index) {
                final event = events[index];

                // PM events keep the side-by-side layout on iPhone too -
                // only non-PM cards get the stacked treatment.
                if (DeviceConfig.isIphone && event.type != TimelineEventType.pm) {
                  // The header had no visual anchor to either neighbor, so
                  // it read as ambiguous - equally close to the card above
                  // as the one below. Dropping its own bottom padding (it
                  // now hugs the card via that card's own top inset, which
                  // is smaller than this top gap) and adding clear space
                  // above it makes it unambiguously belong to the card
                  // beneath.
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            _dateHeader(event),
                            event.build(context),
                        ],
                    ),
                  );
                }

                return Row(
                    mainAxisSize: MainAxisSize.min,
                    // The timeline node sits vertically centered within this
                    // whole row's height (set by whichever sibling here is
                    // tallest - normally the card), so centering the date
                    // column against the card here lines it up with the node
                    // too.
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        _dateColumn(event),
                        // iPad's date text runs wider than the 6px gap
                        // leaves room for, so the card content starts too
                        // soon and crowds the date node's right edge -
                        // give iPad specifically more breathing room here.
                        SizedBox(width: DeviceConfig.isIpad ? 32 : 6),
                        // A plain (non-flex) Row child gets an unbounded max
                        // width to measure its natural size, which breaks
                        // cards - like RentalTile - that use Expanded
                        // internally and need a bounded width to resolve.
                        // Flexible (loose) gives it a real bound while still
                        // letting narrower cards (pm/issue) report their own
                        // smaller natural width instead of being stretched.
                        Flexible(child: event.build(context)),
                    ],
                );
            },
          ),
        ),
    );
  }
}

