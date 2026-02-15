import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/services/trip_service.dart';
import 'package:spotshare/services/api_client.dart';

import 'package:spotshare/pages/Publication/trip/create_trip_page.dart';
import 'package:spotshare/pages/Publication/trip/trip_details_page.dart';

class MesVoyagesPage extends StatefulWidget {
  const MesVoyagesPage({super.key});

  @override
  State<MesVoyagesPage> createState() => _MesVoyagesPageState();
}

class _MesVoyagesPageState extends State<MesVoyagesPage> {
  final TripService _tripService = TripService();
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    setState(() => _isLoading = true);

    final trips = await _tripService.getMyTrips();

    if (mounted) {
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    }
  }

  Future<void> _goToCreatePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTripPage()),
    );

    if (result == true) {
      _fetchTrips();
    }
  }

  Future<void> _goToDetailsPage(Map<String, dynamic> trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripDetailsPage(trip: trip)),
    );

    if (result == true) {
      _fetchTrips();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Liste mise à jour.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Mes voyages",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTrips,
            tooltip: "Rafraîchir",
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: dGreen))
          : _trips.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return _buildVoyageCard(trip);
              },
            ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: dGreen,
        onPressed: _goToCreatePage,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildVoyageCard(Map<String, dynamic> trip) {
    final String title = trip["trip_title"] ?? "Voyage sans titre";
    final String description = trip["trip_description"] ?? "Pas de description";
    final String? startDate = trip["start_date"];
    final bool isPrivate = trip["is_public_flag"] == "N";

    String? fullBannerUrl;
    final String? bannerPath = trip["banner"];

    if (bannerPath != null && bannerPath.isNotEmpty) {
      if (bannerPath.startsWith("http")) {
        fullBannerUrl = bannerPath;
      } else {
        final cleanPath = bannerPath.startsWith('/')
            ? bannerPath.substring(1)
            : bannerPath;
        fullBannerUrl = "${_apiClient.baseUrl}/$cleanPath";
      }
    }

    return GestureDetector(
      onTap: () => _goToDetailsPage(trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: (fullBannerUrl == null)
                    ? _buildFallbackImage()
                    : Image.network(
                        fullBannerUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print("❌ Erreur chargement image : $error");
                          return _buildFallbackImage();
                        },
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrivate)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.lock,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (startDate != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: dGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          startDate,
                          style: const TextStyle(
                            color: dGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      height: 150,
      width: double.infinity,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text(
            "Aucun voyage trouvé",
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Commencez par créer votre première aventure !",
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
