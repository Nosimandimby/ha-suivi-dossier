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

## 2. Contenu du dossier

```
hass-addon/
├── config.yaml          # Configuration de l'add-on (nom, version, options, ingress)
├── Dockerfile           # Construction de l'image (Python 3.13 Alpine)
├── run.sh               # Script de démarrage (lit /data/options.json)
├── DOCS.md              # Documentation embarquée dans Home Assistant
├── README.md            # Ce fichier
├── icon.png
├── logo.png
├── repository.yaml      # Métadonnées du dépôt d'add-ons (méthode B)
└── app/                 # Code source de l'application
    ├── main.py          # Backend FastAPI
    ├── database.py      # Schéma SQLite et règles métier
    ├── seed.py          # Données de démonstration
    ├── chemins.py       # Résolution des chemins
    ├── requirements.txt
    └── static/          # Interface HTML / CSS / JS
```

---

## 3. Installation

### Méthode A — installation locale (sans dépôt GitHub)

1. **Activer le mode avancé**  
   Profil (en bas de la barre latérale) → onglet **Mode avancé** → activer.

2. **Copier le dossier dans `/addons`**  
   Via **Samba share** : copiez le dossier `hass-addon` dans le partage `addons`.  
   Via **Advanced SSH & Web Terminal** :
   ```bash
   ls /addons          # vérifier que le dossier n'existe pas déjà
   # copier le dossier ici
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

### Méthode B — dépôt d'add-ons (mises à jour automatiques)

1. Publiez ce dossier sur GitHub / Gitea / GitLab avec la structure suivante :
   ```
   repository.yaml
   suivi_dossiers/
       config.yaml
       Dockerfile
       run.sh
       ...
   ```
2. Dans Home Assistant : **Paramètres → Modules complémentaires → Boutique →
   ⋮ → Dépôts** → ajoutez l'URL du dépôt.
3. Installez puis démarrez l'add-on comme en méthode A.

Pour proposer une mise à jour, incrémentez `version:` dans `config.yaml`
(par exemple `1.0.1` → `1.0.2`) avant de publier.

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

Pour plus de détails, consultez le guide complet
[`INSTALLATION-HA.md`](./INSTALLATION-HA.md).
