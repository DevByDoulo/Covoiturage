import { Pipe, PipeTransform } from '@angular/core';

const FCFA = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 });

/** 1650 -> « 1 650 FCFA » */
@Pipe({ name: 'fcfa' })
export class FcfaPipe implements PipeTransform {
  transform(montant: number | null | undefined): string {
    return montant == null ? '—' : `${FCFA.format(montant)} FCFA`;
  }
}

/** 75 -> « 1 h 15 », 40 -> « 40 min » */
@Pipe({ name: 'duree' })
export class DureePipe implements PipeTransform {
  transform(minutes: number | null | undefined): string {
    if (minutes == null) return '—';
    const h = Math.floor(minutes / 60);
    const m = Math.round(minutes % 60);
    if (h === 0) return `${m} min`;
    return m === 0 ? `${h} h` : `${h} h ${String(m).padStart(2, '0')}`;
  }
}

/** Valeur pour un champ <input type="datetime-local"> : « 2026-10-28T08:00 ». */
export function versDateTimeLocal(date: Date): string {
  const p = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${p(date.getMonth() + 1)}-${p(date.getDate())}T${p(date.getHours())}:${p(date.getMinutes())}`;
}
