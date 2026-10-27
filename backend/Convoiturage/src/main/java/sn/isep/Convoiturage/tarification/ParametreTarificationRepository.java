package sn.isep.Convoiturage.tarification;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ParametreTarificationRepository extends JpaRepository<ParametreTarification, Long> {

    Optional<ParametreTarification> findByCle(String cle);

    List<ParametreTarification> findAllByOrderByCleAsc();
}
