/** Point WGS84. */
export interface Coordonnee {
  latitude: number;
  longitude: number;
}

/**
 * Décode un tracé au format « Encoded Polyline » de Google (précision 1e-5),
 * tel que renvoyé par le backend dans `itinerairePolyline`.
 */
export function decoderPolyline(encode: string | null | undefined): Coordonnee[] {
  const points: Coordonnee[] = [];
  if (!encode) return points;
  let index = 0;
  let lat = 0;
  let lng = 0;
  const lire = (): number => {
    let resultat = 0;
    let decalage = 0;
    let octet: number;
    do {
      octet = encode.charCodeAt(index++) - 63;
      resultat |= (octet & 0x1f) << decalage;
      decalage += 5;
    } while (octet >= 0x20);
    return resultat & 1 ? ~(resultat >> 1) : resultat >> 1;
  };
  while (index < encode.length) {
    lat += lire();
    lng += lire();
    points.push({ latitude: lat / 1e5, longitude: lng / 1e5 });
  }
  return points;
}
