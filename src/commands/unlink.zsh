###
# Print usage information
###
function _zulu_unlink_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu unlink <package>"
}

###
# The zulu unlink function
###
function _zulu_unlink() {
  local help package json dir file link base
  local -a dirs

  zparseopts -D h=help -help=help

  if [[ -n $help ]]; then
    _zulu_unlink_usage
    return
  fi

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config_dir=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="$base/index/packages"

  package="$1"

  # Check if the package is already installed
  root="$base/packages/$package"
  if [[ ! -d "$root" ]]; then
    echo $(_zulu_color red "Package '$package' is not installed")
    return 1
  fi

  _zulu_revolver start "Unlinking $package..."

  # Get the JSON from the index
  json=$(cat "$index/$package")

  # Loop through the 'bin' and 'share' objects
  dirs=('bin' 'init' 'share')
  local oldPWD=$PWD
  local flags

  case $OSTYPE in
    darwin* )
      flags=''
      ;;
    linux* )
      flags='-r'
      ;;
  esac

  for dir in $dirs[@]; do
    cd "$base/$dir"
    # Unlink any file in $dir which points to the package's source
    ls -la | \
      grep "$base/packages/$package/" | \
      awk '{print $9}' | \
      xargs $flags rm
  done

  cd $oldPWD

  _zulu_revolver stop
  echo "$(_zulu_color green '✔') Finished unlinking $package        "
}
