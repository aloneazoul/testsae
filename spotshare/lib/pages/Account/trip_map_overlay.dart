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
    final String ownerPseudo =
        userData['username'] ?? userData['pseudo'] ?? "Utilisateur";
    final String ownerImage =
        userData['profile_picture'] ?? userData['img'] ?? "";

    return Stack(
      children: [
        MapPage(
          data: 2,
          trip: trip,
          tripOwnerName: ownerPseudo,
          tripOwnerImage: ownerImage,
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: Colors.black54,
            elevation: 0,
            title: Text(
              "Voyage de $ownerPseudo",
              style: const TextStyle(
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
