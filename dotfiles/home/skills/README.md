# Codex skills

Skill folders in this directory are tracked snapshots of user-level skills from
`~/.agents/skills`. Home Manager links each folder into that global Codex skill
directory on every machine using these dotfiles.

To import or update an upstream skill, install it into the user directory and
then run `scripts/sync-codex-skills.sh`. The desktop settings sync script also
runs the skill sync step.

`material-3` comes from <https://github.com/hamen/material-3-skill>.
