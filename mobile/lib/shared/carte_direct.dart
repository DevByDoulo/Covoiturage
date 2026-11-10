import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/itineraire.dart';
import '../core/theme.dart';
import 'carte.dart';

/// Carte « en direct » (guidage, suivi du conducteur) : elle suit le point [suivre] (vous, ou la voiture) sans se
/// reconstruire à chaque position, contrairement à [Carte] qui se recadre quand ses repères changent.
/// Repères spéciaux : type `moi` (point bleu) et `voiture` (pastille orange).
class CarteDirect extends StatefulWidget {
  const CarteDirect({super.key, this.reperes = const [], this.trace = const [], this.suivre, this.hauteur = 320});

  final List<Repere> reperes;
  final List<Coord> trace;
  final Coord? suivre;
  final double hauteur;

  @override
  State<CarteDirect> createState() => _CarteDirectState();
}

class _CarteDirectState extends State<CarteDirect> {
  final _controleur = MapController();
  bool _prete = false;

  static const _dakar = LatLng(14.6928, -17.4467);

  LatLng? get _suivi => widget.suivre == null ? null : LatLng(widget.suivre!.latitude, widget.suivre!.longitude);

  @override
  void didUpdateWidget(CarteDirect ancien) {
    super.didUpdateWidget(ancien);
    final p = _suivi;
    if (_prete && p != null && widget.suivre != ancien.suivre) {
      _controleur.move(p, _controleur.camera.zoom < 15 ? 16 : _controleur.camera.zoom);
    }
  }

  void _recentrer() {
    final p = _suivi;
    if (p != null) _controleur.move(p, 17);
  }

  @override
  Widget build(BuildContext context) {
    final points = [...widget.reperes.map((r) => r.point), ...widget.trace.map((c) => LatLng(c.latitude, c.longitude))];
    final depart = _suivi;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.hauteur,
        child: Stack(children: [
          FlutterMap(
            mapController: _controleur,
            options: MapOptions(
              initialCenter: depart ?? (points.isEmpty ? _dakar : points.first),
              initialZoom: depart != null ? 17 : 13,
              initialCameraFit: depart == null && points.length >= 2
                  ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(40), maxZoom: 16)
                  : null,
              onMapReady: () => _prete = true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'sn.isep.yobalema',
              ),
              if (widget.trace.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(
                    points: widget.trace.map((c) => LatLng(c.latitude, c.longitude)).toList(),
                    strokeWidth: 6,
                    color: Couleurs.vert.withValues(alpha: 0.85),
                  ),
                ]),
              MarkerLayer(markers: [for (final r in widget.reperes) _marqueur(r)]),
              const SimpleAttributionWidget(source: Text('OpenStreetMap')),
            ],
          ),
          if (depart != null)
            Positioned(
              right: 10,
              top: 10,
              child: FloatingActionButton.small(
                heroTag: null,
                tooltip: 'Recentrer',
                backgroundColor: Colors.white,
                foregroundColor: Couleurs.vert,
                onPressed: _recentrer,
                child: const Icon(Icons.my_location),
              ),
            ),
        ]),
      ),
    );
  }

  Marker _marqueur(Repere r) => switch (r.type) {
        'moi' => Marker(
            point: r.point,
            width: 34,
            height: 34,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: const Color(0xFF1A73E8).withValues(alpha: 0.3), blurRadius: 0, spreadRadius: 7)],
              ),
            ),
          ),
        'voiture' => Marker(
            point: r.point,
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Couleurs.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
            ),
          ),
        _ => Marker(
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
              child: Text(r.etiquette, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
      };
}
