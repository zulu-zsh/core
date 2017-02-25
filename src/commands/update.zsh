###
# Print usage information
###
function _zulu_update_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu update [options]"
  echo
  echo $(_zulu_color yellow "Options:")
  echo "  -c, --check       Check if an update is available"
  echo "  -h, --help        Output this help text and exit"
}

###
# Update the zulu package index
###
function _zulu_update_index() {
  local old="$(pwd)"

  cd $index
  git fetch origin && git rebase origin
  cd $old
}

function _zulu_update_check_for_update() {
  local old="$(pwd)"

  cd "$base/index"

  git fetch origin &>/dev/null

  if command git rev-parse --abbrev-ref @'{u}' &>/dev/null; then
    count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"

    down="$count[(w)2]"

    if [[ $down > 0 ]]; then
      echo "$(_zulu_color green "Zulu index updates available") Run zulu update to update the index"
      cd $old
      return
    fi
  fi

  echo "$(_zulu_color green "No update available        ")"
  cd $old
  return 1
}

###
# Update the zulu package index
###
function _zulu_update() {
  local help base index check

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  index="${base}/index"

  # Parse options
  zparseopts -D h=help -help=help c=check -check=check

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_update_usage
    return
  fi

  if [[ -n $check ]]; then
    _zulu_revolver start "Checking for updates..."
    _zulu_update_check_for_update
    _zulu_revolver stop
    return
  fi

  _zulu_revolver start "Checking for updates..."
  if _zulu_update_check_for_update > /dev/null; then
    _zulu_revolver update "Updating package index..."
    out=$(_zulu_update_index 2>&1)
    _zulu_revolver stop

    if [ $? -eq 0 ]; then
      echo "$(_zulu_color green '✔') Package index updated        "
    else
      echo "$(_zulu_color red '✘') Error updating package index        "
      echo "$out"
    fi

    return
  fi

  _zulu_revolver stop
  echo "$(_zulu_color green "No update available        ")"
}
