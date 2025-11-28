import 'package:flutter/material.dart';
import 'package:spotshare/services/api_client.dart';
import 'package:spotshare/utils/constants.dart'; // Indispensable pour dGreen

class TripCardItem extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;

  const TripCardItem({
    super.key,
    required this.trip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ApiClient apiClient = ApiClient();

    final String title = trip["trip_title"] ?? "Sans titre";
    final String? bannerPath = trip["banner"];
    String? fullBannerUrl;

    if (bannerPath != null && bannerPath.isNotEmpty) {
      if (bannerPath.startsWith("http")) {
        fullBannerUrl = bannerPath;
      } else {
        final cleanPath = bannerPath.startsWith('/') ? bannerPath.substring(1) : bannerPath;
        fullBannerUrl = "${apiClient.baseUrl}/$cleanPath";
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[900],
        ),
        clipBehavior: Clip.antiAlias, // Coupe tout ce qui dépasse des bords arrondis
        child: Stack(
          children: [
            // 1. IMAGE DE FOND OU FALLBACK (Ton dégradé)
            Positioned.fill(
              child: fullBannerUrl != null
                  ? Image.network(
                      fullBannerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                    )
                  : _buildFallbackImage(),
            ),

            // 2. OMBRE (Gradient noir pour lire le texte)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // 3. TEXTE (Titre + Date)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (trip["start_date"] != null)
                    Text(
                      trip["start_date"],
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TON WIDGET DE REMPLACEMENT ---
  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [dGreen, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.flight_takeoff, color: Colors.black26, size: 50),
      ),
    );
  }
}