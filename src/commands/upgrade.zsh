###
# Output usage information
###
function _zulu_upgrade_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu upgrade [<packages...>]"
  echo
  echo $(_zulu_color yellow "Options:")
  echo "  -c, --check       Check if upgrades are available"
  echo "  -h, --help        Output this help text and exit"
}

###
# Upgrade a package
###
function _zulu_upgrade_package() {
  local package json repo dir file link oldpwd=$(pwd)

  package="$1"

  # Don't let zvm change the ZSH version for use while we're checking
  local old_ZVM_AUTO_USE=${ZVM_AUTO_USE}
  unset ZVM_AUTO_USE

  # Pull from the repository
  cd "$base/packages/$package"

  git rebase origin && git submodule update --init --recursive

  cd $oldpwd

  # Restore the ZVM_AUTO_USE setting
  export ZVM_AUTO_USE=${old_ZVM_AUTO_USE}
}

###
# Zulu command to handle package upgrades
###
function _zulu_upgrade() {
  local base index out count down oldpwd i
  local -a packages to_update
  local -A _pids

  # Parse options
  zparseopts -D h=help -help=help \
                c=check -check=check

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_upgrade_usage
    return
  fi

  # Don't let zvm change the ZSH version for use while we're checking
  local old_ZVM_AUTO_USE=${ZVM_AUTO_USE}
  unset ZVM_AUTO_USE

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="${base}/index/packages"

  _zulu_revolver start "Checking for updates..."

  packages=($@)
  packagefile="$config/packages"

  if [[ ! -f $packagefile ]]; then
    touch $packagefile
  fi

  # If no context is passed, upgrade the contents of the packagefile
  if [[ ${#packages} -eq 0 ]]; then
    packages=($(/bin/ls "$base/packages"))
  fi

  oldpwd=$(pwd)

  # If the ZSH version we are using supports it,
  # perform update checks asynchronously
  if is-at-least '5.1'; then
    _pids=()
    # Do a first loop, to kick off a fetch asynchronously
    for package in "$packages[@]"; do
      cd "$base/packages/$package"

      {
        git fetch origin >/dev/null 2>&1
      } &!
      _pids[${package}]=$!
    done

    # Do a second loop, to wait until all subprocesses have finished
    for package pid in "${(@kv)_pids}"; do
      while kill -0 $pid >/dev/null 2>&1; do
      done
    done
  else
    for package in "$packages[@]"; do
      cd "$base/packages/$package"
      git fetch origin >/dev/null 2>&1
    done
  fi

  # Do a third loop, to check if updates are available
  i=1
  for package in "$packages[@]"; do
    cd "$base/packages/$package"

    if command git rev-parse --abbrev-ref @'{u}' &>/dev/null; then
      count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"

      down="$count[(w)2]"

      if [[ $down > 0 ]]; then
        to_update[$i]="$package"
        i=$(( i + 1 ))
      fi
    fi
  done

  cd $oldpwd

  # Restore the ZVM_AUTO_USE setting
  export ZVM_AUTO_USE=${old_ZVM_AUTO_USE}

  _zulu_revolver stop

  if [[ ${#to_update} -eq 0 ]]; then
    echo "$(_zulu_color green "Nothing to upgrade        ")"
    return 1
  fi

  if [[ -n $check ]]; then
    echo "$(_zulu_color green 'Package upgrades available') Run zulu upgrade to upgrade"
    return 0
  fi

  echo $(_zulu_color yellow 'The following packages will be upgraded')
  echo "$to_update[@]"
  echo $(_zulu_color yellow bold 'Continue (y|N)')
  read -rs -k 1 input

  case $input in
    y)
      for package in "$to_update[@]"; do
        if [[ -z $package ]]; then
          continue
        fi
        # Unlink package first
        zulu unlink $package

        # Upgrade the package
        _zulu_revolver start "Upgrading $package..."
        out=$(_zulu_upgrade_package "$package" 2>&1)
        _zulu_revolver stop

        if [ $? -eq 0 ]; then
          echo "$(_zulu_color green '✔') Finished upgrading $package        "
          zulu link $package
        else
          echo "$(_zulu_color red '✘') Error upgrading $package        "
          echo "$out"
        fi
      done
      ;;
    *)
      echo $(_zulu_color red 'Upgrade cancelled')
      return 1
      ;;
  esac
}
