#!/usr/bin/env bash

# $1 - output directory for stdout/stderr
# $@ - command to run
# run the given command in a semaphore
# block when there is no free slot for the semaphore
# when there is a free slot, run the command in background
# gather the output of the command in files in the given directory
bats_semaphore_run() {
    bats_semaphore_acquire_slot
    bats_semaphore_release_wrapper "$@" & >/dev/null 2>/dev/null
    printf "%d\n" "$!"
}

export BATS_SEMAPHORE_DIR="$BATS_RUN_TMPDIR/semaphores"
export BATS_SEMAPHORE_NUMBER_OF_SLOTS="$num_jobs"

# $1 - output directory for stdout/stderr
# $@ - command to run
# this wraps the actual function call to install some traps on exiting
bats_semaphore_release_wrapper() {
    # this background subprocess takes over the semaphore from its parent
    # on unix mv uses rename, which is atomic on the same filesystem
    # iff mv is atomic, we don't need to lock, as there is no observable
    # state where this operation changes the number of used semaphore slots
    # as we are a special (background) subshell $$ is our parent's pid and $BASHPID is our own
    mv "$BATS_SEMAPHORE_DIR/pid-$$" "$BATS_SEMAPHORE_DIR/pid-$BASHPID"
    trap bats_semaphore_release_slot EXIT

    output_dir="$1"
    shift # all other parameters will be use for the command to execute

    mkdir -p "$output_dir"
    "$@" 2>"$output_dir/stderr" >"$output_dir/stdout"

    # TODO: why is this necessary? shouldn't the EXIT trap do this already? does it work with signals then?
    bats_semaphore_release_slot
}

# block until a semaphore slot becomes free
bats_semaphore_acquire_slot() {
    mkdir -p "$BATS_SEMAPHORE_DIR"
    # wait for a slot to become free
    while true; do
        # don't lock for reading, we are fine with spuriously getting no free slot
        if [[ $(bats_semaphore_get_free_slot_count) -gt 0 ]]; then
            flock "$BATS_SEMAPHORE_DIR" bash -c "[[ \$(bats_semaphore_get_free_slot_count) -gt 0 ]] && touch '$BATS_SEMAPHORE_DIR/pid-$$'" && break
        fi
        sleep 1
    done
}

bats_semaphore_release_slot() {
    # we don't need to lock this, since only our process owns this file
    # and freeing a semaphore cannot lead to conflicts with others
    rm "$BATS_SEMAPHORE_DIR/pid-$BASHPID" # this will fail if we had not aqcuired a semaphore!
}

bats_semaphore_get_free_slot_count() {
    # find might error out without returning something useful when a file is deleted,
    # while the directory is traversed ->  only continue when there was no error
    until used_slots=$(find "$BATS_SEMAPHORE_DIR" -name 'pid-*' 2>/dev/null | wc -l); do :; done
    echo $(( BATS_SEMAPHORE_NUMBER_OF_SLOTS - used_slots ))
}

export -f bats_semaphore_get_free_slot_count