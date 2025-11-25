import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/services/trip_service.dart';

class TripDetailsPage extends StatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetailsPage({super.key, required this.trip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  final TripService _tripService = TripService();
  bool _isDeleting = false;

  // ---------------------------------------------------
  // FALLBACK IMAGE (identique à la liste)
  // ---------------------------------------------------
  Widget _buildFallbackImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [dGreen, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.flight_takeoff, color: Colors.black26, size: 80),
      ),
    );
  }

  // ---------------------------------------------
  // ACTION : Supprimer le voyage
  // ---------------------------------------------
  Future<void> _deleteTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Supprimer ?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Cette action est irréversible. Voulez-vous vraiment supprimer ce voyage ?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    final tripId = widget.trip['trip_id'];
    final success = await _tripService.deleteTrip(tripId);

    setState(() => _isDeleting = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la suppression")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.trip["trip_title"] ?? "Sans titre";
    final desc = widget.trip["trip_description"] ?? "";
    final startDate = widget.trip["start_date"];
    final endDate = widget.trip["end_date"];

    // Image potentielle
    final String? banner = widget.trip["banner"];
    String? imageUrl;

    if (banner != null && banner.isNotEmpty) {
      imageUrl = banner;
    }

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteTrip,
                ),
        ],
      ),
      extendBodyBehindAppBar: true,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------
            // IMAGE DE COUVERTURE AVEC FALLBACK
            // ---------------------------------------------------
            SizedBox(
              height: 250,
              width: double.infinity,
              child: (imageUrl == null)
                  ? _buildFallbackImage()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) {
                        print("❌ Erreur chargement image couverture : $error");
                        return _buildFallbackImage();
                      },
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                    ),
            ),

            // ---------------------------------------------------
            // CONTENU
            // ---------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne titre + crayon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Modifier le voyage (À implémenter)",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, color: dGreen),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Dates
                  if (startDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          endDate != null
                              ? "Du $startDate au $endDate"
                              : "Depuis le $startDate",
                          style: const TextStyle(
                            color: dGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),

                  // Description
                  if (desc.isNotEmpty) ...[
                    const Text(
                      "À propos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                  ] else
                    const Text(
                      "Aucune description fournie.",
                      style: TextStyle(
                        color: Colors.white24,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: dGreen,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ajouter un souvenir/post (À implémenter)"),
            ),
          );
        },
        icon: const Icon(Icons.add_a_photo, color: Colors.black),
        label: const Text(
          "Ajouter un souvenir",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
