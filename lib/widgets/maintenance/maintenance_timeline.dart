import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'timeline/timeline_event.dart';
import '../../theme/app_colors.dart';

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
            color: AppColors.yellow,
        ),
          builder: TimelineTileBuilder(
            itemCount: events.length,
            contentsAlign: ContentsAlign.basic,

            indicatorBuilder: (context, index) {
                return Container(
                width: 14,
                height: 14,
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

                // child: Center(
                //     child: Container(
                //     width: 27,
                //     height: 27,
                //     decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         color: AppColors.mainBackground,
                //         border: Border.all(
                //         color: AppColors.yellow.withOpacity(.8),
                //         width: 1.5,
                //         ),
                //     ),

                //     ),
                // ),
                );
            },

            startConnectorBuilder: (context, index) =>
                const SolidLineConnector(),

            endConnectorBuilder: (context, index) =>
                const SolidLineConnector(),

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
          )
        ),
    );
  }
}