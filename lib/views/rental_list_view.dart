import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/stop.dart';
import '../widgets/rental_card.dart';
import '../widgets/service_card.dart';
import '../widgets/base_card.dart';

class RentalListView extends StatefulWidget {
  final String driverId;

  const RentalListView({super.key, required this.driverId});

  @override
  _RentalListViewState createState() => _RentalListViewState();
}

class _RentalListViewState extends State<RentalListView> {
  late Future<List<Stop>> futureStops;
  List<TextEditingController> serialControllers = [];

  @override
  void initState() {
    super.initState();
    futureStops = ApiService().fetchStopsByDriver(widget.driverId);
  }

  @override
  void dispose() {
    for (var controller in serialControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _mapDriverId(String driverId) {
    const driverMap = {
      'JS': 'Jacob',
      'K': 'Kaleb',
      'A': 'Adrian',
      'JC': 'Jackson',
      'J': 'John',
      'B': 'Byron',
    };
    return driverMap[driverId] ?? driverId;
  }

  Future<void> _refreshRentals() async {
    setState(() {
      futureStops = ApiService().fetchStopsByDriver(widget.driverId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tasks for: ${_mapDriverId(widget.driverId)}")),
      body: FutureBuilder<List<Stop>>(
        future: futureStops,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No stops available.'));
          }

          List<Stop> stops = snapshot.data!;
          if (serialControllers.length != stops.length) {
            serialControllers =
                List.generate(stops.length, (index) => TextEditingController());
          }

          return RefreshIndicator(
            onRefresh: _refreshRentals,
            child: ListView.builder(
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];

                if (stop.type == 'RENTAL') {
                  return RentalCard(
                    stop: stop,
                    serialController: serialControllers[index],
                    onRefresh: _refreshRentals,
                  );
                } else if (stop.type == 'SERVICE') {
                  return ServiceCard(
                    stop: stop,
                    onRefresh: _refreshRentals,
                  );
                } else if (stop.liftType == 'HQ') {
                  return BaseCard(
                    stop: stop,
                    onRefresh: _refreshRentals, // refresh after HQ deletion
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
