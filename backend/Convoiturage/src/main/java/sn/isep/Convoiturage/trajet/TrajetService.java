package sn.isep.Convoiturage.trajet;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.common.geo.Coordonnee;
import sn.isep.Convoiturage.common.geo.GeoUtils;
import sn.isep.Convoiturage.tarification.MoteurTarification;
import sn.isep.Convoiturage.tarification.MoteurTarification.DemandeEstimation;
import sn.isep.Convoiturage.tarification.MoteurTarification.EstimationPrix;
import sn.isep.Convoiturage.tarification.Tarification;
import sn.isep.Convoiturage.trajet.TrajetDtos.*;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetAnnule;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetModifie;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetTermine;
import sn.isep.Convoiturage.trajet.itineraire.ItineraireService;
import sn.isep.Convoiturage.trajet.itineraire.ItineraireService.Itineraire;
import sn.isep.Convoiturage.utilisateur.Sexe;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;
import sn.isep.Convoiturage.vehicule.Vehicule;
import sn.isep.Convoiturage.vehicule.VehiculeRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TrajetService {

    private static final int DELAI_MIN_PUBLICATION_MIN = 30;
    private static final DateTimeFormatter FORMAT_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy 'à' HH'h'mm");

    private final TrajetRepository trajets;
    private final VehiculeRepository vehicules;
    private final UtilisateurRepository utilisateurs;
    private final ItineraireService itineraires;
    private final MoteurTarification moteur;
    private final ApplicationEventPublisher evenements;

    record Calcul(Itineraire itineraire, EstimationPrix tarif) {}

    // ------------------------------------------------------------------ Estimation / publication

    /** Calcule itinéraire + prix proposé, sans rien enregistrer (écran « Publier un trajet »). */
    @Transactional(readOnly = true)
    public EstimationReponse estimer(Long conducteurId, EstimationRequete req) {
        Vehicule v = vehicules.findByIdAndProprietaireId(req.idVehicule(), conducteurId)
                .filter(Vehicule::isActif)
                .orElseThrow(() -> ApiException.notFound("Véhicule introuvable"));
        Calcul c = calculer(v, req.depart(), req.escales(), req.arrivee(), req.dateHeureDepart(), req.nombrePlaces());
        return EstimationReponse.de(c.itineraire(), c.tarif());
    }

    @Transactional
    public TrajetDto publier(Long conducteurId, PublicationRequete req) {
        Utilisateur conducteur = utilisateurs.findById(conducteurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (!conducteur.estActif()) throw ApiException.forbidden("Votre compte ne permet pas de publier de trajet");
        if (!conducteur.isConducteurValide()) {
            throw ApiException.forbidden("Votre permis et la carte grise de votre véhicule doivent être validés par un administrateur avant de publier un trajet");
        }
        Vehicule v = vehicules.findByIdAndProprietaireId(req.idVehicule(), conducteurId)
                .filter(Vehicule::isActif)
                .orElseThrow(() -> ApiException.notFound("Véhicule introuvable"));
        if (!v.estUtilisable()) throw ApiException.badRequest("Ce véhicule n'a pas encore été validé par un administrateur");
        if (req.femmesUniquement() && conducteur.getSexe() != Sexe.FEMME) {
            throw ApiException.badRequest("L'option « femmes uniquement » est réservée aux conductrices");
        }
        if (req.dateHeureDepart().isBefore(LocalDateTime.now().plusMinutes(DELAI_MIN_PUBLICATION_MIN))) {
            throw ApiException.badRequest("Le départ doit avoir lieu au moins " + DELAI_MIN_PUBLICATION_MIN + " minutes après la publication");
        }

        Calcul c = calculer(v, req.depart(), req.escales(), req.arrivee(), req.dateHeureDepart(), req.nombrePlaces());
        Itineraire it = c.itineraire();

        Trajet t = new Trajet();
        t.setConducteur(conducteur);
        t.setVehicule(v);
        t.setLieuDepart(req.depart().lieu().trim());
        t.setLatitudeDepart(req.depart().latitude());
        t.setLongitudeDepart(req.depart().longitude());
        t.setLieuArrivee(req.arrivee().lieu().trim());
        t.setLatitudeArrivee(req.arrivee().latitude());
        t.setLongitudeArrivee(req.arrivee().longitude());
        t.setDateHeureDepart(req.dateHeureDepart());
        t.setFlexibiliteMinutes(req.flexibiliteMinutes());
        t.setNombrePlacesTotal(req.nombrePlaces());
        t.setNombrePlacesDisponibles(req.nombrePlaces());
        t.setModeReservation(req.modeReservation());
        t.setTailleBagage(req.tailleBagage());
        t.setFemmesUniquement(req.femmesUniquement());
        t.setDistanceKm(BigDecimal.valueOf(it.distanceKm()).setScale(2, RoundingMode.HALF_UP));
        t.setDureeEstimeeMin(it.dureeMin());
        t.setTypeRoute(it.typeRoute());
        t.setDeniveleM(it.deniveleM());
        t.setMontantPeages(it.montantPeages());
        t.setItineraire(GeoUtils.lineString(it.trace()));
        List<PointDto> escales = req.escales() == null ? List.of() : req.escales();
        for (int i = 0; i < escales.size(); i++) {
            Escale e = new Escale();
            e.setOrdre(i + 1);
            e.setLieu(escales.get(i).lieu().trim());
            e.setLatitude(escales.get(i).latitude());
            e.setLongitude(escales.get(i).longitude());
            t.ajouterEscale(e);
        }

        EstimationPrix prix = c.tarif();
        Tarification tf = new Tarification();
        tf.setTrajet(t);
        tf.setPrixIa(prix.prixRecommande());
        tf.setPrixMin(prix.prixMin());
        tf.setPrixMax(prix.prixMax());
        tf.setPrixFinal(prix.prixRecommande());
        tf.setPrixCarburantUtilise(prix.prixCarburantUtilise());
        tf.setHeureDePointe(prix.heureDePointe());
        tf.setVersionModele(prix.versionModele());
        if (req.prixParPlace() != null) tf.ajusterPrix(req.prixParPlace().setScale(2, RoundingMode.HALF_UP));
        t.setTarification(tf);

        trajets.save(t);
        evenements.publishEvent(new TrajetEvenements.TrajetPublie(t.getId()));
        return TrajetDto.de(t, true, null);
    }

    private Calcul calculer(Vehicule v, PointDto depart, List<PointDto> escales, PointDto arrivee,
                            LocalDateTime dateDepart, int nombrePlaces) {
        if (nombrePlaces > v.getNombrePlaces() - 1) {
            throw ApiException.badRequest("Ce véhicule permet de proposer au maximum " + (v.getNombrePlaces() - 1) + " place(s)");
        }
        List<Coordonnee> points = new ArrayList<>();
        points.add(depart.coordonnee());
        if (escales != null) escales.forEach(e -> points.add(e.coordonnee()));
        points.add(arrivee.coordonnee());
        if (GeoUtils.distanceKm(points.getFirst(), points.getLast()) < 1) {
            throw ApiException.badRequest("Le départ et l'arrivée sont trop proches");
        }
        Itineraire it = itineraires.calculer(points);
        // Moteur IA (consommation prédite + météo au départ) avec repli sur la formule : voir TarificationConfig.
        EstimationPrix prix = moteur.estimer(new DemandeEstimation(
                v.getMarque(), v.getTypeEnergie(), v.getPuissanceFiscale(), v.getAnnee() == null ? 0 : v.getAnnee(),
                v.getConsommationTheorique(), v.getConsommationReelle(), v.getAmortissementParKm(),
                it.distanceKm(), it.deniveleM(), it.typeRoute(), it.montantPeages(),
                nombrePlaces, dateDepart, depart.latitude(), depart.longitude()));
        return new Calcul(it, prix);
    }

    // ------------------------------------------------------------------ Cycle de vie (conducteur)

    @Transactional
    public TrajetDto modifier(Long conducteurId, Long trajetId, ModificationTrajetRequete req) {
        Trajet t = chargerPourConducteur(trajetId, conducteurId);
        if (!t.estModifiable()) throw ApiException.conflict("Ce trajet ne peut plus être modifié");
        List<String> changements = new ArrayList<>();

        if (req.dateHeureDepart() != null && !req.dateHeureDepart().equals(t.getDateHeureDepart())) {
            if (req.dateHeureDepart().isBefore(LocalDateTime.now().plusMinutes(DELAI_MIN_PUBLICATION_MIN))) {
                throw ApiException.badRequest("Le départ doit avoir lieu au moins " + DELAI_MIN_PUBLICATION_MIN + " minutes plus tard");
            }
            t.setDateHeureDepart(req.dateHeureDepart());
            changements.add("nouveau départ le " + FORMAT_DATE.format(req.dateHeureDepart()));
        }
        if (req.flexibiliteMinutes() != null && !req.flexibiliteMinutes().equals(t.getFlexibiliteMinutes())) {
            t.setFlexibiliteMinutes(req.flexibiliteMinutes());
            changements.add("flexibilité de " + req.flexibiliteMinutes() + " min");
        }
        if (req.nombrePlaces() != null && !req.nombrePlaces().equals(t.getNombrePlacesTotal())) {
            int reservees = t.getNombrePlacesTotal() - t.getNombrePlacesDisponibles();
            if (req.nombrePlaces() < reservees) {
                throw ApiException.conflict(reservees + " place(s) sont déjà réservées sur ce trajet");
            }
            if (req.nombrePlaces() > t.getVehicule().getNombrePlaces() - 1) {
                throw ApiException.badRequest("Ce véhicule permet de proposer au maximum " + (t.getVehicule().getNombrePlaces() - 1) + " place(s)");
            }
            t.setNombrePlacesTotal(req.nombrePlaces());
            t.setNombrePlacesDisponibles(req.nombrePlaces() - reservees);
            t.setStatut(t.getNombrePlacesDisponibles() == 0 ? StatutTrajet.COMPLET : StatutTrajet.PUBLIE);
        }
        if (req.modeReservation() != null) t.setModeReservation(req.modeReservation());
        if (req.tailleBagage() != null && req.tailleBagage() != t.getTailleBagage()) {
            t.setTailleBagage(req.tailleBagage());
            changements.add("bagages acceptés : " + req.tailleBagage().name().toLowerCase());
        }
        if (req.prixParPlace() != null && req.prixParPlace().compareTo(t.getTarification().getPrixFinal()) != 0) {
            // Les réservations existantes conservent le prix auquel elles ont été faites.
            t.getTarification().ajusterPrix(req.prixParPlace().setScale(2, RoundingMode.HALF_UP));
        }
        if (!changements.isEmpty()) {
            evenements.publishEvent(new TrajetModifie(t.getId(), String.join(", ", changements)));
        }
        return TrajetDto.de(t, true, null);
    }

    @Transactional
    public TrajetDto annuler(Long conducteurId, Long trajetId, String motif) {
        Trajet t = chargerPourConducteur(trajetId, conducteurId);
        if (t.getStatut() != StatutTrajet.PUBLIE && t.getStatut() != StatutTrajet.COMPLET) {
            throw ApiException.conflict("Ce trajet ne peut plus être annulé");
        }
        t.setStatut(StatutTrajet.ANNULE);
        t.setMotifAnnulation(motif);
        evenements.publishEvent(new TrajetAnnule(t.getId(), motif));
        return TrajetDto.de(t, true, null);
    }

    @Transactional
    public TrajetDto demarrer(Long conducteurId, Long trajetId) {
        Trajet t = chargerPourConducteur(trajetId, conducteurId);
        if (t.getStatut() != StatutTrajet.PUBLIE && t.getStatut() != StatutTrajet.COMPLET) {
            throw ApiException.conflict("Ce trajet ne peut pas être démarré");
        }
        if (LocalDateTime.now().isBefore(t.getDateHeureDepart().minusMinutes(60))) {
            throw ApiException.conflict("Le trajet ne peut être démarré qu'à partir d'une heure avant le départ");
        }
        t.setStatut(StatutTrajet.EN_COURS);
        return TrajetDto.de(t, true, null);
    }

    @Transactional
    public TrajetDto terminer(Long conducteurId, Long trajetId) {
        Trajet t = chargerPourConducteur(trajetId, conducteurId);
        if (t.getStatut() != StatutTrajet.EN_COURS) throw ApiException.conflict("Seul un trajet en cours peut être terminé");
        t.setStatut(StatutTrajet.TERMINE);
        evenements.publishEvent(new TrajetTermine(t.getId()));
        return TrajetDto.de(t, true, null);
    }

    // ------------------------------------------------------------------ Consultation

    @Transactional(readOnly = true)
    public List<TrajetDto> mesTrajets(Long conducteurId) {
        return trajets.findByConducteurIdOrderByDateHeureDepartDesc(conducteurId).stream()
                .map(t -> TrajetDto.de(t, true, null)).toList();
    }

    @Transactional(readOnly = true)
    public TrajetDto detail(Long trajetId) {
        Trajet t = trajets.findById(trajetId).orElseThrow(() -> ApiException.notFound("Trajet introuvable"));
        boolean vueConducteur = SecurityUtils.utilisateurCourantIdOptionnel()
                .map(id -> id.equals(t.getConducteur().getId())).orElse(false);
        return TrajetDto.de(t, vueConducteur, null);
    }

    public record CriteresRecherche(double latDepart, double lngDepart, double latArrivee, double lngArrivee,
                                    java.time.LocalDate date, java.time.LocalTime heureMin, java.time.LocalTime heureMax,
                                    int places, double rayonKm, BigDecimal prixMax, BigDecimal noteMin,
                                    boolean femmesUniquement, String conducteur) {}

    @Transactional(readOnly = true)
    public List<TrajetDto> rechercher(CriteresRecherche c) {
        if (c.places() < 1 || c.places() > 8) throw ApiException.badRequest("Nombre de places invalide");
        if (c.rayonKm() <= 0 || c.rayonKm() > 30) throw ApiException.badRequest("Le rayon doit être compris entre 0 et 30 km");
        LocalDateTime debut = c.date().atTime(c.heureMin() != null ? c.heureMin() : java.time.LocalTime.MIN);
        LocalDateTime fin = c.heureMax() != null ? c.date().atTime(c.heureMax()) : c.date().plusDays(1).atStartOfDay();
        String motifConducteur = c.conducteur() == null || c.conducteur().isBlank()
                ? null : "%" + c.conducteur().trim().toLowerCase() + "%";
        long exclure = SecurityUtils.utilisateurCourantIdOptionnel().orElse(-1L);

        List<TrajetRepository.ResultatRecherche> resultats = trajets.rechercher(
                c.latDepart(), c.lngDepart(), c.latArrivee(), c.lngArrivee(), c.rayonKm() * 1000, c.places(),
                LocalDateTime.now(), debut, fin, c.prixMax(), c.noteMin(), c.femmesUniquement(), motifConducteur, exclure);
        if (resultats.isEmpty()) return List.of();

        Map<Long, Trajet> parId = trajets.findByIdIn(resultats.stream().map(TrajetRepository.ResultatRecherche::getIdTrajet).toList())
                .stream().collect(Collectors.toMap(Trajet::getId, Function.identity()));
        return resultats.stream()
                .filter(r -> parId.containsKey(r.getIdTrajet()))
                .map(r -> TrajetDto.de(parId.get(r.getIdTrajet()), false, new CorrespondanceDto(
                        (int) Math.round(r.getDistanceDepartM()), (int) Math.round(r.getDistanceArriveeM()),
                        r.getLatRamassage(), r.getLngRamassage(), r.getLatDepose(), r.getLngDepose())))
                .toList();
    }

    private Trajet chargerPourConducteur(Long trajetId, Long conducteurId) {
        Trajet t = trajets.findByIdForUpdate(trajetId).orElseThrow(() -> ApiException.notFound("Trajet introuvable"));
        if (!t.getConducteur().getId().equals(conducteurId)) throw ApiException.forbidden("Ce trajet ne vous appartient pas");
        return t;
    }
}
