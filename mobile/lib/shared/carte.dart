import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/formats.dart';
import '../core/theme.dart';

/// Marqueur sur la carte : départ (A, vert), arrivée (B, rouge), escale (orange), point de prise en charge (bleu).
class Repere {
  Repere(this.latitude, this.longitude, this.type, {this.etiquette = ''});

  final double latitude;
  final double longitude;
  final String type;
  final String etiquette;

  LatLng get point => LatLng(latitude, longitude);

  Color get couleur => switch (type) {
        'depart' => Couleurs.vert,
        'arrivee' => Couleurs.erreur,
        'escale' => Couleurs.orange,
        _ => const Color(0xFF2563EB),
      };
}

/// Carte OpenStreetMap (sans clé), centrée sur les repères et le tracé.
class Carte extends StatelessWidget {
  const Carte({super.key, this.reperes = const [], this.polyline, this.hauteur = 220, this.surTouche});

  final List<Repere> reperes;
  final String? polyline;
  final double hauteur;

  /// Toucher la carte place un point (ex. le départ).
  final void Function(double latitude, double longitude)? surTouche;

  static const _dakar = LatLng(14.6928, -17.4467);

  @override
  Widget build(BuildContext context) {
    final trace = decoderPolyline(polyline).map((p) => LatLng(p.$1, p.$2)).toList();
    final points = [...reperes.map((r) => r.point), ...trace];
    final cadrage = points.length >= 2
        ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(36), maxZoom: 15)
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: hauteur,
        child: FlutterMap(
          // La clé force le recadrage quand les repères changent.
          key: ValueKey(Object.hashAll([...points.map((p) => p.latitude), polyline])),
          options: MapOptions(
            initialCameraFit: cadrage,
            initialCenter: points.isEmpty ? _dakar : points.first,
            initialZoom: points.isEmpty ? 11 : 13,
            onTap: surTouche == null ? null : (_, p) => surTouche!(p.latitude, p.longitude),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'sn.isep.yobalema',
            ),
            if (trace.length >= 2)
              PolylineLayer(polylines: [Polyline(points: trace, strokeWidth: 4.5, color: Couleurs.vert)]),
            MarkerLayer(
              markers: [
                for (final r in reperes)
                  Marker(
                    point: r.point,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: r.couleur,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      alignment: Alignment.center,
                      child: Text(r.etiquette,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(source: Text('OpenStreetMap')),
          ],
        ),
      ),
    );
  }
}
