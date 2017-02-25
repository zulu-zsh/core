###
# Output usage information
###
function _zulu_info_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu info <package>"
}

###
# Extract package information from the index entry
###
function _zulu_info_package() {
  local json name description url author packagetype installed package=$1

  json=$(cat "$index/$package")

  name=$(jsonval $json 'name')
  description=$(jsonval $json 'description')
  url=$(jsonval $json 'repository')
  author=$(jsonval $json 'author')
  packagetype=$(jsonval $json 'type')

  installed=""
  [[ -d "$base/packages/$package" ]] && installed="$(_zulu_color green '✔ Installed')"

  echo "$(_zulu_color white underline "$name") $installed"
  echo $description
  echo

  echo "Type:   $packagetype"
  echo "URL:    $url"
  echo "Author: $author"
}

###
# Zulu command to output package information
###
function _zulu_info() {
  local base index out package=$1

  # Parse options
  zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_install_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="${base}/index/packages"

  if [[ ! -f "$index/$package" ]]; then
    echo $(_zulu_color red "Package '$package' is not in the index")
    return 1
  fi

  _zulu_info_package $package
}
