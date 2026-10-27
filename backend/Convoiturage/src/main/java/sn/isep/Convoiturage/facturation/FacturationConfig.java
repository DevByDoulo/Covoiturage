package sn.isep.Convoiturage.facturation;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/** Active les tâches planifiées : relance des remboursements que l'opérateur n'a pas pu traiter. */
@Configuration
@EnableScheduling
class FacturationConfig {
}
