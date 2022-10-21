echo stdout
echo stderr >&2
echo fd3 >&3

@test fail {
 true
}
