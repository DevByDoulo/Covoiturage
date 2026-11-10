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
    this.bio,
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

  /// Présentation libre (500 caractères au plus), modifiable dans « Modifier mon profil ».
  final String? bio;
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
        bio: j['bio'] as String?,
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
    this.passager,
    this.pointRamassage,
    this.statutTrajet,
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

  /// Côté conducteur (réservations d'un trajet).
  final Personne? passager;
  final String? pointRamassage;

  /// Statut du trajet (PUBLIE, COMPLET, EN_COURS…).
  final String? statutTrajet;

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
      passager: j['passager'] == null ? null : Personne.depuisJson(j['passager'] as Map<String, dynamic>),
      pointRamassage: j['pointRamassage'] as String?,
      statutTrajet: t['statut'] as String?,
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

/// Véhicule du conducteur (GET /api/moi/vehicules) ; seuls les véhicules validés servent à publier.
class Vehicule {
  Vehicule(this.id, this.libelle, this.immatriculation, this.nombrePlaces, this.statutValidation);

  final int id;
  final String libelle;
  final String immatriculation;
  final int nombrePlaces;
  final String statutValidation;

  bool get valide => statutValidation == 'VALIDE';

  factory Vehicule.depuisJson(Map<String, dynamic> j) => Vehicule(
        _i(j['id']),
        '${j['marque']} ${j['modele']}${j['annee'] == null ? '' : ' (${j['annee']})'}',
        (j['immatriculation'] as String?) ?? '',
        _i(j['nombrePlaces']),
        j['statutValidation'] as String,
      );
}

/// Réponse de POST /api/trajets/estimation : itinéraire et prix proposé (IA + formule).
class Estimation {
  Estimation({
    required this.distanceKm,
    required this.dureeEstimeeMin,
    required this.montantPeages,
    required this.sourceItineraire,
    this.itinerairePolyline,
    required this.prixRecommande,
    required this.prixMin,
    required this.prixMax,
    required this.coutCarburant,
    required this.coutUsure,
    required this.coutPeages,
    required this.facteurMeteo,
    required this.sourceConsommation,
    required this.heureDePointe,
  });

  final double distanceKm;
  final int dureeEstimeeMin;
  final double montantPeages;
  final String sourceItineraire;
  final String? itinerairePolyline;
  final double prixRecommande;
  final double prixMin;
  final double prixMax;
  final double coutCarburant;
  final double coutUsure;
  final double coutPeages;
  final double facteurMeteo;
  final String sourceConsommation;
  final bool heureDePointe;

  factory Estimation.depuisJson(Map<String, dynamic> j) {
    final t = j['tarif'] as Map<String, dynamic>;
    return Estimation(
      distanceKm: _d(j['distanceKm']),
      dureeEstimeeMin: _i(j['dureeEstimeeMin']),
      montantPeages: _d(j['montantPeages']),
      sourceItineraire: (j['sourceItineraire'] as String?) ?? '',
      itinerairePolyline: j['itinerairePolyline'] as String?,
      prixRecommande: _d(t['prixRecommande']),
      prixMin: _d(t['prixMin']),
      prixMax: _d(t['prixMax']),
      coutCarburant: _d(t['coutCarburant']),
      coutUsure: _d(t['coutUsure']),
      coutPeages: _d(t['coutPeages']),
      facteurMeteo: (t['facteurMeteo'] as num?)?.toDouble() ?? 1,
      sourceConsommation: (t['sourceConsommation'] as String?) ?? '',
      heureDePointe: t['heureDePointe'] == true,
    );
  }
}

/// Réponse au conducteur après validation d'un code : qui monte et combien encaisser.
class EmbarquementConfirme {
  EmbarquementConfirme(this.passager, this.nombrePlaces, this.montantAEncaisser, this.moyenPaiement);

  final Personne passager;
  final int nombrePlaces;
  final double montantAEncaisser;
  final String? moyenPaiement;

