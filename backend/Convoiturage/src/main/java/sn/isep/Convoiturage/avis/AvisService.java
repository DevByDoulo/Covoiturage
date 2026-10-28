package sn.isep.Convoiturage.avis;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.avis.AvisDtos.*;
import sn.isep.Convoiturage.avis.AvisEvenements.AvisPublie;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.reservation.Reservation;
import sn.isep.Convoiturage.reservation.ReservationRepository;
import sn.isep.Convoiturage.reservation.StatutReservation;
import sn.isep.Convoiturage.utilisateur.Utilisateur;
import sn.isep.Convoiturage.utilisateur.UtilisateurRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

/**
 * Évaluations après un voyage : le passager embarqué note son conducteur et le conducteur note ce passager,
 * une fois le trajet terminé et pendant {@link #DELAI_JOURS} jours après le départ. Chaque nouvel avis
 * recalcule la note moyenne de la personne notée (utilisée par la recherche de trajets).
 */
@Service
@RequiredArgsConstructor
public class AvisService {

    static final int DELAI_JOURS = 14;
    static final int AVIS_AFFICHES = 20;

    private final EvaluationRepository evaluations;
    private final ReservationRepository reservations;
    private final UtilisateurRepository utilisateurs;
    private final ApplicationEventPublisher evenements;

    @Transactional
    public AvisDto evaluer(Long utilisateurId, Long reservationId, EvaluationRequete req) {
        Reservation r = reservations.findById(reservationId).orElseThrow(() -> ApiException.notFound("Réservation introuvable"));
        Utilisateur conducteur = r.getTrajet().getConducteur();
        boolean estPassager = r.getPassager().getId().equals(utilisateurId);
        boolean estConducteur = conducteur.getId().equals(utilisateurId);
        if (!estPassager && !estConducteur) throw ApiException.notFound("Réservation introuvable");
        if (r.getStatut() != StatutReservation.TERMINEE) {
            throw ApiException.conflict("Vous pourrez donner votre avis une fois le voyage effectué et le trajet terminé");
        }
        if (dateLimite(r).isBefore(LocalDateTime.now())) {
            throw ApiException.conflict("Le délai pour donner votre avis sur ce voyage (" + DELAI_JOURS + " jours) est dépassé");
        }
        if (evaluations.existsByReservationIdAndEvaluateurId(reservationId, utilisateurId)) {
            throw ApiException.conflict("Vous avez déjà donné votre avis sur ce voyage");
        }

        Evaluation e = new Evaluation();
        e.setReservation(r);
        e.setTrajet(r.getTrajet());
        e.setEvaluateur(estPassager ? r.getPassager() : conducteur);
        e.setEvalue(estPassager ? conducteur : r.getPassager());
        e.setNote(req.note().shortValue());
        String commentaire = req.commentaire() == null ? "" : req.commentaire().trim();
        e.setCommentaire(commentaire.isEmpty() ? null : commentaire);
        evaluations.save(e);

        recalculerMoyenne(e.getEvalue());
        evenements.publishEvent(new AvisPublie(e.getId(), e.getEvalue().getId(), req.note()));
        return AvisDto.de(e);
    }

    /** Voyages terminés que l'utilisateur n'a pas encore notés, dans le délai. */
    @Transactional(readOnly = true)
    public List<AvisADonnerDto> aDonner(Long utilisateurId) {
        List<Reservation> voyages = reservations.voyagesTerminesDepuis(utilisateurId,
                LocalDateTime.now().minusDays(DELAI_JOURS));
        if (voyages.isEmpty()) return List.of();
        Set<Long> dejaNotees = evaluations.reservationsDejaNotees(utilisateurId,
                voyages.stream().map(Reservation::getId).toList());
        return voyages.stream()
                .filter(r -> !dejaNotees.contains(r.getId()))
                .map(r -> AvisADonnerDto.de(r, r.getTrajet().getConducteur().getId().equals(utilisateurId), dateLimite(r)))
                .toList();
    }

    /** Réputation publique d'une personne : moyenne, répartition des notes et derniers avis. */
    @Transactional(readOnly = true)
    public ReputationDto reputation(Long utilisateurId) {
        Utilisateur u = utilisateurs.findById(utilisateurId).orElseThrow(() -> ApiException.notFound("Utilisateur introuvable"));
        long[] repartition = new long[5];
        for (Object[] ligne : evaluations.repartition(utilisateurId)) {
            repartition[((Number) ligne[0]).intValue() - 1] = ((Number) ligne[1]).longValue();
        }
        List<AvisDto> derniers = evaluations
                .findByEvalueIdOrderByDateEvaluationDesc(utilisateurId, PageRequest.of(0, AVIS_AFFICHES))
                .stream().map(AvisDto::de).toList();
        return new ReputationDto(u.getId(), u.getNoteMoyenne(), evaluations.countByEvalueId(utilisateurId),
                repartition, derniers);
    }

    private void recalculerMoyenne(Utilisateur evalue) {
        Double moyenne = evaluations.moyenne(evalue.getId());
        evalue.setNoteMoyenne(moyenne == null ? null : BigDecimal.valueOf(moyenne).setScale(2, RoundingMode.HALF_UP));
    }

    private static LocalDateTime dateLimite(Reservation r) {
        return r.getTrajet().getDateHeureDepart().plusDays(DELAI_JOURS);
    }
}
