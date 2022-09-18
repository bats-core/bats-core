#!/usr/bin/env bats

function bgfunc {
  get_open_fds
  echo "${FUNCNAME[1]} fds before: (${open_fds[*]})" >>"${LOG_FILE}"
  close_non_std_fds
  get_open_fds
  echo "${FUNCNAME[1]} fds after: (${open_fds[*]})" >>"${LOG_FILE}"
  sleep 10
  echo "bgfunc done"
  return 0
}

# store the list of open FDs in array open_fds
function get_open_fds() {
  open_fds=() # reset output array in case it was already set
  if [[ ${BASH_VERSINFO[0]} == 3 ]]; then
    local BASHPID
    BASHPID=$(bash -c 'echo $PPID')
  fi
  local tmpfile
  tmpfile=$(mktemp "$BATS_SUITE_TMPDIR/fds-XXXXXX")
  # Avoid opening a new fd to read fds: Don't use <(), glob expansion.
  # Instead, redirect stdout to file which does not create an extra FD.
  if [[ -d /proc/$BASHPID/fd ]]; then # Linux
    ls -1 "/proc/$BASHPID/fd" >"$tmpfile"
    IFS=$'\n' read -d '' -ra open_fds <"$tmpfile" || true
  elif command -v lsof >/dev/null; then # MacOS
    local -a fds
    lsof -F f -p "$BASHPID" >"$tmpfile"
    IFS=$'\n' read -d '' -ra fds <"$tmpfile" || true
    for fd in "${fds[@]}"; do
      case $fd in
      f[0-9]*)                # filter non fd entries (mainly pid?)
        open_fds+=("${fd#f}") # cut off f prefix
        ;;
      esac
    done
  elif command -v procstat >/dev/null; then # BSDs
    local -a columns header
    procstat fds "$BASHPID" >"$tmpfile"
    {
      read -r -a header
      local fd_column_index=-1
      for ((i = 0; i < ${#header[@]}; ++i)); do
        if [[ ${header[$i]} == *FD* ]]; then
          fd_column_index=$i
          break
        fi
      done
      if [[ $fd_column_index -eq -1 ]]; then
        printf "Could not find FD column in procstat" >&2
        exit 1
      fi
      while read -r -a columns; do
        local fd=${columns[$fd_column_index]}
        if [[ $fd == [0-9]* ]]; then # only take up numeric entries
          open_fds+=("$fd")
        fi
      done
    } <"$tmpfile"
  else
    # TODO: MSYS (Windows)
    printf "Neither FD discovery mechanism available\n" >&2
    exit 1
  fi
}

function close_non_std_fds() {
  local open_fds non_std_fds=()
  get_open_fds
  for fd in "${open_fds[@]}"; do
    if [[ $fd -gt 2 ]]; then
      non_std_fds+=("$fd")
    fi
  done
  close_fds "${non_std_fds[@]}"
}

function close_fds() { # <fds...>
  for fd in "$@"; do
    eval "exec $fd>&-"
  done
}

function otherfunc {
  bgfunc &
  PID=$!
  disown
  return 0
}

setup_file() { # see issue #530
  bgfunc &
}

@test "min bg" {
  echo "sec: $SECONDS"
  otherfunc
  sleep 1           # leave some space for the background job to print/fail early
  kill -s 0 -- $PID # fail it the process already finished due to error!
  echo "sec: $SECONDS"
}
