import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view/home/home_page.dart';

class LastAnnouncementsCard extends ConsumerWidget {
  const LastAnnouncementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(homeProvider);

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Son Bildirimler",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const Divider(),

          Expanded(
            child: vm.announcements.isEmpty
                ? const Center(child: Text("Henüz bildirim yok."))
                : ListView.builder(
                    itemCount: vm.announcements.length,
                    itemBuilder: (_, i) {
                      final a = vm.announcements[i];

                      return ListTile(
                        leading: Icon(Icons.notifications),

                        title: Text(a.plate),

                        subtitle: Text("${a.driver} • ${a.region}"),

                        trailing: Text(
                          "${a.time.hour.toString().padLeft(2, '0')}:${a.time.minute.toString().padLeft(2, '0')}",
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
