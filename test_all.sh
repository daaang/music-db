#!/usr/bin/env bash
PROG="$0"
USAGE="[-h] [TYPE_OF_TEST]"
APPS_TO_TEST=("tracktag")

# This is the magic function that actually runs a test with some
# arguments. I have it using the virtual environment for the sake of
# fidelity when moved to production.
run_unit_test_for() {
  ../virtualenv/bin/python3 manage.py test "$@"
}

# Colorful logging.
echogood() { echo "[1;32m *[0m $@"; }
echowarn() { echo "[1;33m *[0m $@"; }
echobad()  { echo "[1;31m *[0m $@"; }

# Echo an optional error message, then show expected usage and
# exit an error status code.
errorout() {
  echo "usage: ${PROG} $USAGE" >&2
  [ -n "$1" ] && echo "${PROG}: error: $@" >&2
  exit 1
}

# Echo the expected usage along with a detailed help message.
printhelp() {
  cat <<EOF
usage: ${PROG} $USAGE

Description of whatever this does.

positional arguments:
 TYPE_OF_TEST what type of test are we doing? (default: all)

optional arguments:
 -h           show this help message and exit
EOF
}

# Parse any arguments. Put a colon after any options that expect
# $OPTARGs to follow. The colon at the start is unrelated.
while getopts ":h" opt; do
  case "$opt" in
    h)
      # Just print the help message and exit happily.
      printhelp
      exit 0
      ;;

    # Additional options go here.

    ?)
      # Don't tolerate unrecognized options.
      errorout "unrecognized option: \`-$OPTARG'"
      ;;
  esac
done

# Shift so that the first "real" argument is $1.
shift $((OPTIND - 1))

run_unit_tests() {
  return_status=0
  for app in "${APPS_TO_TEST[@]}"; do
    echogood "Unit testing "$app" ..."

    # Run the thing for each app.
    if ! run_unit_test_for "$app"; then
      return_status=1
    fi
  done

  # If any failed, I want to know.
  return $return_status
}

process_input() {
  case "$1" in
    [yY])
      # If it's yes, we good.
      return 0
      ;;

    [nN])
      # If it's no, we good (but returning bad).
      return 1
      ;;

    *)
      # Otherwise, halt.
      echobad "I don't understand \`$1'"
      exit 1
      ;;
  esac
}

process_maybe_empty_input() {
  # If this is called, we're saying that empty input is ok.
  if [ -z "$1" ]; then
    return 0
  fi

  # If the input isn't empty though, we'll just process it normally.
  process_input "$1"
  return $?
}

run_unit_tests_with_messages() {
  if run_unit_tests; then
    echogood "Unit tests succeeded: write more tests, refactor, or"
    echogood "check functional tests."

  else
    echowarn "Unit tests failed: write minimal code to fix."
  fi
}

continue_on_enter() {
  echo -n "[35m>>>[0m "
  read text

  process_maybe_empty_input "$text"
  return $?
}

run_functional_tests_with_messages() {
  echogood "Running functional tests ..."
  if run_unit_test_for functional_tests; then
    echogood "Either write more functional tests or refactor."
    return 0

  else
    echowarn "Functional tests failed; write a unit test."
    return 1
  fi
}

run_all_tests_with_messages() {
  if run_unit_tests; then
    echogood "All unit tests succeeded. Press enter to continue on to"
    echogood "functional tests, or enter \`no' if you want to refactor."

    if ! continue_on_enter; then
      echogood "Refactor away!"
      exit 0
    fi

    run_functional_tests_with_messages

  else
    echowarn "Unit tests failed: write minimal code to fix."
  fi
}

run_tests() {
  local first="$1"
  shift

  case "$first" in
    all)
      run_all_tests_with_messages "$@"
      ;;

    unit)
      run_unit_tests_with_messages
      ;;

    ft)
      run_functional_tests_with_messages
      ;;

    *)
      errorout "unrecognized command: \`$first'"
      ;;
  esac
}

if [ -n "$1" ]; then
  firstarg="$1"
  shift

else
  firstarg="all"
fi

run_tests "$firstarg" "$@"
