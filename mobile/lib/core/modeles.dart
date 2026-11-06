/// Modèles alignés sur les DTO du backend (mêmes noms de champs que le site web, `frontend/src/app/**/*.models.ts`).
library;

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
DateTime _date(Object? v) => DateTime.parse(v as String);

class Profil {
  Profil({
    required this.id,
    required this.prenom,
    required this.nom,
    this.email,
    this.telephone,
    this.sexe,
    this.photoProfil,
    required this.role,
    required this.conducteurValide,
    this.noteMoyenne,
  });

  final int id;
  final String prenom;
  final String nom;
  final String? email;
  final String? telephone;
  final String? sexe;
  final String? photoProfil;
  final String role;
  final bool conducteurValide;
  final double? noteMoyenne;

  bool get estFemme => sexe == 'FEMME';
  String get nomComplet => '$prenom $nom';

  factory Profil.depuisJson(Map<String, dynamic> j) => Profil(
        id: _i(j['id']),
        prenom: j['prenom'] as String,
        nom: j['nom'] as String,
        email: j['email'] as String?,
        telephone: j['telephone'] as String?,
        sexe: j['sexe'] as String?,
        photoProfil: j['photoProfil'] as String?,
        role: j['role'] as String,
        conducteurValide: j['conducteurValide'] == true,
        noteMoyenne: (j['noteMoyenne'] as num?)?.toDouble(),
      );
}

/// Réponse de /api/auth/* : soit des jetons (CONNECTE), soit un code envoyé (OTP_ENVOYE).
class AuthReponse {
  AuthReponse({required this.etape, this.accessToken, this.refreshToken, this.canal, this.destination, this.utilisateur, this.renvoiDans});

  final String etape;
  final String? accessToken;
  final String? refreshToken;

  /// EMAIL ou SMS.
  final String? canal;

  /// Adresse ou numéro masqué où le code a été envoyé.
  final String? destination;
  final Profil? utilisateur;
  final int? renvoiDans;

  bool get connecte => etape == 'CONNECTE';

  factory AuthReponse.depuisJson(Map<String, dynamic> j) => AuthReponse(
        etape: j['etape'] as String,
        accessToken: j['accessToken'] as String?,
        refreshToken: j['refreshToken'] as String?,
        canal: j['canal'] as String?,
        destination: (j['emailMasque'] ?? j['telephoneMasque']) as String?,
        utilisateur: j['utilisateur'] == null ? null : Profil.depuisJson(j['utilisateur'] as Map<String, dynamic>),
        renvoiDans: (j['renvoiPossibleDansSecondes'] as num?)?.toInt(),
      );
}

class Point {
  Point(this.lieu, this.latitude, this.longitude);

  final String lieu;
  final double latitude;
  final double longitude;

  factory Point.depuisJson(Map<String, dynamic> j) => Point(j['lieu'] as String, _d(j['latitude']), _d(j['longitude']));

  Map<String, dynamic> versJson() => {'lieu': lieu, 'latitude': latitude, 'longitude': longitude};
}

class Personne {
  Personne({required this.id, required this.prenom, required this.nomInitiale, this.photoProfil, this.noteMoyenne});

  final int id;
  final String prenom;
  final String nomInitiale;
  final String? photoProfil;
  final double? noteMoyenne;

  factory Personne.depuisJson(Map<String, dynamic> j) => Personne(
        id: _i(j['id']),
        prenom: j['prenom'] as String,
        nomInitiale: j['nomInitiale'] as String,
        photoProfil: j['photoProfil'] as String?,
        noteMoyenne: (j['noteMoyenne'] as num?)?.toDouble(),
      );
}

/// Point où le conducteur prend et dépose le passager (résultats de recherche).
class Correspondance {
  Correspondance(this.distanceRamassageM, this.distanceDeposeM, this.ramassage, this.depose);

  final int distanceRamassageM;
  final int distanceDeposeM;
  final Point ramassage;
  final Point depose;

  factory Correspondance.depuisJson(Map<String, dynamic> j) => Correspondance(
        _i(j['distanceRamassageM']),
        _i(j['distanceDeposeM']),
        Point('Prise en charge', _d(j['latitudeRamassage']), _d(j['longitudeRamassage'])),
        Point('Dépose', _d(j['latitudeDepose']), _d(j['longitudeDepose'])),
      );
}

class Trajet {
  Trajet({
    required this.id,
    required this.conducteur,
    required this.vehicule,
    required this.depart,
    required this.arrivee,
    required this.escales,
    required this.dateHeureDepart,
    required this.flexibiliteMinutes,
    required this.nombrePlacesTotal,
    required this.nombrePlacesDisponibles,
    required this.modeReservation,
    required this.tailleBagage,
    required this.femmesUniquement,
    required this.distanceKm,
    required this.dureeEstimeeMin,
    required this.prixParPlace,
    required this.statut,
    this.motifAnnulation,
    this.itinerairePolyline,
    this.correspondance,
  });

  final int id;
  final Personne conducteur;
  final String vehicule;
  final Point depart;
  final Point arrivee;
  final List<Point> escales;
  final DateTime dateHeureDepart;
  final int flexibiliteMinutes;
  final int nombrePlacesTotal;
  final int nombrePlacesDisponibles;
  final String modeReservation;
  final String tailleBagage;
  final bool femmesUniquement;
  final double distanceKm;
  final int dureeEstimeeMin;
  final double prixParPlace;
  final String statut;
  final String? motifAnnulation;
  final String? itinerairePolyline;
  final Correspondance? correspondance;

  bool get reservable => statut == 'PUBLIE' && nombrePlacesDisponibles > 0;

