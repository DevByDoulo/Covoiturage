package sn.isep.Convoiturage.tarification;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sn.isep.Convoiturage.common.ApiException;
import sn.isep.Convoiturage.utilisateur.Utilisateur;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/** Lecture/écriture des coefficients de tarification (table parametre_tarification). */
@Service
@RequiredArgsConstructor
public class ParametresTarification {

    private final ParametreTarificationRepository repository;

    public record ParametreDto(String cle, BigDecimal valeur, String unite, String description, boolean actif,
                               LocalDateTime dateModification) {
        static ParametreDto de(ParametreTarification p) {
            return new ParametreDto(p.getCle(), p.getValeur(), p.getUnite(), p.getDescription(), p.isActif(), p.getDateModification());
        }
    }

    @Transactional(readOnly = true)
    public BigDecimal valeur(CleParametre cle) {
        return repository.findByCle(cle.name())
                .filter(ParametreTarification::isActif)
                .map(ParametreTarification::getValeur)
                .orElse(cle.defaut());
    }

    @Transactional(readOnly = true)
    public List<ParametreDto> lister() {
        return repository.findAllByOrderByCleAsc().stream().map(ParametreDto::de).toList();
    }

    @Transactional
    public ParametreDto modifier(String cle, BigDecimal valeur, Utilisateur admin) {
        if (valeur == null || valeur.signum() < 0) throw ApiException.badRequest("La valeur doit être positive");
        ParametreTarification p = repository.findByCle(cle).orElseThrow(() -> ApiException.notFound("Paramètre inconnu : " + cle));
        p.setValeur(valeur);
        p.setAdmin(admin);
        p.setDateModification(LocalDateTime.now());
        return ParametreDto.de(p);
    }
}
