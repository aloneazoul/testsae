import 'package:flutter/material.dart';
import 'package:spotshare/pages/Map/map_page.dart';

class TripMapOverlay extends StatelessWidget {
  final dynamic trip;
  final VoidCallback onClose;
  final Map<String, dynamic> userData;
  final String currentLoggedUserId;

  const TripMapOverlay({
    super.key,
    required this.trip,
    required this.onClose,
    required this.userData,
    required this.currentLoggedUserId,
  });

  @override
  Widget build(BuildContext context) {
    print(trip["trip_id"]);

    return Stack(
      children: [
        MapPage(data: 2, trip: trip),

        /// 🎀 APPBAR FIXÉE EN HAUT POUR RETOUR
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: Colors.black54,
            elevation: 0,
            title: const Text(
              "Retour",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onClose,
            ),
          ),
        ),
      ],
    );
  }
}