  factory EmbarquementConfirme.depuisJson(Map<String, dynamic> j) => EmbarquementConfirme(
      Personne.depuisJson(j['passager'] as Map<String, dynamic>),
      _i(j['nombrePlaces']),
      _d(j['montantAEncaisser']),
      j['moyenPaiement'] as String?);
}

/// Trajet rappelé en tête d'une conversation.
class TrajetConversation {
  TrajetConversation(this.id, this.lieuDepart, this.lieuArrivee, this.dateHeureDepart, this.statut);

  final int id;
  final String lieuDepart;
  final String lieuArrivee;
  final DateTime dateHeureDepart;
  final String statut;

  factory TrajetConversation.depuisJson(Map<String, dynamic> j) => TrajetConversation(_i(j['id']),
      j['lieuDepart'] as String, j['lieuArrivee'] as String, _date(j['dateHeureDepart']), j['statut'] as String);
}

/// Ligne de la liste des conversations (GET /api/moi/conversations).
class ConversationResume {
  ConversationResume(this.id, this.trajet, this.interlocuteur, this.jeSuisConducteur, this.dernierMessage,
      this.dernierDeMoi, this.dateDernierMessage, this.nonLus);

  final int id;
  final TrajetConversation trajet;
  final Personne interlocuteur;
  final bool jeSuisConducteur;
  final String? dernierMessage;
  final bool dernierDeMoi;
  final DateTime? dateDernierMessage;
  final int nonLus;

  factory ConversationResume.depuisJson(Map<String, dynamic> j) => ConversationResume(
        _i(j['id']),
        TrajetConversation.depuisJson(j['trajet'] as Map<String, dynamic>),
        Personne.depuisJson(j['interlocuteur'] as Map<String, dynamic>),
        j['jeSuisConducteur'] == true,
        j['dernierMessage'] as String?,
        j['dernierDeMoi'] == true,
        j['dateDernierMessage'] == null ? null : _date(j['dateDernierMessage']),
        _i(j['nonLus']),
      );
}

class MessageApp {
  MessageApp(this.id, this.contenu, this.dateEnvoi, this.deMoi, this.lu);

  final int id;
  final String contenu;
  final DateTime dateEnvoi;
  final bool deMoi;
  final bool lu;

  factory MessageApp.depuisJson(Map<String, dynamic> j) =>
      MessageApp(_i(j['id']), j['contenu'] as String, _date(j['dateEnvoi']), j['deMoi'] == true, j['lu'] == true);
}

/// Conversation ouverte (GET /api/moi/conversations/{id}, qui marque les messages reçus comme lus).
/// [fermeture] : raison pour laquelle on ne peut plus écrire (null si la conversation est ouverte).
class ConversationDetail {
  ConversationDetail(this.id, this.trajet, this.interlocuteur, this.jeSuisConducteur, this.fermeture, this.messages);

  final int id;
  final TrajetConversation trajet;
  final Personne interlocuteur;
  final bool jeSuisConducteur;
  final String? fermeture;
  final List<MessageApp> messages;

  factory ConversationDetail.depuisJson(Map<String, dynamic> j) => ConversationDetail(
        _i(j['id']),
        TrajetConversation.depuisJson(j['trajet'] as Map<String, dynamic>),
        Personne.depuisJson(j['interlocuteur'] as Map<String, dynamic>),
        j['jeSuisConducteur'] == true,
        j['fermeture'] as String?,
        ((j['messages'] as List?) ?? const []).map((e) => MessageApp.depuisJson(e as Map<String, dynamic>)).toList(),
      );
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

const libellesStatutTrajet = {
  'PUBLIE': 'Publié',
  'COMPLET': 'Complet',
  'EN_COURS': 'En cours',
  'TERMINE': 'Terminé',
  'ANNULE': 'Annulé',
};

const libellesBagage = {'PETIT': 'Petit', 'MOYEN': 'Moyen', 'GRAND': 'Grand'};
