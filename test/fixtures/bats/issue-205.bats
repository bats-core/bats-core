#!/usr/bin/env bats

function bgfunc {
    close_non_std_fds
    sleep 10
    echo "bgfunc done"
    return 0
}

function get_open_fds() {
    if [[ -d /proc/$$/fd ]]; then # Linux
        read -d '' -ra open_fds < <(ls -1 /proc/$$/fd) || true
    elif command -v lsof >/dev/null ; then # MacOS
        local -a fds
        IFS=$'\n' read -d '' -ra fds < <(lsof -F f -p $$) || true
        open_fds=()
        for fd in "${fds[@]}"; do
            case $fd in 
                f[0-9]*) # filter non fd entries (mainly pid?)
                    open_fds+=("${fd#f}") # cut off f prefix
                ;;
            esac
        done
    elif command -v procstat >/dev/null ; then # BSDs
        local -a columns header
        {
            read -r -a header
            local fd_column_index=-1
            for ((i=0; i<${#header[@]}; ++i)); do
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
        } < <(procstat fds $$)
    else
        # TODO: MSYS (Windows)
        printf "Neither FD discovery mechanism available\n" >&2
        exit 1
    fi
}

function close_non_std_fds() {
    get_open_fds
    for fd in "${open_fds[@]}"; do
        if [[ $fd -gt 2 ]]; then
            printf "Close %d\n" "$fd"
            eval "exec $fd>&-"
        else
            printf "Retain %d\n" "$fd"
        fi
    done
}

function otherfunc {
    bgfunc &
    PID=$!
    disown
    return 0
}

@test "min bg" {
    echo "sec: $SECONDS"
    otherfunc
    sleep 1 # leave some space for the background job to print/fail early
    kill -s 0 -- $PID # fail it the process already finished due to error!
    echo "sec: $SECONDS"
}
