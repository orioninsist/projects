#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INDEX_FILE="projects-index.md"
LINK_LIST_FILE="projects-index-link.md"
LOCAL_LINK_LIST_FILE="projects-index-link.local.md"

touch "$INDEX_FILE" "$LINK_LIST_FILE"

provider_name() {
  local url="$1"
  case "$url" in
    *github.com*) printf "GitHub" ;;
    *gitlab*) printf "GitLab" ;;
    *bitbucket.org*) printf "Bitbucket" ;;
    "") printf "No Link" ;;
    *) printf "Other" ;;
  esac
}

remote_url_for_dir() {
  local dir="$1"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" remote get-url origin 2>/dev/null || true
  fi
}

collect_projects_tsv() {
  local dir name url provider
  for dir in */; do
    [[ -d "$dir" ]] || continue
    name="${dir%/}"
    [[ "$name" == ".git" ]] && continue
    url="$(remote_url_for_dir "$name")"
    provider="$(provider_name "$url")"
    printf "%s\t%s\t%s\n" "$provider" "$name" "$url"
  done | sort -f -k1,1 -k2,2
}

existing_comment_state() {
  local link="$1"
  [[ -f "$LOCAL_LINK_LIST_FILE" ]] || return 0
  if awk -v link="$link" '
    $0 ~ /^# [0-9]+\. / {
      line = $0
      sub(/^# [0-9]+\. /, "", line)
      sub(/^</, "", line)
      sub(/>$/, "", line)
      if (line == link) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$LOCAL_LINK_LIST_FILE" 2>/dev/null; then
    printf "# "
  fi
  return 0
}

write_if_changed() {
  local source="$1" target="$2"
  if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
    rm -f "$source"
  else
    mv "$source" "$target"
  fi
}

ensure_local_link_list() {
  [[ -f "$LOCAL_LINK_LIST_FILE" ]] && return 0
  cp "$LINK_LIST_FILE" "$LOCAL_LINK_LIST_FILE"
  chmod a+rw "$LOCAL_LINK_LIST_FILE"
}

refresh_files() {
  local tmp index_tmp link_tmp local_tmp projects_count links_count provider name url current_provider prefix
  tmp="$(mktemp)"
  index_tmp="$(mktemp)"
  link_tmp="$(mktemp)"
  local_tmp="$(mktemp)"
  collect_projects_tsv > "$tmp"
  projects_count="$(wc -l < "$tmp" | tr -d ' ')"
  links_count="$(awk -F '\t' '$3 != "" { c++ } END { print c + 0 }' "$tmp")"

  {
    printf "# Projects Index\n\n"
    printf "Short index of first-level project folders in this directory.\n\n"
    printf -- "- Directory: \`%s\`\n" "$SCRIPT_DIR"
    printf -- "- Total projects: %s\n" "$projects_count"
    printf -- "- Projects with clone links: %s\n\n" "$links_count"

    current_provider=""
    local number=0
    while IFS=$'\t' read -r provider name url; do
      [[ -n "$name" ]] || continue
      if [[ "$provider" != "$current_provider" ]]; then
        if [[ -n "$current_provider" ]]; then
          printf "\n"
        fi
        current_provider="$provider"
        printf "## %s\n\n" "$current_provider"
        printf "| # | Project | Clone link |\n"
        printf "|---:|---|---|\n"
      fi
      number=$((number + 1))
      if [[ -n "$url" ]]; then
        printf "| %s | %s | [%s](%s) |\n" "$number" "$name" "$url" "$url"
      else
        printf "| %s | %s | No link found |\n" "$number" "$name"
      fi
    done < "$tmp"
  } > "$index_tmp"

  {
    printf "# Project Clone Links\n\n"
    printf "Clean clone URL list. Local comment changes are kept in \`%s\` and are not committed.\n\n" "$LOCAL_LINK_LIST_FILE"
    local number=0
    while IFS=$'\t' read -r _provider _name url; do
      [[ -n "$url" ]] || continue
      number=$((number + 1))
      printf "%s. <%s>\n" "$number" "$url"
    done < "$tmp"
  } > "$link_tmp"

  {
    printf "# Local Project Clone Links\n\n"
    printf "Ignored local working list. Lines starting with \`#\` are skipped by option 4.\n\n"
    local number=0
    while IFS=$'\t' read -r _provider _name url; do
      [[ -n "$url" ]] || continue
      number=$((number + 1))
      prefix="$(existing_comment_state "$url")"
      if [[ -n "$prefix" ]]; then
        printf "# %s. <%s>\n" "$number" "$url"
      else
        printf "%s. <%s>\n" "$number" "$url"
      fi
    done < "$tmp"
  } > "$local_tmp"

  write_if_changed "$index_tmp" "$INDEX_FILE"
  write_if_changed "$link_tmp" "$LINK_LIST_FILE"
  write_if_changed "$local_tmp" "$LOCAL_LINK_LIST_FILE"
  chmod a+rw "$LOCAL_LINK_LIST_FILE"
  rm -f "$tmp"
  printf "\nRefresh complete.\n"
  printf -- "- %s: %s projects, %s links\n" "$INDEX_FILE" "$projects_count" "$links_count"
  printf -- "- %s: clean tracked clone list\n" "$LINK_LIST_FILE"
  printf -- "- %s: ignored local clone list, manual comments preserved\n" "$LOCAL_LINK_LIST_FILE"
}

comment_all_links() {
  local tmp
  ensure_local_link_list
  tmp="$(mktemp)"
  awk '
    /^[[:space:]]*$/ || /^<!--/ || /^# / { print; next }
    /^[0-9]+\. / { print "# " $0; next }
    { print }
  ' "$LOCAL_LINK_LIST_FILE" > "$tmp"
  write_if_changed "$tmp" "$LOCAL_LINK_LIST_FILE"
  chmod a+rw "$LOCAL_LINK_LIST_FILE"
  printf "\nAll local clone links were commented out: %s\n" "$LOCAL_LINK_LIST_FILE"
}

uncomment_all_links() {
  local tmp
  ensure_local_link_list
  tmp="$(mktemp)"
  sed -E 's/^# ([0-9]+\. )/\1/' "$LOCAL_LINK_LIST_FILE" > "$tmp"
  write_if_changed "$tmp" "$LOCAL_LINK_LIST_FILE"
  chmod a+rw "$LOCAL_LINK_LIST_FILE"
  printf "\nAll local clone links were uncommented: %s\n" "$LOCAL_LINK_LIST_FILE"
}

repo_name_from_url() {
  local url="$1" name
  name="${url##*/}"
  name="${name%.git}"
  printf "%s" "$name"
}

clone_selected_links() {
  local line url repo_name cloned=0 skipped=0 failed=0
  ensure_local_link_list
  printf "\nClone started. Only uncommented links will be used.\n"
  while IFS= read -r line; do
    [[ "$line" =~ ^[0-9]+\.\  ]] || continue
    url="${line#*. }"
    url="${url#<}"
    url="${url%>}"
    [[ -n "$url" ]] || continue
    repo_name="$(repo_name_from_url "$url")"
    if [[ -e "$repo_name" ]]; then
      printf -- "- Skipped, already exists: %s\n" "$repo_name"
      skipped=$((skipped + 1))
      continue
    fi
    printf -- "- Cloning: %s\n" "$url"
    if git clone "$url"; then
      cloned=$((cloned + 1))
    else
      printf "  Error: could not clone %s\n" "$url"
      failed=$((failed + 1))
    fi
  done < "$LOCAL_LINK_LIST_FILE"
  printf "\nClone result: %s cloned, %s skipped, %s failed.\n" "$cloned" "$skipped" "$failed"
}

add_ignore_backup_files() {
  local dir name target total=0 created=0 existing=0 failed=0
  printf "\n.ignore-backup check started.\n"
  printf "Directory: %s\n\n" "$SCRIPT_DIR"

  for dir in */; do
    [[ -d "$dir" ]] || continue
    name="${dir%/}"
    [[ "$name" == ".git" ]] && continue
    total=$((total + 1))
    target="$name/.ignore-backup"

    if [[ -e "$target" ]]; then
      printf -- "- Exists, unchanged: %s\n" "$target"
      existing=$((existing + 1))
      continue
    fi

    if : > "$target"; then
      printf -- "- Added: %s\n" "$target"
      created=$((created + 1))
    else
      printf -- "- Error, could not add: %s\n" "$target"
      failed=$((failed + 1))
    fi
  done

  printf "\n.ignore-backup result: %s folders checked, %s added, %s already existed, %s failed.\n" "$total" "$created" "$existing" "$failed"
}

print_menu() {
  cat <<MENU

Projects Index
Directory: $SCRIPT_DIR

1) Refresh the directory scan and update the index files
2) Comment out every clone link in the ignored local list
3) Uncomment every clone link in the ignored local list
4) Clone uncommented local links into this directory
5) Add .ignore-backup to all first-level project folders
0) Exit

MENU
}

main() {
  while true; do
    print_menu
    read -r -p "Secim: " choice
    case "$choice" in
      1) refresh_files ;;
      2) comment_all_links ;;
      3) uncomment_all_links ;;
      4) clone_selected_links ;;
      5) add_ignore_backup_files ;;
      0) printf "\nExited.\n"; exit 0 ;;
      *) printf "\nInvalid choice: %s\n" "$choice" ;;
    esac
  done
}

main "$@"
