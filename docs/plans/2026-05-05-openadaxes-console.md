# OpenAdaxes Console Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Transformer OpenRSAT en console desktop open-source inspirée d'Adaxes Administration Console, sans portail web ni self-service web.

**Architecture:** Fork produit basé sur OpenRSAT/Lazarus. On garde le coeur LDAP/AD existant, on ajoute une couche UX console moderne, des actions bulk, des templates, un audit local et des assistants d'administration. Les fonctionnalités restent desktop-first et parlent directement à Active Directory via LDAP/LDAPS/Global Catalog.

**Tech Stack:** Object Pascal, Lazarus/FPC, mORMot2 LDAP, OpenRSATCore, OpenRSATGUI, stockage local JSON/SQLite si nécessaire pour templates/audit/config.

---

## Product Direction

Le produit cible n'est pas un clone web d'Adaxes. C'est une **console d'administration AD moderne** :

- navigation ADUC-like ;
- recherche forest-wide ;
- propriétés objets ;
- actions rapides ;
- bulk operations ;
- templates de provisioning ;
- audit local ;
- favoris/récents ;
- UX plus propre que RSAT classique ;
- packaging Windows propre.

Nom de travail : **OpenAdaxes Console**. Le nom final pourra changer pour éviter toute ambiguïté de marque.

---

## Non-Goals v1

Ces éléments sont explicitement hors périmètre au début :

- portail web ;
- self-service web ;
- backend serveur permanent ;
- agent Windows distant ;
- moteur complet d'approbation multi-acteurs ;
- copie pixel-perfect d'Adaxes ;
- marketplace de plugins ;
- synchronisation cloud.

---

## Current Repository Context

Repo local :

```text
/home/hoka/clawd/OpenRSAT
```

Branche actuelle de départ :

```text
feature/forest-global-catalog-search
```

État connu :

- recherche Global Catalog déjà implémentée ;
- ouverture/modification cross-domain déjà implémentée ;
- builds Linux et Windows x64 déjà validés dans ce workspace ;
- licence OpenRSAT : GPLv3.

Commandes de build validées :

```bash
export PATH=/home/hoka/src/lazarus-4.0:/home/hoka/local/bin:/home/hoka/local/usr/bin:$PATH
export LAZDIR=/home/hoka/src/lazarus-4.0
export PCP=/home/hoka/.lazarus-openrsat-laz4
cd /home/hoka/clawd/OpenRSAT
lazbuild --lazarusdir="$LAZDIR" --pcp="$PCP" --build-mode=linux-x64 sources/OpenRSAT.lpi
lazbuild --lazarusdir="$LAZDIR" --pcp="$PCP" --build-mode=win64 sources/OpenRSAT.lpi
```

---

## MVP Definition

Le MVP doit permettre à un admin AD de remplacer une partie de son usage Adaxes Console/RSAT pour les tâches quotidiennes.

### MVP Features

1. Console branding propre.
2. Recherche forest-wide robuste.
3. Panneau d'actions rapides sur utilisateur/groupe/OU.
4. Actions bulk sur utilisateurs et groupes.
5. Templates de création utilisateur.
6. Audit local des actions.
7. Favoris et objets récents.
8. Packaging Windows x64 livrable.

### MVP Acceptance Criteria

- L'application démarre sous Windows x64.
- Connexion à un domaine AD existant via profil OpenRSAT.
- Recherche d'utilisateurs dans un domaine et dans la forêt.
- Ouverture/modification d'un utilisateur trouvé via Global Catalog.
- Sélection multi-objets et action bulk simple.
- Création utilisateur depuis template.
- Export CSV des résultats de recherche.
- Audit local lisible depuis l'UI.
- Build reproductible et zip généré.

---

## Phase 0 — Hygiene, Branching, Build Baseline

### Task 0.1: Create product branch

**Objective:** Isoler le développement console Adaxes-like sur une branche dédiée.

**Files:**
- Modify: git branch only

**Steps:**

```bash
cd /home/hoka/clawd/OpenRSAT
git status --short --branch
git checkout -b feature/openadaxes-console
```

**Verification:**

```bash
git branch --show-current
```

Expected:

```text
feature/openadaxes-console
```

**Commit:** Aucun commit nécessaire.

