# CoVoitIA — Frontend Angular 21

Application web (passager, conducteur, back-office admin). Composants autonomes, signaux,
sans zone.js, formulaires réactifs typés, styles SCSS sans bibliothèque d'interface.

```bash
npm install
npm start          # http://localhost:4200 — l'API doit tourner sur http://localhost:8080
npm test           # tests unitaires (Vitest)
npm run build      # build de production dans dist/
```

Configuration : `src/environments/environment.ts` (dev) et `environment.prod.ts` (prod) :
`apiUrl`, `googleClientId` (vide = bouton Google désactivé avec message).

## Organisation

```
src/app
├── core
│   ├── api/erreur-api.ts        lecture des ProblemDetail du backend (message, champ, tentativesRestantes…)
│   └── auth/                    SessionService (jetons, parcours d'auth), intercepteur JWT + refresh, guards
├── shared/ui                    icônes, logo, alerte, champ mot de passe, saisie de code OTP, pavé numérique…
└── features
    ├── auth                     connexion, inscription, vérification OTP, mot de passe oublié, téléphone Google
    └── accueil                  page provisoire après connexion
```

## Session

- Jeton d'accès en mémoire uniquement ; refresh token en `localStorage` (session conservée après rechargement).
- Au démarrage, la session est rouverte via `/api/auth/refresh` avant la première navigation.
- Sur un 401, l'intercepteur renouvelle le jeton une fois et rejoue la requête ; sinon retour à la connexion.
- La vérification OTP en cours (numéro masqué, échéances) est gardée en `sessionStorage`.
