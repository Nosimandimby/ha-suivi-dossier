# Suivi des dossiers — add-on Home Assistant

Application de suivi des dossiers administratifs (accusé de réception, retrait,
visa, retour) servie directement dans l'interface de Home Assistant, avec sa
propre base SQLite persistante.

---

## 1. Prérequis

| Élément | Nécessaire |
|---|---|
| Installation Home Assistant | **Home Assistant OS** ou **Home Assistant Supervised** (l'installation « Container » n'a pas de boutique d'add-ons) |
| Version | Home Assistant 2024.1 ou plus récent |
| Architecture | `amd64` (PC, NUC, VM, HA Yellow) ou `aarch64` (Raspberry Pi 4/5, HA Green) — **armv7 / armhf non supportés** |
| Accès fichiers | Add-on **Samba share** ou **Advanced SSH & Web Terminal** |
| Réseau | Accès à `ghcr.io` et PyPI pendant la construction de l'image |

---

## 2. Structure du projet

Pour que Home Assistant détecte l'add-on (soit en local, soit via un dépôt GitHub),
le dossier doit respecter **cette structure exacte** :

```
suivi-dossiers-hass-addon/         ← racine de votre dépôt GitHub
├── repository.yaml                ← Métadonnées du dépôt (obligatoire pour méthode B)
└── suivi_dossiers/                ← Dossier de l'add-on (slug = suivi_dossiers)
    ├── config.yaml                # Configuration de l'add-on
    ├── Dockerfile                 # Construction de l'image (Python 3.13 Alpine)
    ├── run.sh                     # Script de démarrage
    ├── DOCS.md                    # Documentation embarquée
    ├── README.md                  # Ce fichier
    ├── icon.png
    ├── logo.png
    ├── synchroniser-addon.sh      # Script de synchronisation du code
    └── app/                       # Code source de l'application
        ├── main.py                # Backend FastAPI
        ├── database.py            # Schéma SQLite et règles métier
        ├── seed.py                # Données de démonstration
        ├── chemins.py             # Résolution des chemins
        ├── requirements.txt
        └── static/                # Interface HTML / CSS / JS
```

> **Important** : Le nom du dossier de l'add-on **doit être `suivi_dossiers`** (le slug
> défini dans `config.yaml`). Tout autre nom fera échouer la détection par Home Assistant.

---

## 3. Installation

### Méthode A — installation locale (sans dépôt GitHub)

1. **Activer le mode avancé**  
   Profil (en bas de la barre latérale) → onglet **Mode avancé** → activer.

2. **Copier le dossier `suivi_dossiers/` dans `/addons`**  
   Via **Samba share** : copiez le dossier `suivi_dossiers` dans le partage `addons`.  
   Via **Advanced SSH & Web Terminal** :
   ```bash
   ls /addons          # vérifier que le dossier n'existe pas déjà
   # copier le dossier suivi_dossiers ici
   ```

   Le fichier suivant doit exister :
   ```
   /addons/suivi_dossiers/config.yaml
   ```
   ⚠️ Un niveau de trop (`/addons/suivi_dossiers/suivi_dossiers/config.yaml`)
   est la cause n°1 d'un add-on invisible dans Home Assistant.

3. **Rafraîchir la boutique**  
   **Paramètres → Modules complémentaires → Boutique** → menu **⋮** →
   **Vérifier les mises à jour**.  
   Une section **Modules complémentaires locaux** apparaît avec la carte
   **Suivi des dossiers**.

4. **Installer**  
   Cliquez sur la carte puis sur **Installer**. Le premier build prend
   généralement 3 à 10 minutes.

5. **Démarrer**  
   Onglet **Démarrer** → **Démarrer**. L'entrée **Dossiers** apparaît dans la
   barre latérale de Home Assistant.

### Méthode B — dépôt d'add-ons GitHub (mises à jour automatiques)

1. **Préparez le dépôt GitHub**  
   Créez un dépôt (ex: `suivi-dossiers-hass-addon`) avec la structure
   montrée ci-dessus. Assurez-vous que :
   - `repository.yaml` est à la **racine du dépôt**
   - `suivi_dossiers/` est un **sous-dossier** à la racine

