import 'package:intl/intl.dart';

final _fcfa = NumberFormat.decimalPattern('fr_FR');

/// 1650 → « 1 650 FCFA ».
String fcfa(num? montant) => montant == null ? '—' : '${_fcfa.format(montant.round())} FCFA';

/// 75 → « 1 h 15 ».
String duree(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

/// « vendredi 6 novembre à 08h00 ».
String dateHeure(DateTime d) => DateFormat("EEEE d MMMM 'à' HH'h'mm", 'fr_FR').format(d);

/// « 06/11 08h00 ».
String dateCourte(DateTime d) => DateFormat("dd/MM HH'h'mm", 'fr_FR').format(d);

/// 1300 → « 1,3 km » ; 450 → « 450 m ».
String distance(int metres) =>
    metres < 1000 ? '$metres m' : '${(metres / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

/// Date au format de l'API : « 2026-11-06 ».
String dateApi(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Décode un tracé « encoded polyline » (Google, précision 5) en couples latitude/longitude.
List<(double, double)> decoderPolyline(String? encode) {
  if (encode == null || encode.isEmpty) return const [];
  final points = <(double, double)>[];
  var index = 0, lat = 0, lng = 0;
  int valeur() {
    var resultat = 0, decalage = 0, b = 0;
    do {
      b = encode.codeUnitAt(index++) - 63;
      resultat |= (b & 0x1f) << decalage;
      decalage += 5;
    } while (b >= 0x20);
    // Pas de « ~ » : sur le web, les opérations bit à bit de Dart donnent des entiers non signés (longitudes fausses).
    return (resultat & 1) != 0 ? -(resultat >> 1) - 1 : resultat >> 1;
  }

  while (index < encode.length) {
    lat += valeur();
    lng += valeur();
    points.add((lat / 1e5, lng / 1e5));
  }
  return points;
}
