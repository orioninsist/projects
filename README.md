# Projects

This repository tracks the first-level project folders under `/mnt/local/projects`.

It does not track the projects themselves. The `.gitignore` file keeps Git focused on this small index repository: the script, the generated Markdown indexes, this README, and `.gitignore`.

## Files

- [projects-index.md](projects-index.md): short project index grouped by provider, with clickable clone links.
- [projects-index-link.md](projects-index-link.md): clean clone URL list for copying or cloning.
- [projects-index.sh](projects-index.sh): refreshes the index files and can clone uncommented links.

## Usage

```bash
chmod +x projects-index.sh
./projects-index.sh
```

Use option `1` to refresh both Markdown files.