2. **Éditez `repository.yaml`** à la racine avec vos informations :
   ```yaml
   name: Suivi des dossiers
   maintainer: VotrePseudoGitHub
   type: github
   location: https://github.com/VotrePseudoGitHub/suivi-dossiers-hass-addon
   version: "1.0.1"
   ```
   Remplacez `VotrePseudoGitHub` par votre nom d'utilisateur GitHub réel.

3. **Ajoutez le dépôt dans Home Assistant**  
   - **Paramètres → Modules complémentaires → Boutique → ⋮ → Dépôts**
   - Collez l'URL de votre dépôt GitHub (ex: `https://github.com/Vous/suivi-dossiers-hass-addon`)
   - Cliquez sur **Ajouter**

4. **Installez l'add-on**  
   La section de votre dépôt apparaît dans la boutique. Installez **Suivi des dossiers**
   comme en méthode A.

5. **Mises à jour futures**  
   - Modifiez le code, incrémentez `version:` dans `config.yaml` (ex: `1.0.1` → `1.0.2`)
   - `git commit && git push`
   - Dans Home Assistant : Boutique → ⋮ → **Vérifier les mises à jour** → **Mettre à jour**

---

## 4. Configuration du port

L'add-on écoute par défaut sur le port interne **`8000`**, utilisé par l'ingress
Home Assistant. Une option **`port`** est disponible dans la configuration de
l'add-on et lue depuis `/data/options.json` :

```json
{
  "port": 9000
}
```

`run.sh` exporte ensuite la variable d'environnement `PORT` avant de lancer
l'application. Redémarrez l'add-on après modification.

> **Remarque** : l'ingress Home Assistant continue d'utiliser le port interne
> `8000` défini par `ingress_port` dans `config.yaml`. Pour modifier ce port,
> il faut éditer `config.yaml` et reconstruire l'add-on.

---

## 5. Première connexion

1. Ouvrez **Dossiers** dans la barre latérale.
2. Connectez-vous avec le compte de démonstration :
   - Identifiant : `admin`
   - Mot de passe : `admin`
3. Changez immédiatement le mot de passe : onglet **Utilisateurs** → `admin`.

---

## 6. Données et sauvegardes

- La base est le fichier **`/data/dossiers.db`** : volume persistant privé de
  l'add-on. Elle survit aux redémarrages, mises à jour et réinstallations.
- Elle est incluse dans les **sauvegardes Home Assistant**
  (**Paramètres → Système → Sauvegardes**).
- Pour importer une base existante, déposez `dossiers.db` dans le dossier
  partagé **`/share`** avant le premier démarrage. L'import n'est effectué
  qu'une seule fois, si `/data/dossiers.db` n'existe pas encore.

---

## 7. Dépannage rapide

| Symptôme | Cause probable | Solution |
|---|---|---|
| L'add-on n'apparaît pas dans la boutique | Dossier mal placé ou boutique non rafraîchie | Vérifier `/addons/suivi_dossiers/config.yaml`, puis ⋮ → **Vérifier les mises à jour** |
| Le menu ⋮ n'affiche pas « Vérifier les mises à jour » | Mode avancé désactivé | Profil → Mode avancé |
| Échec du build (`ghcr.io` / PyPI injoignable) | Problème réseau ou DNS | Autoriser `ghcr.io` et `files.pythonhosted.org` |
| L'add-on démarre puis s'arrête | Port déjà utilisé ou `/data` non inscriptible | Consulter l'onglet **Journaux** |
| La base de démonstration remplace mes données | `/data/dossiers.db` existait déjà | Restaurer une sauvegarde ou réinstaller proprement |
| Dépôt GitHub non détecté | `repository.yaml` manquant ou mal placé | Vérifier structure : `repository.yaml` à la racine + `suivi_dossiers/` en dessous |

Pour plus de détails, consultez le guide complet
[`INSTALLATION-HA.md`](./INSTALLATION-HA.md).

---

## 8. Synchronisation du code (développement)

Le script `synchroniser-addon.sh` copie le code depuis la racine du projet vers
l'add-on. **Exécutez-le depuis la racine du projet** (là où se trouvent
`main.py`, `database.py`, etc.) après chaque modification :

```bash
./hass-addon/suivi_dossiers/synchroniser-addon.sh
```

Cela met à jour `hass-addon/suivi_dossiers/app/` avant de publier / installer.