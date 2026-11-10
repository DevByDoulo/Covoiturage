import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'formats.dart';

/// Point géographique simple (latitude, longitude en degrés).
typedef Coord = ({double latitude, double longitude});

/// À pied (passager qui rejoint le point de prise en charge) ou en voiture (conducteur).
enum ModeDeplacement { pied, voiture }

/// Une manœuvre à annoncer : où elle a lieu, quoi dire, longueur du tronçon qui suit.
class Etape {
  Etape(this.latitude, this.longitude, this.instruction, this.arrivee, this.distanceM);

  final double latitude;
  final double longitude;
  final String instruction;
  final bool arrivee;
  double distanceM;

  Coord get coord => (latitude: latitude, longitude: longitude);
}

class Itineraire {
  Itineraire(this.distanceM, this.dureeS, this.trace, this.etapes);

  final double distanceM;
  final double dureeS;
  final List<Coord> trace;

  /// Manœuvres dans l'ordre ; la première est le départ.
  final List<Etape> etapes;
}

/// 08 — Itinéraire détaillé (tracé + manœuvres en français) pour le guidage vocal, comme sur le site :
/// serveurs OSRM publics de l'association FOSSGIS (données OpenStreetMap, sans clé). Service gratuit sans
/// garantie : en production, prévoir un serveur OSRM à soi ou Google.
class ItineraireService {
  ItineraireService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _serveurs = {
    ModeDeplacement.pied: 'https://routing.openstreetmap.de/routed-foot/route/v1/driving',
    ModeDeplacement.voiture: 'https://routing.openstreetmap.de/routed-car/route/v1/driving',
  };

