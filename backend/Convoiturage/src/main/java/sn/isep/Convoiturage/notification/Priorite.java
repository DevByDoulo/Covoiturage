package sn.isep.Convoiturage.notification;

/**
 * Urgence d'une notification. NORMALE : dans l'application (et en push si l'appareil est enregistré).
 * IMPORTANTE : en plus, par email (ou par SMS si le compte n'a pas d'email), car l'utilisateur doit la voir
 * même s'il n'ouvre pas l'application (réservation confirmée, trajet annulé, document refusé…).
 */
public enum Priorite { NORMALE, IMPORTANTE }