---

### Task 0.2: Add implementation plan to repo

**Objective:** Versionner ce plan dans le repo.

**Files:**
- Create: `docs/plans/2026-05-05-openadaxes-console.md`

**Steps:**

```bash
git add docs/plans/2026-05-05-openadaxes-console.md
git commit -m "docs: add OpenAdaxes console implementation plan"
```

**Verification:**

```bash
git show --stat HEAD
```

Expected: le fichier du plan apparaît dans le commit.

---

### Task 0.3: Verify Linux and Windows builds before product changes

**Objective:** Confirmer que la baseline compile avant les changements produit.

**Files:**
- No source modification

**Steps:**

```bash
export PATH=/home/hoka/src/lazarus-4.0:/home/hoka/local/bin:/home/hoka/local/usr/bin:$PATH
export LAZDIR=/home/hoka/src/lazarus-4.0
export PCP=/home/hoka/.lazarus-openrsat-laz4
cd /home/hoka/clawd/OpenRSAT
lazbuild --lazarusdir="$LAZDIR" --pcp="$PCP" --build-mode=linux-x64 sources/OpenRSAT.lpi
lazbuild --lazarusdir="$LAZDIR" --pcp="$PCP" --build-mode=win64 sources/OpenRSAT.lpi
```

**Verification:**

```bash
file bin/linux-x64/OpenRSAT
file bin/win64/OpenRSAT.exe
```

Expected:

- Linux binary is ELF x86-64.
- Windows binary is PE32+ GUI x86-64.

---

## Phase 1 — Product Identity / Rebranding

### Task 1.1: Inventory product strings

**Objective:** Trouver les strings OpenRSAT visibles à l'utilisateur.

**Files:**
- Inspect: `sources/OpenRSAT.lpi`
- Inspect: `sources/OpenRSAT.lpr`
- Inspect: `packages/OpenRSATGUI/*.pas`
- Inspect: `packages/OpenRSATGUI/*.lfm`

**Steps:**

```bash
cd /home/hoka/clawd/OpenRSAT
python3 - <<'PY'
from pathlib import Path
for p in Path('.').rglob('*'):
    if p.suffix.lower() in ['.pas', '.lfm', '.lpi', '.lpr', '.rc', '.iss', '.spec', '.desktop']:
        try:
            s = p.read_text(errors='ignore')
        except Exception:
            continue
        if 'OpenRSAT' in s or 'RSAT' in s:
            print(p)
PY
```

**Verification:** Liste des fichiers impactés produite.

---

### Task 1.2: Add centralized product metadata unit

**Objective:** Créer une unité Pascal centralisant nom produit, version marketing et site projet.

**Files:**
- Create: `packages/OpenRSATCore/uopenadaxesbranding.pas`
- Modify: `packages/OpenRSATCore/OpenRSATCore.pas` if package file requires unit registration

**Implementation sketch:**

```pascal
unit uopenadaxesbranding;

{$mode ObjFPC}{$H+}

interface

const
  PRODUCT_NAME = 'OpenAdaxes Console';
  PRODUCT_SHORT_NAME = 'OpenAdaxes';
  PRODUCT_DESCRIPTION = 'Open-source Active Directory administration console';
  PRODUCT_WEBSITE = 'https://github.com/Hokasama/OpenRSAT';

implementation

end.
```

**Verification:** Linux build passes.

**Commit:**

```bash
git add packages/OpenRSATCore/uopenadaxesbranding.pas packages/OpenRSATCore/OpenRSATCore.pas
git commit -m "feat(branding): add product metadata constants"
```

---

### Task 1.3: Replace main window title with product metadata

**Objective:** Afficher le nouveau nom produit dans la fenêtre principale sans hardcoder partout.

**Files:**
- Modify: `packages/OpenRSATGUI/ufrmrsat.pas`
- Possibly modify: `packages/OpenRSATGUI/ufrmrsat.lfm`

**Steps:**

1. Add `uopenadaxesbranding` to the `uses` clause.
2. Set the main form caption from `PRODUCT_NAME` during form creation/show.
3. Avoid changing technical class names yet.

**Verification:**

```bash
lazbuild --lazarusdir="$LAZDIR" --pcp="$PCP" --build-mode=linux-x64 sources/OpenRSAT.lpi
```

