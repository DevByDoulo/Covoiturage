package sn.isep.Convoiturage.auth;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface OtpCodeRepository extends JpaRepository<OtpCode, Long> {

    Optional<OtpCode> findFirstByTelephoneAndObjetOrderByDateCreationDesc(String telephone, ObjetOtp objet);
}
