setup_suite() {
    echo $BASH_SOURCE setup_suite >> "$LOGFILE"
}

teardown_suite() {
    echo $BASH_SOURCE teardown_suite >> "$LOGFILE"
}