**Commit:**

```bash
git add packages/OpenRSATGUI/ufrmrsat.pas packages/OpenRSATGUI/ufrmrsat.lfm
git commit -m "feat(branding): update main window title"
```

---

## Phase 2 — Console UX Shell

### Task 2.1: Add right-side action panel placeholder

**Objective:** Ajouter un panneau d'actions contextuelles type console Adaxes.

**Files:**
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.lfm`
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.pas`

**UI Concept:**

Panneau droit :

```text
Actions
- Properties
- Rename
- Move
- Add to group
- Disable account
- Reset password
- Export selection
```

**Implementation notes:**

- Utiliser un `TPanel` aligné à droite.
- Ajouter des `TButton` ou `TAction` liés aux actions existantes quand possible.
- Le panneau doit s'activer/désactiver selon la sélection.

**Verification:**

- Build Linux.
- L'app démarre.
- Le panneau apparaît sans casser l'ADUC tree/grid.

**Commit:**

```bash
git add packages/OpenRSATGUI/ufrmmoduleaduc.*
git commit -m "feat(ui): add contextual action panel placeholder"
```

---

### Task 2.2: Wire existing object actions into action panel

**Objective:** Réutiliser les actions existantes pour éviter la duplication.

**Files:**
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.pas`
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.lfm`

**Steps:**

1. Identifier les `TAction` existantes : properties, delete, rename, move, group membership si existant.
2. Relier les boutons du panneau aux `TAction` existantes.
3. Ajouter une méthode unique `UpdateActionPanelState`.
4. Appeler cette méthode lors des changements de sélection.

**Verification:**

- Sélection utilisateur : actions utilisateur visibles.
- Sélection groupe : actions groupe visibles.
- Pas de sélection : actions désactivées.

**Commit:**

```bash
git add packages/OpenRSATGUI/ufrmmoduleaduc.*
git commit -m "feat(ui): connect action panel to existing ADUC actions"
```

---

## Phase 3 — Fast Search and Forest Search Polish

### Task 3.1: Add search mode labels and safer defaults

**Objective:** Rendre évident quand une recherche est domaine vs forêt.

**Files:**
- Modify: `packages/OpenRSATGUI/uvissearch.pas`
- Modify: `packages/OpenRSATGUI/uvissearch.lfm`

**Steps:**

1. Ajouter un label d'état : `Domain search` / `Forest search via Global Catalog`.
2. Quand forest search est activé, limiter les attributs demandés aux attributs GC-safe.
3. Conserver l'ouverture propriété via LDAP domaine objet.

**Verification:**

- Build Linux.
- Le label change quand la checkbox `Search whole forest` change.

**Commit:**

```bash
git add packages/OpenRSATGUI/uvissearch.*
git commit -m "feat(search): clarify domain and forest search modes"
```

---

### Task 3.2: Add CSV export for search results

**Objective:** Permettre l'export de résultats de recherche, indispensable en console admin.

**Files:**
- Modify: `packages/OpenRSATGUI/uvissearch.pas`
- Modify: `packages/OpenRSATGUI/uvissearch.lfm`

**Implementation notes:**

- Ajouter action `Action_ExportCsv`.
- Ajouter bouton `Export CSV`.
- Exporter colonnes visibles du grid/list.
- Échapper correctement guillemets, virgules, retours ligne.

**CSV escaping helper sketch:**

```pascal
function CsvEscape(const Value: string): string;
begin
  Result := StringReplace(Value, '"', '""', [rfReplaceAll]);
  if (Pos(',', Result) > 0) or (Pos('"', Result) > 0) or
     (Pos(#10, Result) > 0) or (Pos(#13, Result) > 0) then
    Result := '"' + Result + '"';
end;
```

**Verification:**

- Search users.
- Export CSV.
- Open CSV manually and verify columns/rows.

**Commit:**

```bash
git add packages/OpenRSATGUI/uvissearch.*
git commit -m "feat(search): export search results to CSV"
```

---

## Phase 4 — Local Audit Log

### Task 4.1: Create audit model/unit

**Objective:** Enregistrer localement les actions sensibles faites depuis la console.

