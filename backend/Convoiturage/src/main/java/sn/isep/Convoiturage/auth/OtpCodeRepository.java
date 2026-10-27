package sn.isep.Convoiturage.auth;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;

public interface OtpCodeRepository extends JpaRepository<OtpCode, Long> {

    Optional<OtpCode> findFirstByTelephoneAndObjetOrderByDateCreationDesc(String telephone, ObjetOtp objet);

    long countByTelephoneAndObjetAndDateCreationAfter(String telephone, ObjetOtp objet, LocalDateTime debut);

    Optional<OtpCode> findFirstByTelephoneAndObjetAndDateCreationAfterOrderByDateCreationAsc(
            String telephone, ObjetOtp objet, LocalDateTime debut);
}
