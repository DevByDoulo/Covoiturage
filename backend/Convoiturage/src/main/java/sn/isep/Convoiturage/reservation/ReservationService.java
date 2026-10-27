package sn.isep.Convoiturage.reservation;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.reservation.ReservationDtos.*;
import sn.isep.Convoiturage.reservation.ReservationEvenements.*;
import sn.isep.Convoiturage.trajet.Escale;
import sn.isep.Convoiturage.trajet.ModeReservation;
import sn.isep.Convoiturage.trajet.StatutTrajet;
import sn.isep.Convoiturage.trajet.Trajet;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetAnnule;
import sn.isep.Convoiturage.trajet.TrajetEvenements.TrajetTermine;
import sn.isep.Convoiturage.trajet.TrajetRepository;
import sn.isep.Convoiturage.utilisateur.Sexe;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurDtos.UtilisateurResume;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Réservations : demande, acceptation/refus (mode manuel), annulation, embarquement par PIN/QR.
 * Le paiement est créé dès la demande avec le moyen choisi (espèces, Wave, Orange Money) ; le module
 * facturation gère ensuite le paiement mobile et les remboursements à partir des événements publiés ici.
 */
@Service
@RequiredArgsConstructor
public class ReservationService {

    static final String PREFIXE_QR = "covoitia:embarquement:";
    private static final Set<StatutReservation> ACTIVES = EnumSet.of(StatutReservation.EN_ATTENTE, StatutReservation.ACCEPTEE);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final ReservationRepository reservations;
    private final PaiementRepository paiements;
    private final ConfirmationEmbarquementRepository confirmations;
    private final TrajetRepository trajets;
    private final UtilisateurRepository utilisateurs;
    private final MoyensPaiement moyensPaiement;
    private final ApplicationEventPublisher evenements;

    // ------------------------------------------------------------------ Passager