**Files:**
- Create: `packages/OpenRSATCore/uauditlog.pas`
- Modify: `packages/OpenRSATCore/OpenRSATCore.pas` if package registration needed

**Audit record fields:**

```text
TimestampUtc
Action
TargetDN
TargetClass
Username
Domain
Status
Details
ErrorMessage
```

**Storage v1:** JSON Lines file local.

Suggested path:

```text
<user config dir>/OpenAdaxes/audit.jsonl
```

**Implementation sketch:**

```pascal
procedure AppendAuditEvent(const Action, TargetDN, Status, Details: RawUtf8);
```

**Verification:** Unit compiles.

**Commit:**

```bash
git add packages/OpenRSATCore/uauditlog.pas packages/OpenRSATCore/OpenRSATCore.pas
git commit -m "feat(audit): add local audit log writer"
```

---

### Task 4.2: Audit property modifications

**Objective:** Logguer les modifications d'attributs depuis les propriétés objet.

**Files:**
- Inspect/Modify: property page units under `packages/OpenRSATGUI/`
- Likely Modify: object property save handler unit

**Steps:**

1. Identifier le handler exact qui applique les modifications LDAP.
2. Avant modification : capturer DN + attributs modifiés.
3. Après succès : `AppendAuditEvent('modify_object', DN, 'success', Details)`.
4. En cas d'erreur : log status `failure` avec message.

**Verification:**

- Modifier un attribut test.
- Vérifier présence ligne JSONL.
- Build Linux.

**Commit:**

```bash
git add packages/OpenRSATGUI/*.pas packages/OpenRSATCore/uauditlog.pas
git commit -m "feat(audit): record object property modifications"
```

---

### Task 4.3: Add audit viewer window

**Objective:** Lire l'audit depuis l'UI.

**Files:**
- Create: `packages/OpenRSATGUI/uvisauditlog.pas`
- Create: `packages/OpenRSATGUI/uvisauditlog.lfm`
- Modify: main menu/form to open it, likely `packages/OpenRSATGUI/ufrmrsat.*`

**UI:**

Colonnes :

- Time
- Action
- Target
- Status
- Details

Actions :

- Refresh
- Open log file
- Export CSV

**Verification:**

- Menu ouvre la fenêtre.
- Les lignes JSONL existantes apparaissent.

**Commit:**

```bash
git add packages/OpenRSATGUI/uvisauditlog.* packages/OpenRSATGUI/ufrmrsat.*
git commit -m "feat(audit): add audit log viewer"
```

---

## Phase 5 — Bulk Actions

### Task 5.1: Add selection abstraction for ADUC grid

**Objective:** Créer une méthode fiable qui retourne les DNs sélectionnés.

