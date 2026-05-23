#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INDEX_FILE="projects-main-folder-structure-index.md"
LINK_LIST_FILE="projects-main-folder-structure-link-list.md"

touch "$INDEX_FILE" "$LINK_LIST_FILE"

provider_name() {
  local url="$1"
  case "$url" in
    *github.com*) printf "GitHub" ;;
    *gitlab.com*) printf "GitLab" ;;
    *bitbucket.org*) printf "Bitbucket" ;;
    "") printf "Link Yok" ;;
    *) printf "Diger" ;;
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
  if grep -Fqx "# $link" "$LINK_LIST_FILE" 2>/dev/null || grep -Fqx "#$link" "$LINK_LIST_FILE" 2>/dev/null; then
    printf "# "
  fi
}

refresh_files() {
  local tmp projects_count links_count provider name url current_provider prefix
  tmp="$(mktemp)"
  collect_projects_tsv > "$tmp"
  projects_count="$(wc -l < "$tmp" | tr -d ' ')"
  links_count="$(awk -F '\t' '$3 != "" { c++ } END { print c + 0 }' "$tmp")"

  {
    printf "# Projects Main Folder Structure Index\n\n"
    printf -- "- Dizin: \`%s\`\n" "$SCRIPT_DIR"
    printf -- "- Toplam proje klasoru: %s\n" "$projects_count"
    printf -- "- Git clone linki bulunan proje: %s\n" "$links_count"
    printf -- "- Son guncelleme: %s\n\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"

    current_provider=""
    local number=0
    while IFS=$'\t' read -r provider name url; do
      [[ -n "$name" ]] || continue
      if [[ "$provider" != "$current_provider" ]]; then
        current_provider="$provider"
        printf "## %s\n\n" "$current_provider"
      fi
      number=$((number + 1))
      printf "### %s. %s\n\n" "$number" "$name"
      if [[ -n "$url" ]]; then
        printf -- "- Clone link: \`%s\`\n\n" "$url"
      else
        printf -- "- Clone link: bulunamadi\n\n"
      fi
    done < "$tmp"
  } > "$INDEX_FILE"

  {
    printf "# Projects Main Folder Structure Link List\n\n"
    printf "<!-- Basinda # olan linkler 4. asamada indirilmez. -->\n\n"
    local number=0
    while IFS=$'\t' read -r _provider _name url; do
      [[ -n "$url" ]] || continue
      number=$((number + 1))
      prefix="$(existing_comment_state "$url")"
      printf "%s%s- %s\n" "$prefix" "$number" "$url"
    done < "$tmp"
  } > "$LINK_LIST_FILE"

  rm -f "$tmp"
  printf "\nGuncelleme tamamlandi.\n"
  printf -- "- %s: %s proje, %s link\n" "$INDEX_FILE" "$projects_count" "$links_count"
  printf -- "- %s: manuel yorum durumlari korunarak yenilendi\n" "$LINK_LIST_FILE"
}

comment_all_links() {
  local tmp
  tmp="$(mktemp)"
  awk '
    /^[[:space:]]*$/ || /^<!--/ || /^# / { print; next }
    /^[0-9]+- / { print "# " $0; next }
    { print }
  ' "$LINK_LIST_FILE" > "$tmp"
  mv "$tmp" "$LINK_LIST_FILE"
  chmod a+rw "$LINK_LIST_FILE"
  printf "\nTum linkler yorum satiri yapildi: %s\n" "$LINK_LIST_FILE"
}

uncomment_all_links() {
  local tmp
  tmp="$(mktemp)"
  sed -E 's/^# ([0-9]+- )/\1/' "$LINK_LIST_FILE" > "$tmp"
  mv "$tmp" "$LINK_LIST_FILE"
  chmod a+rw "$LINK_LIST_FILE"
  printf "\nTum link yorumlari kaldirildi: %s\n" "$LINK_LIST_FILE"
}

repo_name_from_url() {
  local url="$1" name
  name="${url##*/}"
  name="${name%.git}"
  printf "%s" "$name"
}

clone_selected_links() {
  local line url repo_name cloned=0 skipped=0 failed=0
  printf "\nIndirme basliyor. Yorum satiri olmayan linkler kullanilacak.\n"
  while IFS= read -r line; do
    [[ "$line" =~ ^[0-9]+-\  ]] || continue
    url="${line#*- }"
    [[ -n "$url" ]] || continue
    repo_name="$(repo_name_from_url "$url")"
    if [[ -e "$repo_name" ]]; then
      printf -- "- Atlandi, zaten var: %s\n" "$repo_name"
      skipped=$((skipped + 1))
      continue
    fi
    printf -- "- Klonlaniyor: %s\n" "$url"
    if git clone "$url"; then
      cloned=$((cloned + 1))
    else
      printf "  Hata: %s indirilemedi\n" "$url"
      failed=$((failed + 1))
    fi
  done < "$LINK_LIST_FILE"
  printf "\nIndirme sonucu: %s klonlandi, %s atlandi, %s hata.\n" "$cloned" "$skipped" "$failed"
}

add_ignore_backup_files() {
  local dir name target total=0 created=0 existing=0 failed=0
  printf "\n.ignore-backup kontrolu basliyor.\n"
  printf "Islem dizini: %s\n\n" "$SCRIPT_DIR"

  for dir in */; do
    [[ -d "$dir" ]] || continue
    name="${dir%/}"
    [[ "$name" == ".git" ]] && continue
    total=$((total + 1))
    target="$name/.ignore-backup"

    if [[ -e "$target" ]]; then
      printf -- "- Var, dokunulmadi: %s\n" "$target"
      existing=$((existing + 1))
      continue
    fi

    if : > "$target"; then
      printf -- "- Eklendi: %s\n" "$target"
      created=$((created + 1))
    else
      printf -- "- Hata, eklenemedi: %s\n" "$target"
      failed=$((failed + 1))
    fi
  done

  printf "\n.ignore-backup sonucu: %s klasor kontrol edildi, %s yeni eklendi, %s zaten vardi, %s hata.\n" "$total" "$created" "$existing" "$failed"
}

print_menu() {
  cat <<MENU

Projects Main Folder Structure
Dizin: $SCRIPT_DIR

1) Dizin taramasini yenile, index ve link listesini olustur
2) Link listesindeki tum linkleri yorum satiri yap
3) Link listesindeki tum yorumlari kaldir
4) Yorum satiri olmayan linkleri bu dizine git clone ile indir
5) Tum ana klasorlere .ignore-backup dosyasi ekle
0) Cikis

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
      0) printf "\nCikis yapildi.\n"; exit 0 ;;
      *) printf "\nGecersiz secim: %s\n" "$choice" ;;
    esac
  done
}

main "$@"
