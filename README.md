# Projects

This repository tracks the first-level project folders under `/mnt/local/projects`.

It does not track the projects themselves. The `.gitignore` file keeps Git focused on this small index repository: the script, the generated Markdown indexes, this README, and `.gitignore`.

## Files

- [projects-index.md](projects-index.md): short project index grouped by provider, with clickable clone links.
- [projects-index-link.md](projects-index-link.md): clean tracked clone URL list.
- [projects-index.sh](projects-index.sh): refreshes the index files and can clone uncommented links.

The script keeps local clone selections in `projects-index-link.local.md`. That file is ignored by Git, so option `2`, option `3`, and manual comment changes do not enter commits.

## Usage

```bash
chmod +x projects-index.sh
./projects-index.sh
```

Use option `1` to refresh the tracked Markdown files.

## Menu Options

The script never runs `git add`, `git commit`, or `git push`.

1. `Refresh the directory scan and update the index files`
   Updates [projects-index.md](projects-index.md) and [projects-index-link.md](projects-index-link.md). This creates a Git-visible change only when the real project list or clone links changed.

2. `Comment out every clone link in the ignored local list`
   Comments every link in `projects-index-link.local.md`. This file is ignored by Git, so it is not committed.

3. `Uncomment every clone link in the ignored local list`
   Uncomments every link in `projects-index-link.local.md`. This file is ignored by Git, so it is not committed.

4. `Clone uncommented local links into this directory`
   Reads `projects-index-link.local.md` and clones only uncommented links. Project folders are ignored by Git, so cloned repositories are not committed here.

5. `Add .ignore-backup to all first-level project folders`
   Adds `.ignore-backup` inside project folders only when missing. Project folders are ignored by Git, so these local files are not committed here.

0. `Exit`
   Exits the menu without changing tracked files.
