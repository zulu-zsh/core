###
# Output usage information
###
function _zulu_var_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu var <context> [args]"
  echo
  echo $(_zulu_color yellow "Contexts:")
  echo "  add <var> <command>   Add an environment variable"
  echo "  load                  Load all environment variables from env file"
  echo "  rm <var>              Remove an environment variable"
}

###
# Add an var
###
_zulu_var_add() {
  local existing var cmd

  var="$1"
  cmd="${(@)@:2}"

  existing=$(cat $envfile | grep "export $var=")
  if [[ $existing != "" ]]; then
    echo $(_zulu_color red "Environment variable '$var' already exists")
    return 1
  fi

  echo "export $var='$cmd'" >> $envfile

  zulu var load
  return
}

###
# Remove an var
###
_zulu_var_rm() {
  local existing var

  var="$1"

  existing=$(cat $envfile | grep "export $var=")
  if [[ $existing = "" ]]; then
    echo $(_zulu_color red "Environment variable '$var' does not exist")
    return 1
  fi

  echo "$(cat $envfile | grep -v "export $var=")" >! $envfile
  unset $var
  zulu var load
  return
}

###
# Load vares
###
_zulu_var_load() {
  source $envfile
}

###
# Zulu command to handle path manipulation
###
function _zulu_var() {
  local ctx base envfile

  # Parse options
  zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_var_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  envfile="${config}/env"

  if [[ ! -f $envfile ]]; then
    touch $envfile
  fi

  # If no context is passed, output the contents of the envfile
  if [[ "$1" = "" ]]; then
    cat "$envfile"
    return
  fi

  # Get the context
  ctx="$1"

  # Call the relevant function
  _zulu_var_${ctx} "${(@)@:2}"
}