**Files:**
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.pas`

**Implementation concept:**

```pascal
function TFrmModuleADUC.GetSelectedObjectDNs: TRawUtf8DynArray;
```

**Verification:**

- Single selection returns one DN.
- Multi-selection returns all selected DNs.
- Empty selection returns empty array.

**Commit:**

```bash
git add packages/OpenRSATGUI/ufrmmoduleaduc.pas
git commit -m "feat(aduc): expose selected object DNs"
```

---

### Task 5.2: Add bulk disable users action

**Objective:** Première vraie action bulk avec confirmation.

**Files:**
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.pas`
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.lfm`
- Modify: `packages/OpenRSATCore/uauditlog.pas` if needed

**Behavior:**

1. User selects multiple users.
2. Click `Disable accounts`.
3. Confirmation dialog lists count and sample DNs.
4. App modifies `userAccountControl` to set disabled flag.
5. Each object gets audit event.
6. Summary dialog shows success/failure count.

**Important:** Preserve other `userAccountControl` flags. Only set `ACCOUNTDISABLE` bit.

**Verification:**

- Test on lab AD user only.
- Confirm disabled flag set.
- Confirm audit entries.

**Commit:**

```bash
git add packages/OpenRSATGUI/ufrmmoduleaduc.* packages/OpenRSATCore/uauditlog.pas
git commit -m "feat(bulk): disable selected user accounts"
```

---

### Task 5.3: Add bulk add-to-group action

**Objective:** Ajouter plusieurs users/groups/computers à un groupe.

**Files:**
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.pas`
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.lfm`
- Possibly Create: `packages/OpenRSATGUI/uvisselectgroup.pas/.lfm`

**Behavior:**

1. Select objects.
2. Click `Add to group`.
3. Dialog searches/selects target group.
4. Modify target group `member` attribute.
5. Log each add.

**Verification:**

- Add lab user to lab group.
- Re-open group membership and confirm.

**Commit:**

```bash
git add packages/OpenRSATGUI/* packages/OpenRSATCore/uauditlog.pas
git commit -m "feat(bulk): add selected objects to group"
```

---

### Task 5.4: Add bulk move action

**Objective:** Déplacer plusieurs objets vers une OU cible.

**Files:**
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.pas`
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.lfm`
- Possibly Create: OU picker dialog

**Behavior:**

1. Select objects.
2. Click `Move to OU`.
3. Select target OU.
4. Execute LDAP modify DN / move operation.
5. Refresh current view.
6. Audit success/failure.

**Verification:** Lab objects only.

**Commit:**

```bash
git add packages/OpenRSATGUI/* packages/OpenRSATCore/uauditlog.pas
git commit -m "feat(bulk): move selected objects to OU"
```

---

## Phase 6 — User Creation Templates

### Task 6.1: Create template storage unit

**Objective:** Stocker des templates de création utilisateur localement.

**Files:**
- Create: `packages/OpenRSATCore/uusertemplates.pas`
- Modify: `packages/OpenRSATCore/OpenRSATCore.pas` if package registration needed

**Template fields v1:**

```text
Name
TargetOU
UPNSuffix
SamAccountNamePattern
DisplayNamePattern
EmailPattern
DefaultGroups
EnabledByDefault
MustChangePasswordAtNextLogon
DefaultAttributes
```

**Storage:** JSON file local.

Suggested path:

```text
<user config dir>/OpenAdaxes/user-templates.json
```

**Verification:** Unit compiles and can load empty template list.

**Commit:**

```bash
git add packages/OpenRSATCore/uusertemplates.pas packages/OpenRSATCore/OpenRSATCore.pas
git commit -m "feat(templates): add user template storage"
```

---

### Task 6.2: Add template management dialog

**Objective:** Permettre de créer/modifier/supprimer des templates.

**Files:**
- Create: `packages/OpenRSATGUI/uvisusertemplates.pas`
- Create: `packages/OpenRSATGUI/uvisusertemplates.lfm`
- Modify: `packages/OpenRSATGUI/ufrmrsat.*` for menu entry

**UI v1:**

- List templates left.
- Form fields right.
- Buttons: New, Duplicate, Save, Delete.

**Verification:**

- Create a template.
- Restart app.
- Template persists.

**Commit:**

```bash
git add packages/OpenRSATGUI/uvisusertemplates.* packages/OpenRSATGUI/ufrmrsat.* packages/OpenRSATCore/uusertemplates.pas
git commit -m "feat(templates): add user template manager"
```

---

### Task 6.3: Add Create User From Template wizard

**Objective:** Créer un utilisateur AD depuis un template.

**Files:**
- Create: `packages/OpenRSATGUI/uviscreateuserfromtemplate.pas`
- Create: `packages/OpenRSATGUI/uviscreateuserfromtemplate.lfm`
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.*`
- Modify: `packages/OpenRSATCore/uusertemplates.pas`
- Modify: `packages/OpenRSATCore/uauditlog.pas`

**Wizard steps:**

1. Choose template.
2. Enter identity fields: first name, last name, login, password.
3. Preview computed attributes.
4. Confirm creation.
5. Create LDAP object.
6. Set password if supported.
7. Add default groups.
8. Audit all actions.

**Verification:**

- Create lab user.
- Confirm attributes.
- Confirm group membership.
- Confirm audit entries.

**Commit:**

```bash
git add packages/OpenRSATGUI/uviscreateuserfromtemplate.* packages/OpenRSATGUI/ufrmmoduleaduc.* packages/OpenRSATCore/uusertemplates.pas packages/OpenRSATCore/uauditlog.pas
git commit -m "feat(templates): create users from templates"
```

---

## Phase 7 — Favorites and Recent Objects

### Task 7.1: Add local favorites storage

**Objective:** Sauvegarder OUs/groupes/users favoris.

**Files:**
- Create: `packages/OpenRSATCore/ufavorites.pas`
- Modify: `packages/OpenRSATCore/OpenRSATCore.pas`

**Fields:**

```text
DN
DisplayName
ObjectClass
Domain
AddedAt
```

**Verification:** Unit compiles.

**Commit:**

```bash
git add packages/OpenRSATCore/ufavorites.pas packages/OpenRSATCore/OpenRSATCore.pas
git commit -m "feat(favorites): add local favorites storage"
```

---

### Task 7.2: Add favorites panel or menu

**Objective:** Accéder rapidement aux objets/OU fréquents.

**Files:**
- Modify: `packages/OpenRSATGUI/ufrmmoduleaduc.*`
- Possibly Create: `packages/OpenRSATGUI/uvisfavorites.pas/.lfm`

**Behavior:**

- Right click object -> Add to favorites.
- Menu/panel lists favorites.
- Click favorite -> focus/open object.

**Verification:**

- Add OU favorite.
- Restart app.
- Click favorite navigates to OU/object.

**Commit:**

```bash
git add packages/OpenRSATGUI/* packages/OpenRSATCore/ufavorites.pas
git commit -m "feat(favorites): add favorites UI"
```

---

### Task 7.3: Add recent objects tracking

**Objective:** Garder un historique des derniers objets ouverts/modifiés.

**Files:**
- Modify: `packages/OpenRSATCore/ufavorites.pas` or create `urecentobjects.pas`
- Modify: property/open handlers in GUI

**Behavior:**

- On object properties open, add/update recent entry.
- Keep max 50 entries.
- Show in menu/panel.

**Verification:** Open 3 objects, recent list shows them in order.

**Commit:**

```bash
git add packages/OpenRSATGUI/* packages/OpenRSATCore/*
git commit -m "feat(recent): track recently opened AD objects"
```

---

## Phase 8 — Safety Rails

### Task 8.1: Add confirmation helper for destructive/bulk actions

**Objective:** Standardiser les confirmations sensibles.

**Files:**
- Create: `packages/OpenRSATGUI/uconfirmbulkaction.pas`
- Create: `packages/OpenRSATGUI/uconfirmbulkaction.lfm`

**Behavior:**

- Shows action name.
- Shows object count.
- Shows first N DNs.
- Requires checkbox `I understand` for destructive operations.

**Verification:** Bulk disable uses the dialog.

**Commit:**

```bash
git add packages/OpenRSATGUI/uconfirmbulkaction.* packages/OpenRSATGUI/ufrmmoduleaduc.*
git commit -m "feat(safety): add reusable bulk action confirmation"
```

---

### Task 8.2: Add dry-run preview for bulk actions where possible

**Objective:** Réduire le risque d'erreur admin.

**Files:**
- Modify: bulk action handlers

**Behavior:**

- Show exact objects and target changes before execution.
- For group add: show target group and selected members.
- For move: show target OU.

**Verification:** Preview appears before any LDAP modify.

**Commit:**

```bash
git add packages/OpenRSATGUI/*
git commit -m "feat(safety): preview bulk LDAP changes before execution"
```

---

## Phase 9 — Packaging and Release Artifacts

### Task 9.1: Add Windows release packaging script

**Objective:** Générer un zip versionné automatiquement.

**Files:**
- Create: `scripts/package-win64.sh`

**Script:**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-dev}"
ARTIFACT_DIR="/home/hoka/artifacts"
EXE="$ROOT/bin/win64/OpenRSAT.exe"
OUT_EXE="$ARTIFACT_DIR/OpenAdaxes-Console-$VERSION-win64.exe"
OUT_ZIP="$ARTIFACT_DIR/OpenAdaxes-Console-$VERSION-win64.zip"

mkdir -p "$ARTIFACT_DIR"
cp -f "$EXE" "$OUT_EXE"
cd "$ARTIFACT_DIR"
zip -9 -q "$(basename "$OUT_ZIP")" "$(basename "$OUT_EXE")"
sha256sum "$OUT_EXE" "$OUT_ZIP"
```

**Verification:**

```bash
chmod +x scripts/package-win64.sh
./scripts/package-win64.sh mvp0
```

Expected: zip and sha256 in `/home/hoka/artifacts`.

**Commit:**

```bash
git add scripts/package-win64.sh
git commit -m "build: add Windows release packaging script"
```

---

### Task 9.2: Add MVP release notes

**Objective:** Documenter ce qui est livré et ce qui ne l'est pas.

**Files:**
- Create: `docs/releases/mvp0.md`

**Content should include:**

- Features included.
- Known limitations.
- Tested platforms.
- Build hash.
- Artifact hash.

**Commit:**

```bash
git add docs/releases/mvp0.md
git commit -m "docs: add MVP0 release notes"
```

---

## Phase 10 — Validation Matrix

### Task 10.1: Create manual AD lab test checklist

**Objective:** Avoir une checklist claire pour valider sur vrai AD/lab AD.

**Files:**
- Create: `docs/testing/ad-lab-checklist.md`

**Checklist:**

```markdown
# AD Lab Checklist

## Connection
- [ ] Connect with explicit credentials
- [ ] Connect with current Windows credentials if applicable
- [ ] Connect via LDAPS

## Search
- [ ] Search user by sAMAccountName prefix
- [ ] Search user by UPN prefix
- [ ] Forest search via GC
- [ ] Open cross-domain object properties

## Object actions
- [ ] Modify description
- [ ] Disable lab user
- [ ] Enable lab user
- [ ] Add lab user to lab group
- [ ] Remove lab user from lab group
- [ ] Move lab user to another OU

## Templates
- [ ] Create user from template
- [ ] Validate default groups
- [ ] Validate password flags

## Audit
- [ ] Modify action logged
- [ ] Bulk action logged
- [ ] Template creation action logged
- [ ] Failed action logged
```

**Commit:**

```bash
git add docs/testing/ad-lab-checklist.md
git commit -m "docs: add AD lab validation checklist"
```

---

## Implementation Order Summary

Recommended coding order:

1. Baseline branch + build.
2. Branding constants and window title.
3. Action panel placeholder.
4. Wire existing actions.
5. Polish search UI and CSV export.
6. Audit writer.
7. Audit property modifications.
8. Audit viewer.
9. Selected DNs abstraction.
10. Bulk disable users.
11. Bulk add-to-group.
12. Bulk move.
13. Template storage.
14. Template manager.
15. Create user from template.
16. Favorites.
17. Recent objects.
18. Safety confirmation dialog.
19. Packaging script.
20. Release notes + validation checklist.

---

## Build Verification Command

Run after every meaningful task:

```bash
export PATH=/home/hoka/src/lazarus-4.0:/home/hoka/local/bin:/home/hoka/local/usr/bin:$PATH
export LAZDIR=/home/hoka/src/lazarus-4.0
export PCP=/home/hoka/.lazarus-openrsat-laz4
cd /home/hoka/clawd/OpenRSAT
lazbuild --lazarusdir="$LAZDIR" --pcp="$PCP" --build-mode=linux-x64 sources/OpenRSAT.lpi
```

Run before delivery:

```bash
lazbuild --lazarusdir="$LAZDIR" --pcp="$PCP" --build-mode=win64 sources/OpenRSAT.lpi
./scripts/package-win64.sh mvp0
```

---

## Risk Register

### Risk: Lazarus UI edits break `.lfm`

**Mitigation:** Small UI commits, compile after each change, avoid mass edits.

### Risk: LDAP operations differ across AD versions

**Mitigation:** Validate on lab AD, log precise LDAP errors, avoid destructive default actions.

### Risk: Bulk actions can damage real directory

**Mitigation:** Confirmation dialogs, previews, audit, lab-first validation.

### Risk: Global Catalog missing attributes

**Mitigation:** Use GC only for search/location. Use normal LDAP for properties/modifications.

### Risk: GPLv3 implications

**Mitigation:** Keep project open-source GPLv3-compatible unless rewritten from scratch later.

---

## First Coding Target

The first implementation sprint should be:

1. Create branch `feature/openadaxes-console`.
2. Commit this plan.
3. Verify build.
4. Add branding metadata.
5. Update main window title.
6. Add packaging script.

This gives a clean foundation and a deliverable artifact before touching risky AD operations.
