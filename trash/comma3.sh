shopt -s extdebug
set -o functrace
foo() { echo "BASH_COMMAND=\"$BASH_COMMAND\""; return 1; }
trap 'foo' DEBUG


echo a && echo b &