    @Transactional
    public ReservationDto reserver(Long passagerId, Long trajetId, ReservationRequete req) {
        MoyenPaiement moyen = req.moyenPaiement() == null ? MoyenPaiement.ESPECES : req.moyenPaiement();
        if (!moyensPaiement.disponible(moyen)) {
            throw ApiException.badRequest("Le paiement par " + libelle(moyen) + " n'est pas disponible pour le moment")
                    .surChamp("moyenPaiement");
        }
        Utilisateur passager = utilisateurs.findById(passagerId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        if (!passager.estActif()) throw ApiException.forbidden("Votre compte ne permet pas de réserver");

        Trajet trajet = trajets.findByIdForUpdate(trajetId).orElseThrow(() -> ApiException.notFound("Trajet introuvable"));
        if (!trajet.estOuvertALaReservation()) throw ApiException.conflict("Ce trajet n'est plus ouvert à la réservation");
        if (trajet.getConducteur().getId().equals(passagerId)) {
            throw ApiException.badRequest("Vous ne pouvez pas réserver votre propre trajet");
        }
        if (trajet.isFemmesUniquement() && passager.getSexe() != Sexe.FEMME) {
            throw ApiException.forbidden("Ce trajet est réservé aux femmes");
        }
        if (trajet.getNombrePlacesDisponibles() < req.nombrePlaces()) {
            throw ApiException.conflict("Il ne reste que " + trajet.getNombrePlacesDisponibles() + " place(s) sur ce trajet");
        }
        if (reservations.existsByTrajetIdAndPassagerIdAndStatutIn(trajetId, passagerId, ACTIVES)) {
            throw ApiException.conflict("Vous avez déjà une réservation en cours sur ce trajet");
        }
        Escale escale = null;
        if (req.idEscaleRamassage() != null) {
            escale = trajet.getEscales().stream().filter(e -> e.getId().equals(req.idEscaleRamassage())).findFirst()
                    .orElseThrow(() -> ApiException.badRequest("Cette escale n'appartient pas au trajet"));
        }

        Reservation r = new Reservation();
        r.setPassager(passager);
        r.setTrajet(trajet);
        r.setEscaleRamassage(escale);
        r.setNombrePlaces(req.nombrePlaces());
        r.setPrixUnitaire(trajet.getTarification().getPrixFinal());
        r.setMontantTotal(r.getPrixUnitaire().multiply(BigDecimal.valueOf(req.nombrePlaces())));
        reservations.save(r);

        Paiement p = new Paiement();
        p.setReservation(r);
        p.setMontant(r.getMontantTotal());
        p.setMoyenPaiement(moyen);
        p.setReferenceTransaction("YBL-" + UUID.randomUUID().toString().replace("-", "").substring(0, 20).toUpperCase());
        paiements.save(p);

        if (trajet.getModeReservation() == ModeReservation.AUTOMATIQUE) {
            accepterInterne(r, trajet);
        } else {
            evenements.publishEvent(new ReservationDemandee(r.getId()));
        }
        return dto(r);
    }

    @Transactional
    public ReservationDto annulerParPassager(Long passagerId, Long reservationId, String motif) {
        Reservation r = reservations.findById(reservationId).orElseThrow(() -> ApiException.notFound("Réservation introuvable"));
        if (!r.getPassager().getId().equals(passagerId)) throw ApiException.notFound("Réservation introuvable");
        if (!r.estActive()) throw ApiException.conflict("Cette réservation ne peut plus être annulée");
        Trajet trajet = trajets.findByIdForUpdate(r.getTrajet().getId()).orElseThrow();
        if (trajet.getStatut() == StatutTrajet.EN_COURS || trajet.getStatut() == StatutTrajet.TERMINE
                || !trajet.getDateHeureDepart().isAfter(LocalDateTime.now())) {
            throw ApiException.conflict("Le trajet a déjà commencé : la réservation ne peut plus être annulée");
        }
        boolean etaitAcceptee = r.getStatut() == StatutReservation.ACCEPTEE;
        clore(r, StatutReservation.ANNULEE, motif == null || motif.isBlank() ? "Annulée par le passager" : motif, true);
        if (etaitAcceptee) trajet.reserverPlaces(-r.getNombrePlaces());
        return dto(r);
    }

    @Transactional(readOnly = true)
    public List<ReservationDto> mesReservations(Long passagerId) {
        return reservations.findByPassagerIdOrderByDateDemandeDesc(passagerId).stream().map(this::dto).toList();
    }

    @Transactional(readOnly = true)
    public CodeEmbarquementDto codeEmbarquement(Long passagerId, Long reservationId) {
        Reservation r = reservations.findById(reservationId).orElseThrow(() -> ApiException.notFound("Réservation introuvable"));
        if (!r.getPassager().getId().equals(passagerId)) throw ApiException.notFound("Réservation introuvable");
        ConfirmationEmbarquement c = confirmations.findByReservationId(reservationId)
                .orElseThrow(() -> ApiException.conflict("Le code d'embarquement est disponible une fois la réservation acceptée"));
        Paiement p = paiements.findFirstByReservationIdOrderByDateInitiationDesc(r.getId()).orElseThrow();
        return new CodeEmbarquementDto(r.getId(), c.getCodePin(), PREFIXE_QR + c.getQrToken(), c.getStatut(),
                c.getDateExpiration(), resteAPayer(p));
    }

    // ------------------------------------------------------------------ Conducteur

    @Transactional(readOnly = true)
    public List<ReservationDto> reservationsDuTrajet(Long conducteurId, Long trajetId) {
        Trajet t = trajets.findById(trajetId).orElseThrow(() -> ApiException.notFound("Trajet introuvable"));
        if (!t.getConducteur().getId().equals(conducteurId)) throw ApiException.forbidden("Ce trajet ne vous appartient pas");
        return reservations.findByTrajetIdOrderByDateDemandeAsc(trajetId).stream().map(this::dto).toList();
    }

    @Transactional
    public ReservationDto accepter(Long conducteurId, Long reservationId) {
        Reservation r = chargerPourConducteur(conducteurId, reservationId);
        Trajet trajet = trajets.findByIdForUpdate(r.getTrajet().getId()).orElseThrow();
        if (r.getStatut() != StatutReservation.EN_ATTENTE) throw ApiException.conflict("Cette demande a déjà été traitée");
        if (!trajet.estOuvertALaReservation() || trajet.getNombrePlacesDisponibles() < r.getNombrePlaces()) {
            throw ApiException.conflict("Il n'y a plus assez de places disponibles sur ce trajet");
        }
        accepterInterne(r, trajet);
        return dto(r);
    }

    @Transactional
    public ReservationDto refuser(Long conducteurId, Long reservationId, String motif) {
        Reservation r = chargerPourConducteur(conducteurId, reservationId);
        if (r.getStatut() != StatutReservation.EN_ATTENTE) throw ApiException.conflict("Cette demande a déjà été traitée");
        r.setStatut(StatutReservation.REFUSEE);
        r.setMotifAnnulation(motif);
        r.setDateReponse(LocalDateTime.now());
        abandonnerPaiementEnAttente(r);
        evenements.publishEvent(new ReservationRefusee(r.getId(), motif));
        return dto(r);
    }

    /**
     * Le conducteur valide la prise en charge avec le PIN (ou le QR) du passager. Si le passager n'a pas déjà
     * payé par Wave / Orange Money, le conducteur encaisse le montant en espèces et le paiement est soldé.
     */
    @Transactional
    public EmbarquementConfirmeDto confirmerEmbarquement(Long conducteurId, Long trajetId, String code) {
        Trajet trajet = trajets.findById(trajetId).orElseThrow(() -> ApiException.notFound("Trajet introuvable"));
        if (!trajet.getConducteur().getId().equals(conducteurId)) throw ApiException.forbidden("Ce trajet ne vous appartient pas");
        if (trajet.getStatut() == StatutTrajet.ANNULE || trajet.getStatut() == StatutTrajet.TERMINE) {
            throw ApiException.conflict("Ce trajet n'accepte plus d'embarquement");
        }
        String valeur = code.trim().startsWith(PREFIXE_QR) ? code.trim().substring(PREFIXE_QR.length()) : code.trim();
        ConfirmationEmbarquement c = confirmations.trouverPourEmbarquement(trajetId, valeur, StatutConfirmation.EN_ATTENTE)
                .orElseThrow(() -> ApiException.notFound("Code invalide ou déjà utilisé pour ce trajet"));
        Reservation r = c.getReservation();
        if (r.getStatut() != StatutReservation.ACCEPTEE) throw ApiException.conflict("Cette réservation n'est plus valide");
        if (c.getDateExpiration().isBefore(LocalDateTime.now())) throw ApiException.conflict("Ce code a expiré");

        LocalDateTime maintenant = LocalDateTime.now();
        c.setStatut(StatutConfirmation.CONFIRMEE);
        c.setDateConfirmation(maintenant);
        Paiement p = paiements.findFirstByReservationIdOrderByDateInitiationDesc(r.getId()).orElseThrow();
        BigDecimal aEncaisser = resteAPayer(p);
        if (p.getStatut() != StatutPaiement.REUSSI) {
            // Espèces, ou paiement mobile non abouti : réglé en main propre au conducteur.
            p.setMoyenPaiement(MoyenPaiement.ESPECES);
            p.setFournisseur(null);
            p.setStatut(StatutPaiement.REUSSI);
            p.setDateConfirmation(maintenant);
        }
        evenements.publishEvent(new EmbarquementConfirme(r.getId()));
        return new EmbarquementConfirmeDto(r.getId(), UtilisateurResume.de(r.getPassager()),
                r.getNombrePlaces(), aEncaisser, p.getMoyenPaiement());
    }

    // ------------------------------------------------------------------ Événements trajet

    @EventListener
    public void surTrajetAnnule(TrajetAnnule e) {
        String motif = "Trajet annulé par le conducteur" + (e.motif() == null || e.motif().isBlank() ? "" : " : " + e.motif());
        for (Reservation r : reservations.findByTrajetIdAndStatutIn(e.idTrajet(), ACTIVES)) {
            clore(r, StatutReservation.ANNULEE, motif, true);
        }
    }

    /** Fin du trajet : passagers embarqués -> TERMINEE ; non embarqués -> ANNULEE ; demandes en attente -> REFUSEE. */
    @EventListener
    public void surTrajetTermine(TrajetTermine e) {
        LocalDateTime maintenant = LocalDateTime.now();
        for (Reservation r : reservations.findByTrajetIdAndStatutIn(e.idTrajet(), ACTIVES)) {
            if (r.getStatut() == StatutReservation.EN_ATTENTE) {
                r.setStatut(StatutReservation.REFUSEE);
                r.setDateReponse(maintenant);
                abandonnerPaiementEnAttente(r);
                continue;
            }
            boolean embarque = confirmations.findByReservationId(r.getId())
                    .map(c -> c.getStatut() == StatutConfirmation.CONFIRMEE).orElse(false);
            if (embarque) {
                r.setStatut(StatutReservation.TERMINEE);
            } else {
                // Absent au départ : ce n'est pas une annulation avant le départ, pas de remboursement.
                clore(r, StatutReservation.ANNULEE, "Passager non embarqué", false);
            }
        }
    }

    // ------------------------------------------------------------------ Interne

    private void accepterInterne(Reservation r, Trajet trajet) {
        trajet.reserverPlaces(r.getNombrePlaces());
        r.setStatut(StatutReservation.ACCEPTEE);
        r.setDateReponse(LocalDateTime.now());

        ConfirmationEmbarquement c = new ConfirmationEmbarquement();
        c.setReservation(r);
        c.setCodePin(genererPinUnique(trajet.getId()));
        byte[] octets = new byte[24];
        RANDOM.nextBytes(octets);
        c.setQrToken(Base64.getUrlEncoder().withoutPadding().encodeToString(octets));
        c.setDateExpiration(trajet.getDateHeureDepart().plusHours(6));
        confirmations.save(c);
        evenements.publishEvent(new ReservationAcceptee(r.getId()));
    }

    /** Annule/clôt une réservation et neutralise son code d'embarquement ; la facturation rembourse si besoin. */
    private void clore(Reservation r, StatutReservation statut, String motif, boolean avantDepart) {
        r.setStatut(statut);
        r.setMotifAnnulation(motif);
        r.setDateAnnulation(LocalDateTime.now());
        confirmations.findByReservationId(r.getId())
                .filter(c -> c.getStatut() == StatutConfirmation.EN_ATTENTE)
                .ifPresent(c -> c.setStatut(StatutConfirmation.ANNULEE));
        abandonnerPaiementEnAttente(r);
        evenements.publishEvent(new ReservationAnnulee(r.getId(), motif, avantDepart));
    }

    /** Un paiement jamais effectué n'aboutira plus. Un paiement réussi reste tel quel (remboursé par la facturation). */
    private void abandonnerPaiementEnAttente(Reservation r) {
        paiements.findFirstByReservationIdOrderByDateInitiationDesc(r.getId())
                .filter(p -> p.getStatut() == StatutPaiement.EN_ATTENTE)
                .ifPresent(p -> p.setStatut(StatutPaiement.ECHOUE));
    }

    private static BigDecimal resteAPayer(Paiement p) {
        return p.getStatut() == StatutPaiement.REUSSI ? BigDecimal.ZERO : p.getMontant();
    }

    private String genererPinUnique(Long trajetId) {
        for (int i = 0; i < 20; i++) {
            String pin = String.format("%06d", RANDOM.nextInt(1_000_000));
            if (!confirmations.pinDejaUtilise(trajetId, pin)) return pin;
        }
        throw new IllegalStateException("Impossible de générer un code PIN unique");
    }

    private Reservation chargerPourConducteur(Long conducteurId, Long reservationId) {
        Reservation r = reservations.findById(reservationId).orElseThrow(() -> ApiException.notFound("Réservation introuvable"));
        if (!r.getTrajet().getConducteur().getId().equals(conducteurId)) {
            throw ApiException.forbidden("Cette réservation ne concerne pas l'un de vos trajets");
        }
        return r;
    }

    private ReservationDto dto(Reservation r) {
        return ReservationDto.de(r,
                paiements.findFirstByReservationIdOrderByDateInitiationDesc(r.getId()).orElse(null),
                confirmations.findByReservationId(r.getId()).orElse(null));
    }

    private static String libelle(MoyenPaiement moyen) {
        return switch (moyen) {
            case ESPECES -> "espèces";
            case WAVE -> "Wave";
            case ORANGE_MONEY -> "Orange Money";
        };
    }
}
