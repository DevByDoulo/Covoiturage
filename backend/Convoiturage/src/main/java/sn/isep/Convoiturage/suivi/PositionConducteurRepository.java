package sn.isep.Convoiturage.suivi;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;

public interface PositionConducteurRepository extends JpaRepository<PositionConducteur, Long> {

    @Modifying
    @Query("delete from PositionConducteur p where p.dateMaj < :limite")
    int supprimerAnciennes(@Param("limite") LocalDateTime limite);
}
