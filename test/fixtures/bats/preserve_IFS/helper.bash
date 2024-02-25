check_ifs() {
    if [[ ${EXPECTED_IFS?} != ${IFS} ]]; then
        diff <(hexdump -c <<<"$EXPECTED_IFS") <(hexdump -c <<<"$IFS") >"${EXPECTED_IFS_MISMATCH_FILE?}"
        exit 1
    fi
}