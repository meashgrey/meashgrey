# NixOS desktop configuration

The flake configures the `nixos` host and the `ashgrey` Home Manager user.
Copy the contents of this directory to `/etc/nixos`, then run
`sudo nixos-rebuild build --flake /etc/nixos#nixos` before switching.

## Codex

System defaults, including the status line, live in `/etc/codex/config.toml`.
Codex can write `~/.codex/config.toml` for interactive preferences, MCP
servers, and project trust. User settings override the system defaults; remove
an overriding user setting to restore its Nix-managed default. Keep credentials
and user state out of this repository and the Nix store.

On the first switch from the former Home Manager-managed config, Home Manager
should remove its old symlink. If it remains, verify it points to a Home
Manager store path and remove that symlink before using `/statusline`. Preserve
any regular user config file; do not remove it.

## Niri and DMS

The files under `home/niri/` and `home/dms/settings.json` are initial defaults.
Home Manager copies them only when the corresponding target does not exist.
Existing files and symlinks, including dangling symlinks, are left untouched
on activation and rollback. DMS and Niri can modify their files normally;
rebuilding does not undo those changes. To update the defaults for future
installations, run the synchronization script as the desktop user:

```sh
~/Projects/nixos-dotfiles/scripts/sync-desktop-config.sh --dry-run
~/Projects/nixos-dotfiles/scripts/sync-desktop-config.sh
```

The script copies the Niri config and five included DMS fragments, DMS
settings, and the Fcitx5 profile into this repository, then requests sudo
authorization and copies the repository into `/etc/nixos` (excluding `.git`
and the `result` build link). Existing files with matching names are replaced;
unrelated files in `/etc/nixos` are retained. `--dry-run` only reports changes
and does not request sudo or copy files. The script respects `XDG_CONFIG_HOME`,
skips missing files without deleting the old seeds, and stops before deployment
if any are missing. It does not run a rebuild or back up learned data and
session state. Review its changes,
especially monitor settings, paths, and the Fcitx5 input method list. If
MSIME has not yet been added to the live profile, syncing that profile will
replace the repository's MSIME default with the current list.

The dynamically generated `home/niri/dms/colors.kdl` is excluded from the
sync script. Its tracked copy is a first-install seed; DMS updates the live
file when the theme changes. Generated Matugen output and `bibata-cursor.kdl`
also stay in the user configuration directory. Templates and the Bibata
preset palette remain in the repository so the setup can be reproduced.

The `home/niri/dms/*.kdl` files are initial seeds for the includes in
`config.kdl`. DMS manages the live copies thereafter.
For example, display settings changed through DMS are machine-specific and are
not reapplied from the repository on every activation. To reproduce such a
change on a fresh machine, update the corresponding seed in the repository.

DMS stores wallpaper selection and cycling state separately in
`~/.local/state/dms/session.json`; that state and wallpaper images are not
managed here. Back them up separately to reproduce the current wallpaper.
Do not copy the whole session file into the repository without reviewing it,
because it can contain machine-specific and private state.

For the latest desktop settings on a new device, back up and restore the
relevant writable user data separately: `~/.config/niri/`, `~/.config/dms/`
(or `~/.config/DankMaterialShell/`), `~/.config/fcitx5/`,
`~/.local/share/fcitx5/`, `~/.config/msime-client/`,
`~/.local/share/msime-client/`, the DMS session state, and any wallpapers.
Some paths may not exist until a feature is used. Restore user data only from
a trusted backup, before starting the corresponding applications, and review
machine-specific monitor settings and absolute paths on the new device.
These directories may contain private data: encrypt backups and do not commit
credentials or learned dictionaries to a public repository. A Git repository
or flake alone does not contain or automatically back up those live changes.

## Fcitx5 and MSIME

WeTypeX is installed alongside MSIME through the locked `wetypex` flake input.
Its theme integration is disabled so it does not take over Fcitx5's shared
candidate-window theme. Existing input-method profiles are not overwritten.
After switching the system, prepare the official runtime as the desktop user:

```sh
# Use a copy of the official archive obtained and accepted by the user:
fcitx5-wetypex-setup --archive /path/to/WeType_2.2.3_657.zip
fcitx5-wetypex-setup --check
```

Alternatively, after reviewing and accepting the upstream license, use
`fcitx5-wetypex-setup --download --accept-upstream-license`. Restart the
desktop session, then add WeTypeX in Fcitx5 Configuration. The runtime and
user data stay in `~/.local/share/fcitx5-wetypex/`; the settings are under
`~/.config/fcitx5/`. They are not included in this repository or flake.

Fcitx5 and its addons are managed by NixOS. The MSIME upstream NixOS module
installs the Fcitx5 plugin, setup command, and provider user units. The
user's input method group is seeded from `home/fcitx5/profile` only if no
profile exists. The seed includes US keyboard, MSIME (default), WeTypeX, and
Mozc. An existing profile is left intact, so newly installed input methods
may need to be added in Fcitx5 Configuration. General Fcitx5 settings, learned dictionaries and
DMS-generated themes remain user data and are not reset by this configuration.

MSIME's source revision is pinned in `flake.nix` and all flake inputs are
locked in `flake.lock`. Keep the repository and `/etc/nixos` lock files in
sync: after updating inputs in `/etc/nixos`, copy its `flake.lock` back to this
repository before deploying the repository again. Otherwise deployment can
replace a newer lock with an older one. To upgrade MSIME, deliberately change
the pinned revision and update the lock. Updating nixpkgs can still cause an
MSIME rebuild because the Fcitx5 plugin uses the system's nixpkgs.

After adding the new flake input, update its lock on a machine with network
and Nix daemon access before building:

```sh
cd /etc/nixos
sudo nix flake lock
sudo nixos-rebuild build --flake /etc/nixos#nixos
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

Log out and back in so Fcitx5 loads the newly built plugin. Then run as the
desktop user (not root):

```sh
msime-linux-setup --download
```

The first setup downloads MSIME's dictionaries into the user's data directory
and creates user runtime state; these are not included in the flake. Back up
MSIME's user configuration and learned data separately. After future system
switches, log out and back in, or run `fcitx5 -rd` from a newly opened terminal.
