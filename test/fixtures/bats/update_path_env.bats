PATH="/usr/bin:/bin"

@test "PATH is reset" {
  echo "$PATH"
  false
}
