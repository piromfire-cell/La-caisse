# 🍺 La Caisse

**Le jeu de bluff qui se boit.** Un seul téléphone qu'on se passe autour de la table, 2 à 10 joueurs,
aucun Internet requis. Fait avec Godot 4 (GDScript), interface en français.

> ⚠️ Jeu pour adultes (18 ans et plus, ou l'âge légal de ta région). Bois de façon responsable,
> ne conduis jamais après avoir bu. Le **mode Soft** remplace l'alcool par de l'eau ou des défis.

---

## 📱 Installer le jeu sur ton téléphone Android (APK)

Le fichier d'installation s'appelle **`La-Caisse.apk`** (dossier `dist/` du projet).

1. **Récupère le fichier** sur ton téléphone :
   - soit en le téléchargeant depuis la conversation avec Claude (touche le fichier envoyé) ;
   - soit depuis GitHub : ouvre le dépôt `piromfire-cell/La-caisse`, va dans le dossier **`dist`**,
     touche **`La-Caisse.apk`**, puis le bouton de téléchargement (⬇ « Download raw file »).
2. **Ouvre le fichier téléchargé** (notification « Téléchargement terminé », ou l'appli *Fichiers* → *Téléchargements*).
3. Android va dire que l'installation depuis cette source est bloquée : touche **Paramètres**, puis
   active **« Autoriser depuis cette source »** (c'est normal : le jeu ne vient pas du Play Store).
   Reviens en arrière avec la flèche.
4. Touche **Installer**. Si Google Play Protect affiche un avertissement (« application non reconnue »),
   touche **Détails** → **Installer quand même**. (Le jeu est signé par nous, pas par Google, d'où l'avertissement.)
5. Touche **Ouvrir**. L'icône « La Caisse » (une chope de bière) est maintenant dans tes applis. 🎉

**Mise à jour du jeu plus tard :** installe simplement le nouveau `La-Caisse.apk` par-dessus l'ancien :
tes réglages et les noms des joueurs sont conservés.

**Désinstaller :** appui long sur l'icône → *Désinstaller*.

Le jeu demande **une seule permission : la vibration** (pour le « MENTEUR ! »). Il n'a **pas** accès à Internet
et ne collecte aucune donnée.

---

## 🌐 Jouer dans le navigateur du cell (version Web)

La version Web est dans le dossier **`docs/`** (c'est un vrai site : `docs/index.html`). Pour y jouer depuis
n'importe quel téléphone (Android **ou iPhone**), il faut la « mettre en ligne » une fois. Trois façons, de la
plus simple à la plus indépendante :

### Option A — GitHub Pages (gratuit, déjà dans ton dépôt)

1. Sur GitHub, ouvre le dépôt `piromfire-cell/La-caisse` → onglet **Settings** (Paramètres).
2. Dans le menu de gauche, touche **Pages**.
3. Sous **Build and deployment** → **Source** : choisis **Deploy from a branch**.
4. Sous **Branch** : choisis la branche **`claude/la-caisse-godot-game-rxf4my`** (ou `main` si tu as fusionné
   le travail dedans), dossier **`/docs`**, puis **Save**.
5. Attends 1 à 2 minutes. Ton jeu est à l'adresse :
   **https://piromfire-cell.github.io/La-caisse/**
6. Ouvre cette adresse sur ton cell. 👍

> Si l'option *Pages* est grisée ou demande de passer à un forfait payant, c'est que le dépôt est **privé** :
> utilise plutôt l'option B ou C (ou rends le dépôt public dans *Settings → General → Danger Zone*).

### Option B — itch.io (gratuit, très simple, joue directement dans la page)

1. Crée un compte gratuit sur <https://itch.io>, puis **Upload new project**.
2. **Kind of project** : *HTML*. Envoie le fichier **`dist/La-Caisse-web.zip`**
   et coche **« This file will be played in the browser »**.
3. **Viewport size** : largeur `450`, hauteur `800`. Coche **Mobile friendly** et **Fullscreen button**.
4. Mets la visibilité sur *Restricted* (privé, accessible avec un mot de passe) ou *Public*, puis **Save**.
5. Ouvre la page du jeu sur ton cell et touche **Run game**.

### Option C — Netlify Drop (30 secondes, sans programmation)

1. Va sur <https://app.netlify.com/drop>.
2. Glisse-dépose le **dossier `docs`** (ou dézippe `La-Caisse-web.zip` et glisse le dossier obtenu).
3. Netlify te donne une adresse (du genre `https://xxxx.netlify.app`) : ouvre-la sur ton cell.

### Astuce : « installer » la version Web comme une appli

Une fois le jeu ouvert dans le navigateur de ton téléphone :
- **Android (Chrome)** : menu ⋮ → **Ajouter à l'écran d'accueil** (ou *Installer l'application*).
- **iPhone (Safari)** : bouton Partager ⬆ → **Sur l'écran d'accueil**.

Le jeu s'ouvre alors en plein écran avec son icône, et **fonctionne même sans connexion** après le premier chargement.

---

## 🎲 Les règles en bref

- À ton tour, tu lances **2 dés en secret** (maintiens ton doigt sur le sous-bock pour les voir). Le plus gros chiffre se lit
  en premier : un 3 et un 5 = **53**.
- **Classement, du plus faible au plus fort :** les normaux `31 32 41 42 43 51 … 65` < les **mousses** (doubles)
  `11 22 33 44 55 66` < **LA CAISSE** `21`.
- Tu **annonces** un résultat — vrai ou bluff — obligatoirement **plus fort** que l'annonce précédente
  (le jeu ne propose que les choix valides).
- Le joueur suivant choisit :
  - **JE TE CROIS** : la mise monte de 1 gorgée, il relance ses dés en secret et doit annoncer plus fort ;
  - **MENTEUR !** : on révèle les vrais dés. Bluff (dés plus faibles) → le menteur boit la mise ;
    vrai (dés égaux ou plus forts) → l'accusateur boit la mise.
- Mise de départ : **1 gorgée**. Si l'annonce contestée est **LA CAISSE**, la mise est **doublée**.
  Une punition ne dépasse jamais la limite des réglages (5 par défaut).
- Après une accusation : mise remise à 1, annonces effacées, et **le perdant commence** la manche suivante.
- **Règle spéciale :** rien ne bat LA CAISSE. Le joueur suivant peut seulement la **croire** (il boit la mise tout de suite
  et la manche recommence) ou **accuser**.

Précisions sur des cas que la règle ne détaille pas (choix faits dans le jeu) :
- La règle spéciale s'applique dès que **quelqu'un annonce** LA CAISSE (vraie ou bluff) : le jeu ne dévoile jamais
  si c'est vrai avant une accusation. Si on la croit, les vrais dés restent secrets.
- Croire LA CAISSE fait boire la mise **telle quelle** (sans doublage, sans le +1 habituel). Seule une *accusation* double la mise.
- La mise ne dépasse jamais la limite choisie dans les réglages, et la punition non plus (même doublée).
- La partie n'a pas de fin automatique : touche **☰ → Terminer la partie** (ou « Terminer » après une révélation)
  pour voir le tableau des stats.

---

## ⚙️ Réglages

- **Limite de gorgées** par punition (1 à 15, 5 par défaut).
- **Mode Soft** : de l'**eau**, des **défis** (plus la punition est grosse, plus le défi est corsé) ou **les deux**.
- Sons, voix « Menteur ! » (synthèse vocale du téléphone, si une voix française est installée), vibrations.
- **Point d'aide** : un petit point discret sur la grille d'annonce indique ton vrai résultat (désactivable).

L'avertissement 18+ s'affiche à chaque ouverture de l'appli.

---

## 🛠️ Demander des changements (pour toi qui ne programmes pas)

Dis simplement à Claude ce que tu veux (« change la couleur des boutons », « ajoute 10 défis », « le jeu doit
se terminer après 15 manches »…). Pour t'y retrouver, voici la carte du projet :

| Je veux changer… | Fichier |
|---|---|
| Les **règles** (mise, classement, verdict) | `scripts/core/rules.gd`, `dice.gd`, `match_state.gd` |
| Les **défis** du mode Soft | `scripts/core/challenges.gd` |
| Les **couleurs, polices, boutons** | `scripts/ui/ui.gd` |
| Un **écran** précis | `scripts/screens/*_screen.gd` (accueil, joueurs, passage, dés, annonce, décision, révélation, stats, règles, réglages) |
| Les **sons** (fabriqués en code) | `scripts/autoload/sfx.gd` |
| Les **réglages** sauvegardés | `scripts/autoload/settings.gd` |
| L'**ordre des écrans** | `scripts/autoload/game.gd` |
| Les **tests automatiques** | dossier `tests/` |

Chaque fichier est commenté en français.

### Tester et reconstruire (commandes)

```bash
bash tools/setup_env.sh      # une seule fois : installe Godot 4.4.1 + de quoi signer l'APK (Linux)
bash tools/build_all.sh      # lance tous les tests, puis fabrique docs/ (Web) et dist/La-Caisse.apk
```

- Tests de la logique seule (dés, classement, annonces valides, mise, verdict, stats — plus de 2 millions de vérifications
  avec 3000 parties simulées) :
  `godot --headless --path . --script res://tests/run_tests.gd`
- Test d'interface (un robot joue de vraies parties en appuyant sur les boutons) :
  `godot --headless --path . res://tests/ui_flow_test.tscn`
- Régénérer les icônes : `node tools/make_icons.js` (SVG dans `assets/icons/`).

### Remarque sur la clé de signature Android

L'APK est signé avec la clé **`keystore/la-caisse.keystore`** (mot de passe dans `export_presets.cfg`).
Elle est dans le dépôt volontairement : **Android n'accepte une mise à jour que si l'APK est signé avec la même clé**,
donc il ne faut ni la perdre ni la changer. C'est parfait pour un jeu entre amis. Si un jour tu veux publier sur le
Google Play Store, il faudra créer une nouvelle clé secrète, non partagée.

---

## 📜 Licences

- Code du jeu : à toi, fais-en ce que tu veux.
- Polices **Lilita One** et **Fredoka** : licence SIL Open Font License 1.1 (voir `assets/fonts/OFL-*.txt`).
- Moteur **Godot** : licence MIT.