  Future<Itineraire> calculer(Coord depart, Coord arrivee, ModeDeplacement mode) async {
    final points = '${depart.longitude},${depart.latitude};${arrivee.longitude},${arrivee.latitude}';
    final r = await _client
        .get(Uri.parse('${_serveurs[mode]}/$points?overview=full&geometries=polyline&steps=true'))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('Service d\'itinéraire indisponible (${r.statusCode})');
    return lireReponseOsrm(jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  }
}

/// Lecture d'une réponse OSRM (séparée pour les tests).
Itineraire lireReponseOsrm(Map<String, dynamic> j) {
  final routes = j['routes'] as List?;
  if (j['code'] != 'Ok' || routes == null || routes.isEmpty) {
    throw Exception('Aucun itinéraire trouvé jusqu\'au point de rendez-vous.');
  }
  final route = routes.first as Map<String, dynamic>;
  final etapes = [
    for (final leg in route['legs'] as List) ...(leg['steps'] as List).cast<Map<String, dynamic>>(),
  ];
  return Itineraire(
    (route['distance'] as num).toDouble(),
    (route['duration'] as num).toDouble(),
    decoderPolyline(route['geometry'] as String).map((p) => (latitude: p.$1, longitude: p.$2)).toList(),
    etapesAnnoncees(etapes),
  );
}

/// Garde les manœuvres utiles (les sorties de rond-point sont dites à l'entrée ; leur tronçon s'ajoute au rond-point).
List<Etape> etapesAnnoncees(List<Map<String, dynamic>> etapes) {
  final resultat = <Etape>[];
  for (final e in etapes) {
    final m = e['maneuver'] as Map<String, dynamic>;
    final type = m['type'] as String;
    final distance = (e['distance'] as num).toDouble();
    if (type == 'exit roundabout' || type == 'exit rotary') {
      if (resultat.isNotEmpty) resultat.last.distanceM += distance;
      continue;
    }
    final loc = (m['location'] as List).cast<num>();
    resultat.add(Etape(loc[1].toDouble(), loc[0].toDouble(), instructionFr(e), type == 'arrive', distance));
  }
  return resultat;
}

const _directions = {
  'left': 'tournez à gauche',
  'right': 'tournez à droite',
  'slight left': 'serrez à gauche',
  'slight right': 'serrez à droite',
  'sharp left': 'tournez franchement à gauche',
  'sharp right': 'tournez franchement à droite',
  'straight': 'continuez tout droit',
  'uturn': 'faites demi-tour',
};

const _ordinaux = ['', 'première', 'deuxième', 'troisième', 'quatrième', 'cinquième', 'sixième'];

/// Phrase française d'une manœuvre OSRM, ex. « Tournez à gauche sur Rue 14 ».
String instructionFr(Map<String, dynamic> e) {
  final m = e['maneuver'] as Map<String, dynamic>;
  final type = m['type'] as String;
  final modifier = m['modifier'] as String?;
  final sortie = (m['exit'] as num?)?.toInt();
  final nom = (e['name'] as String?) ?? '';
  final sur = nom.isEmpty ? '' : ' sur $nom';
  final direction = _directions[modifier ?? 'straight'] ?? 'continuez';
  String phrase;
  switch (type) {
    case 'depart':
      phrase = 'Partez$sur';
    case 'arrive':
      return 'Vous êtes arrivé au point de rendez-vous';
    case 'roundabout':
    case 'rotary':
      phrase = sortie != null && sortie < _ordinaux.length
          ? 'Au rond-point, prenez la ${_ordinaux[sortie]} sortie$sur'
          : 'Au rond-point, continuez$sur';
    case 'fork':
      phrase = 'À l\'embranchement, ${(modifier ?? '').contains('left') ? 'restez à gauche' : 'restez à droite'}$sur';
    case 'end of road':
      phrase = 'Au bout de la route, $direction$sur';
    case 'new name':
    case 'continue':
      phrase = modifier == 'uturn' ? 'Faites demi-tour$sur' : 'Continuez$sur';
    default:
      phrase = '$direction$sur';
  }
  return phrase[0].toUpperCase() + phrase.substring(1);
}

// ------------------------------------------------------------------ Distances

const _rayonTerreM = 6371000.0;
double _rad(double d) => d * math.pi / 180;

/// Distance à vol d'oiseau en mètres.
double distanceM(Coord a, Coord b) {
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _rayonTerreM * math.asin(math.sqrt(h));
}

/// Distance en mètres entre un point et une ligne brisée (projection plane locale, suffisante en ville).
double distanceAuTraceM(Coord p, List<Coord> trace) {
  if (trace.isEmpty) return double.infinity;
  if (trace.length == 1) return distanceM(p, trace.first);
  final kx = _rayonTerreM * math.cos(_rad(p.latitude)) * math.pi / 180;
  const ky = _rayonTerreM * math.pi / 180;
  var min = double.infinity;
  for (var i = 1; i < trace.length; i++) {
    final ax = (trace[i - 1].longitude - p.longitude) * kx, ay = (trace[i - 1].latitude - p.latitude) * ky;
    final bx = (trace[i].longitude - p.longitude) * kx, by = (trace[i].latitude - p.latitude) * ky;
    final dx = bx - ax, dy = by - ay;
    final l2 = dx * dx + dy * dy;
    final t = l2 == 0 ? 0.0 : (-(ax * dx + ay * dy) / l2).clamp(0.0, 1.0);
    min = math.min(min, math.sqrt(math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2)));
  }
  return min;
}

/// « 350 mètres », « 1,2 kilomètre » : forme parlée d'une distance (arrondie pour l'oreille).
String distanceParlee(double m) {
  if (m < 1000) {
    final arrondi = m < 100 ? math.max(10, (m / 10).round() * 10) : (m / 50).round() * 50;
    return '$arrondi mètres';
  }
  final km = (m / 100).round() / 10;
  final texte = km == km.roundToDouble() ? km.toInt().toString() : km.toString().replaceAll('.', ',');
  return '$texte kilomètre${km >= 2 ? 's' : ''}';
}

/// « 860 m », « 2,7 km » : forme écrite courte.
String distanceAffichee(double m) =>
    m < 1000 ? '${math.max(10, (m / 10).round() * 10)} m' : '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
