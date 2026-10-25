import { DestroyRef, Signal, computed, inject, signal } from '@angular/core';

/**
 * Secondes restantes jusqu'à une échéance (epoch ms), mises à jour chaque seconde.
 * À appeler dans un contexte d'injection (constructeur ou initialiseur de champ d'un composant).
 */
export function compteARebours(echeance: Signal<number | null>): Signal<number> {
  const maintenant = signal(Date.now());
  const minuterie = setInterval(() => maintenant.set(Date.now()), 1000);
  inject(DestroyRef).onDestroy(() => clearInterval(minuterie));
  return computed(() => {
    const fin = echeance();
    return fin === null ? 0 : Math.max(0, Math.ceil((fin - maintenant()) / 1000));
  });
}

/** 272 -> "04:32" */
export function formatMinutes(secondes: number): string {
  const m = Math.floor(secondes / 60);
  const s = secondes % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}
