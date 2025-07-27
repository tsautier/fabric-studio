#!/usr/bin/env bash
# update_repo.sh: manage firmware/template in remote repo via SSH/SCP
# Usage: see usage() below

set -euo pipefail

# Configuration
SERVER="10.7.80.20"
#BASE_DIR="/var/www/fabric/prod"
BASE_DIR="/srv/fsrepo/html/prod"

# Print help
usage() {
  cat <<EOF
Usage: $0 {list|delete|add|update} {firmware|template} [args...]

Commands:
  list <firmware|template>
      List contents of remote directory in a formatted table

  delete <firmware|template> <file1> [file2 ...]
      Delete specified file(s) from remote directory

  add <firmware|template> <file1> [file2 ...]
      Upload local file(s) to remote directory. Filenames not starting with your SSH username
      will be automatically prefixed with "<username>_".

  update <firmware|template> <remote_file> <local_file>
      Replace a single remote file with a new local file. Both must start with your SSH username;
      missing prefixes will be added automatically.

Examples:
  $0 list firmware
  $0 delete template alice_config1
  $0 add firmware alice_fw1.bin alice_fw2.bin
  $0 update template alice_template1.cfg new_template.cfg
EOF
}

# Validate minimal args
if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

action="$1"
# Normalize type to lowercase (portable across Bash versions)
type="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"
shift 2


# Determine remote directory
case "$type" in
  firmware)
    DIR="$BASE_DIR/firmwares"
    ;;
  template)
    DIR="$BASE_DIR/templates"
    ;;
  *)
    echo "Error: unknown type '$type'" >&2
    usage
    exit 1
    ;;
esac

# Prompt for remote user
read -rp "Remote SSH/SCP username: " REMOTE_USER

# Helper: prefix filenames if missing username
prefixed() {
  local name="$1"
  if [[ "$name" != "$REMOTE_USER"* ]]; then
    echo "${REMOTE_USER}_${name}"
  else
    echo "$name"
  fi
}

# Execute actions
case "$action" in
  list)
    if [[ $# -ne 0 ]]; then
      echo "Error: 'list' takes no additional arguments" >&2
      usage
      exit 1
    fi
    # Fetch and format listing: Owner, Filename, Modified Date, Size (MB)
    ssh "${REMOTE_USER}@${SERVER}" "ls -l --time-style='+%Y-%m-%d %H:%M:%S' '${DIR}'" | \
    awk '
    NR==2 {
      printf "%-15s | %-50s | %-19s | %10s\n", "Owner", "Filename", "Modified", "Size(MB)";
      printf "%-15s-+-%-50s-+-%-19s-+-%10s\n", "---------------", "--------------------------------------------------", "-------------------", "----------";
    }
    NR>1 {
      size=$5/1024/1024;
      printf "%-15s | %-50s | %-19s | %10.2f\n", $3, $8, $6" "$7, size;
    }'
    ;;

  delete)
    if [[ $# -lt 1 ]]; then
      echo "Error: 'delete' requires at least one filename" >&2
      usage
      exit 1
    fi
    for fname in "$@"; do
      remote_name=$(prefixed "$(basename "$fname")")
      ssh "${REMOTE_USER}@${SERVER}" "rm -f '${DIR}/${remote_name}'" || {
        echo "Failed to delete ${remote_name}" >&2
        exit 1
      }
    done
    ssh "${REMOTE_USER}@${SERVER}" "/opt/ftnt/bin/fprepo refresh '${BASE_DIR}'" || {
      echo "Failed to run fprepo command to update repository" >&2
      exit 1
    }
    ;;

  add)
    if [[ $# -lt 1 ]]; then
      echo "Error: 'add' requires at least one local filename" >&2
      usage
      exit 1
    fi
    for localpath in "$@"; do
      if [[ ! -f "$localpath" ]]; then
        echo "Local file not found: $localpath" >&2
        exit 1
      fi
      base=$(basename "$localpath")
      remote_name=$(prefixed "$base")
      scp "$localpath" "${REMOTE_USER}@${SERVER}:${DIR}/${remote_name}" || {
        echo "Failed to upload ${localpath}" >&2
        exit 1
      }
    done
    ssh "${REMOTE_USER}@${SERVER}" "/opt/ftnt/bin/fprepo refresh '${BASE_DIR}'" || {
      echo "Failed to run fprepo command to update repository" >&2
      exit 1
    }
    ;;

  update)
    if [[ $# -ne 2 ]]; then
      echo "Error: 'update' requires exactly two arguments: <remote_file> <local_file>" >&2
      usage
      exit 1
    fi
    remote_arg="$1"
    localpath="$2"
    if [[ ! -f "$localpath" ]]; then
      echo "Local file not found: $localpath" >&2
      exit 1
    fi
    remote_name=$(prefixed "$(basename "$remote_arg")")
    base_local=$(basename "$localpath")
    local_name=$(prefixed "$base_local")
    temp_local="$localpath"
    if [[ "$base_local" != "$local_name" ]]; then
      temp_local="/tmp/${local_name}"
      cp "$localpath" "$temp_local"
    fi
    scp "$temp_local" "${REMOTE_USER}@${SERVER}:${DIR}/${remote_name}" || {
      echo "Failed to upload ${local_name}" >&2
      exit 1
    }
    if [[ "$temp_local" != "$localpath" ]]; then
      rm -f "$temp_local"
    fi
    ssh "${REMOTE_USER}@${SERVER}" "/opt/ftnt/bin/fprepo refresh '${BASE_DIR}'" || {
      echo "Failed to run fprepo command to refresh repository" >&2
      exit 1
    }
    ;;

  *)
    echo "Error: unknown action '$action'" >&2
    usage
    exit 1
    ;;
esac
