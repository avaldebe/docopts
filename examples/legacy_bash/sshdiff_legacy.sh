#!/bin/bash

usage() {
  cat << EOF
Show file differences between 2 hosts.
Usage: sshdiff.sh [-h] [-s] <host1> <host2> <file> [<lines_context>]

Use colordiff if available.

Options:
    -h   display this help and exit
    -s   use sort instead of cat to show remote FILE

If not specified, <lines_context> defaults to 3.

Environment variable:
  EXTRA_DIFF  pass extra argument to diff command
  SSH_USER    use this user for remote ssh user (default: $USER)

Examples:
    sshdiff.sh server1 server2 /etc/crontab
    # ignore changes on blank lines
    EXTRA_DIFF=-b sshdiff.sh webserver1 webserver2 /etc/apache2/apache2.conf
EOF
}

# legacy option parsing
FILTER="cat"
while getopts "hs" OPTION
do
  case $OPTION in
    h)
      usage
      exit 0
    ;;
    s)
      FILTER="sort"
    ;;
    *)
      usage
      exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -lt 3 ]; then
  echo "invalid number of arguments." >&2
  usage
  exit 1
fi

HOST1=$1
HOST2=$2
FILENAME=$3

# main code
LINES_CONTEXT="3"
if [ -n "$4" ]; then
  if [ "$4" -gt 0 ]; then
    LINES_CONTEXT="$4"
  else
    echo "<lines_context>: '$4' must be greater than 0." >&2
    usage
    exit 1
  fi
fi

# selecting diff program
DIFF="$(which diff)"
COLORDIFF="$(which colordiff)"
if [ -x "$COLORDIFF" ]; then
  DIFF="$COLORDIFF"
fi

if [ -z "$SSH_USER" ]; then
  SSH_USER=$USER
fi

# complete final command
"$DIFF" $EXTRA_DIFF -U "$LINES_CONTEXT" \
    <(ssh $SSH_USER@"$HOST1" $FILTER "$FILENAME") \
    <(ssh $SSH_USER@"$HOST2" $FILTER "$FILENAME")
