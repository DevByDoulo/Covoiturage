package sn.isep.Convoiturage.vehicule;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VehiculeRepository extends JpaRepository<Vehicule, Long> {

    List<Vehicule> findByProprietaireIdAndActifTrueOrderByDateCreationDesc(Long proprietaireId);

    Optional<Vehicule> findByIdAndProprietaireId(Long id, Long proprietaireId);

    Optional<Vehicule> findByImmatriculationIgnoreCase(String immatriculation);

    boolean existsByProprietaireIdAndStatutValidationAndActifTrue(Long proprietaireId, StatutValidation statut);
}
