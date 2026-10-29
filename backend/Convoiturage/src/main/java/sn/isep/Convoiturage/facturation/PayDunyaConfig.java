package sn.isep.Convoiturage.facturation;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import sn.isep.Convoiturage.reservation.MoyenPaiement;

/** PayDunya relaie Wave et Orange Money : un fournisseur par moyen, sur le même client HTTP. */
@Configuration
class PayDunyaConfig {

    @Bean
    FournisseurPaiement payDunyaWave(PayDunyaClient client, PaiementProperties props) {
        return new PayDunyaFournisseur(MoyenPaiement.WAVE, client, props);
    }

    @Bean
    FournisseurPaiement payDunyaOrangeMoney(PayDunyaClient client, PaiementProperties props) {
        return new PayDunyaFournisseur(MoyenPaiement.ORANGE_MONEY, client, props);
    }
}