  factory Trajet.depuisJson(Map<String, dynamic> j) {
    final v = j['vehicule'] as Map<String, dynamic>;
    return Trajet(
      id: _i(j['id']),
      conducteur: Personne.depuisJson(j['conducteur'] as Map<String, dynamic>),
      vehicule: '${v['marque']} ${v['modele']}${v['annee'] == null ? '' : ' (${v['annee']})'}',
      depart: Point.depuisJson(j['depart'] as Map<String, dynamic>),
      arrivee: Point.depuisJson(j['arrivee'] as Map<String, dynamic>),
      escales: ((j['escales'] as List?) ?? const []).map((e) => Point.depuisJson(e as Map<String, dynamic>)).toList(),
      dateHeureDepart: _date(j['dateHeureDepart']),
      flexibiliteMinutes: _i(j['flexibiliteMinutes']),
      nombrePlacesTotal: _i(j['nombrePlacesTotal']),
      nombrePlacesDisponibles: _i(j['nombrePlacesDisponibles']),
      modeReservation: j['modeReservation'] as String,
      tailleBagage: j['tailleBagage'] as String,
      femmesUniquement: j['femmesUniquement'] == true,
      distanceKm: _d(j['distanceKm']),
      dureeEstimeeMin: _i(j['dureeEstimeeMin']),
      prixParPlace: _d(j['prixParPlace']),
      statut: j['statut'] as String,
      motifAnnulation: j['motifAnnulation'] as String?,
      itinerairePolyline: j['itinerairePolyline'] as String?,
      correspondance:
          j['correspondance'] == null ? null : Correspondance.depuisJson(j['correspondance'] as Map<String, dynamic>),
    );
  }
}

class Reservation {
  Reservation({
    required this.id,
    required this.idTrajet,
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.dateHeureDepart,
    required this.conducteur,
    required this.nombrePlaces,
    required this.montantTotal,
    required this.statut,
    this.moyenPaiement,
    this.statutPaiement,
    required this.embarque,
    this.motifAnnulation,
  });

  final int id;
  final int idTrajet;
  final String lieuDepart;
  final String lieuArrivee;
  final DateTime dateHeureDepart;
  final Personne conducteur;
  final int nombrePlaces;
  final double montantTotal;
  final String statut;
  final String? moyenPaiement;
  final String? statutPaiement;
  final bool embarque;
  final String? motifAnnulation;

  bool get active => statut == 'EN_ATTENTE' || statut == 'ACCEPTEE';

  /// Paiement en ligne attendu : réservation acceptée, payée par Wave ou Orange Money, pas encore réglée.
  bool get aPayerEnLigne =>
      statut == 'ACCEPTEE' &&
      !embarque &&
      (moyenPaiement == 'WAVE' || moyenPaiement == 'ORANGE_MONEY') &&
      statutPaiement != 'REUSSI' &&
      statutPaiement != 'REMBOURSE' &&
      statutPaiement != 'REMBOURSEMENT_DEMANDE';

  factory Reservation.depuisJson(Map<String, dynamic> j) {
    final t = j['trajet'] as Map<String, dynamic>;
    return Reservation(
      id: _i(j['id']),
      idTrajet: _i(t['id']),
      lieuDepart: t['lieuDepart'] as String,
      lieuArrivee: t['lieuArrivee'] as String,
      dateHeureDepart: _date(t['dateHeureDepart']),
      conducteur: Personne.depuisJson(t['conducteur'] as Map<String, dynamic>),
      nombrePlaces: _i(j['nombrePlaces']),
      montantTotal: _d(j['montantTotal']),
      statut: j['statut'] as String,
      moyenPaiement: j['moyenPaiement'] as String?,
      statutPaiement: j['statutPaiement'] as String?,
      embarque: j['embarque'] == true,
      motifAnnulation: j['motifAnnulation'] as String?,
    );
  }
}

class CodeEmbarquement {
  CodeEmbarquement(this.codePin, this.qrContenu, this.montantAPayer, this.dateExpiration);

  final String codePin;
  final String qrContenu;
  final double montantAPayer;
  final DateTime dateExpiration;

  factory CodeEmbarquement.depuisJson(Map<String, dynamic> j) => CodeEmbarquement(
      j['codePin'] as String, j['qrContenu'] as String, _d(j['montantAPayer']), _date(j['dateExpiration']));
}

class NotificationApp {
  NotificationApp(this.id, this.type, this.titre, this.contenu, this.lien, this.lu, this.dateEnvoi);

  final int id;
  final String type;
  final String titre;
  final String contenu;
  final String? lien;
  bool lu;
  final DateTime dateEnvoi;

  factory NotificationApp.depuisJson(Map<String, dynamic> j) => NotificationApp(_i(j['id']), j['type'] as String,
      j['titre'] as String, j['contenu'] as String, j['lien'] as String?, j['lu'] == true, _date(j['dateEnvoi']));
}

/// Lieu choisi par l'utilisateur (recherche d'adresse, position actuelle).
class Lieu {
  Lieu(this.libelle, this.latitude, this.longitude, {this.detail});

  final String libelle;
  final String? detail;
  final double latitude;
  final double longitude;
}

const libellesStatutReservation = {
  'EN_ATTENTE': 'En attente',
  'ACCEPTEE': 'Confirmée',
  'REFUSEE': 'Refusée',
  'ANNULEE': 'Annulée',
  'TERMINEE': 'Terminée',
};

const libellesMoyen = {'ESPECES': 'Espèces', 'WAVE': 'Wave', 'ORANGE_MONEY': 'Orange Money'};

const libellesStatutPaiement = {
  'EN_ATTENTE': 'À payer',
  'REUSSI': 'Payé',
  'ECHOUE': 'Échoué',
  'REMBOURSEMENT_DEMANDE': 'Remboursement en cours',
  'REMBOURSE': 'Remboursé',
};
