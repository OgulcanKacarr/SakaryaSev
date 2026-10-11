import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final Function(int) onSelected;

  const AppSidebar({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: const Color(0xff111827),
      child: Column(
        children: [

          const SizedBox(height: 40),

          const Icon(
            Icons.directions_bus,
            size: 55,
            color: Colors.white,
          ),

          const SizedBox(height: 10),

          const Text(
            "SEV TAKİP",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 40),


          menuItem(
            Icons.directions_bus,
            "Gelen Araçlar",
            0,
          ),

          menuItem(
            Icons.settings,
            "Ayarlar",
            1,
          ),

        ],
      ),
    );
  }


  Widget menuItem(
      IconData icon,
      String title,
      int index,
      ) {

    return InkWell(

      onTap: (){
        onSelected(index);
      },

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 18,
        ),

        child: Row(
          children: [

            Icon(
              icon,
              color: Colors.white70,
            ),

            const SizedBox(width: 15),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            )

          ],
        ),
      ),
    );
  }
}