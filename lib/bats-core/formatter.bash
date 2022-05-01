#!/usr/bin/env bash

# reads (extended) bats tap streams from stdin and calls callback functions for each line
# bats_tap_stream_plan <number of tests>                                      -> when the test plan is encountered
# bats_tap_stream_begin <test index> <test name>                              -> when a new test is begun WARNING: extended only
# bats_tap_stream_ok [--duration <milliseconds] <test index> <test name>      -> when a test was successful
# bats_tap_stream_not_ok [--duration <milliseconds>] <test index> <test name> -> when a test has failed
# bats_tap_stream_skipped <test index> <test name> <skip reason>              -> when a test was skipped
# bats_tap_stream_comment <comment text without leading '# '> <scope>         -> when a comment line was encountered, 
#                                                                                scope tells the last encountered of plan, begin, ok, not_ok, skipped, suite
# bats_tap_stream_suite <file name>                                           -> when a new file is begun WARNING: extended only
# bats_tap_stream_unknown <full line> <scope>                                 -> when a line is encountered that does not match the previous entries,
#                                                                                scope @see bats_tap_stream_comment
# forwards all input as is, when there is no TAP test plan header
function bats_parse_internal_extended_tap() {
    local header_pattern='[0-9]+\.\.[0-9]+'
    IFS= read -r header

    if [[ "$header" =~ $header_pattern ]]; then
        bats_tap_stream_plan "${header:3}"
    else
        # If the first line isn't a TAP plan, print it and pass the rest through
        printf '%s\n' "$header"
        exec cat
    fi

    ok_line_regexpr="ok ([0-9]+) (.*)"
    skip_line_regexpr="ok ([0-9]+) (.*) # skip( (.*))?$"
    not_ok_line_regexpr="not ok ([0-9]+) (.*)"

    timing_expr="in ([0-9]+)ms$"
    local test_name begin_index ok_index not_ok_index index scope
    begin_index=0
    index=0
    scope=plan
    while IFS= read -r line; do
        case "$line" in
        'begin '*) # this might only be called in extended tap output
            ((++begin_index))
            scope=begin
            test_name="${line#* "$begin_index" }"
            bats_tap_stream_begin "$begin_index" "$test_name"
            ;;
        'ok '*)
            ((++index))
            if [[ "$line" =~ $ok_line_regexpr ]]; then
                ok_index="${BASH_REMATCH[1]}"
                test_name="${BASH_REMATCH[2]}"
                if [[ "$line" =~ $skip_line_regexpr ]]; then
                    scope=skipped
                    test_name="${BASH_REMATCH[2]}" # cut off name before "# skip"
                    local skip_reason="${BASH_REMATCH[4]}"
                    bats_tap_stream_skipped "$ok_index" "$test_name" "$skip_reason"
                else
                    scope=ok
                    if [[ "$line" =~ $timing_expr ]]; then
                        bats_tap_stream_ok --duration "${BASH_REMATCH[1]}" "$ok_index" "$test_name"
                    else
                        bats_tap_stream_ok "$ok_index" "$test_name"
                    fi
                fi
            else
                printf "ERROR: could not match ok line: %s" "$line" >&2
                exit 1
            fi
            ;;
        'not ok '*)
            ((++index))
            scope=not_ok
            if [[ "$line" =~ $not_ok_line_regexpr ]]; then
                not_ok_index="${BASH_REMATCH[1]}"
                test_name="${BASH_REMATCH[2]}"
                if [[ "$line" =~ $timing_expr ]]; then
                    bats_tap_stream_not_ok --duration "${BASH_REMATCH[1]}" "$not_ok_index" "$test_name"
                else
                    bats_tap_stream_not_ok "$not_ok_index" "$test_name"
                fi
            else
                printf "ERROR: could not match not ok line: %s" "$line" >&2
                exit 1
            fi
            ;;
        '# '*)
            bats_tap_stream_comment "${line:2}" "$scope"
            ;;
        '#')
            bats_tap_stream_comment "" "$scope"
            ;;
        'suite '*) 
            scope=suite
            # pass on the
            bats_tap_stream_suite "${line:6}"
        ;;
        *)
            bats_tap_stream_unknown "$line" "$scope"
        ;;
        esac
    done
}

normalize_base_path() { # <target variable> <base path>
    # the relative path root to use for reporting filenames
    # this is mainly intended for suite mode, where this will be the suite root folder
    local base_path="$2"
    # use the containing directory when --base-path is a file
    if [[ ! -d "$base_path" ]]; then
        base_path="$(dirname "$base_path")"
    fi
    # get the absolute path
    base_path="$(cd "$base_path" && pwd)"
    # ensure the path ends with / to strip that later on
    if [[ "${base_path}" != *"/" ]]; then
        base_path="$base_path/"
    fi
    printf -v "$1" "%s" "$base_path"
}
