import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view/home/home_page.dart';

class DepartureCard extends ConsumerWidget {
  final String departure;

  const DepartureCard({
    super.key,
    required this.departure,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final vm = ref.watch(homeProvider);

    final list = vm.getByDeparture(departure);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              children: [

                const Icon(Icons.directions_bus),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    "$departure'dan Gelen Araçlar",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                CircleAvatar(
                  radius: 14,
                  child: Text("${list.length}"),
                )

              ],
            ),

            const Divider(),

            Expanded(
              child: list.isEmpty
                  ? const Center(
                child: Text(
                  "Henüz araç gelmedi.",
                ),
              )
                  : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {

                  final bus = list[i];

                  return ListTile(

                    dense: true,

                    leading: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                    ),

                    title: Text(bus.plate),

                    subtitle: Text(
                      "${bus.driver}\n${bus.region}",
                    ),

                    trailing: Text(
                      "${bus.time.hour.toString().padLeft(2, "0")}:${bus.time.minute.toString().padLeft(2, "0")}",
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}