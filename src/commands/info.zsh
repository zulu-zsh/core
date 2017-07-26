###
# Output usage information
###
function _zulu_info_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu info <package>"
}

###
# Check if a package is installed
###
function _zulu_info_is_installed() {
  local package="$1" base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}

  [[ -d "$base/packages/$package" ]]
  return $?
}

###
# Extract package information from the index entry
###
function _zulu_info_package() {
  local json name description url author packagetype installed package=$1

  json=$(command cat "$index/$package")

  name=$(jsonval $json 'name')
  description=$(jsonval $json 'description')
  url=$(jsonval $json 'repository')
  author=$(jsonval $json 'author')
  packagetype=$(jsonval $json 'type')

  _zulu_info_is_installed $name && installed="$(_zulu_color green '✔ Installed')"

  builtin echo "$(_zulu_color white underline "$name") $installed"
  builtin echo $description
  builtin echo

  builtin echo "Type:   $packagetype"
  builtin echo "URL:    $url"
  builtin echo "Author: $author"
}

###
# Zulu command to output package information
###
function _zulu_info() {
  local base index out package=$1

  # Parse options
  builtin zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_info_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="${base}/index/packages"

  if [[ ! -f "$index/$package" ]]; then
    builtin echo $(_zulu_color red "Package '$package' is not in the index")
    return 1
  fi

  _zulu_info_package $package
}
