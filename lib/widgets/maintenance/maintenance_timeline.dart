import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'timeline/timeline_event.dart';

class MaintenanceTimeline extends StatelessWidget {
  final List<TimelineEvent> events;

  const MaintenanceTimeline({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Timeline.tileBuilder(
        theme: TimelineThemeData(
          nodePosition: 0,
          color: Colors.amber,
        ),
        builder: TimelineTileBuilder.fromStyle(
          contentsAlign: ContentsAlign.basic,
          itemCount: events.length,
          indicatorStyle: IndicatorStyle.dot,
          connectorStyle: ConnectorStyle.solidLine,
          contentsBuilder: (context,index) {
            final event = events[index];

            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                if(event.isSpan)
                    Text(
                    '${event.start} → ${event.end}',
                    ),

                event.build(context),
                ],
            );
          },
        ),
      ),
    );
  }
}