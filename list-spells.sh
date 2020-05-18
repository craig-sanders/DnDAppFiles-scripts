#!/bin/bash

cd /home/cas/git/rpg/DnDAppFiles/Compendiums

function usage() {
  script=$(basename $0)

  cat <<__EOF__
Usage: $script [options] <search pattern>...

  -h      This usage message
  -n      Search spell names only
  -b      Search for full word only
  -l c    Search for spells of 'Level: [c]' (a regexp class) only

  -C      Don't list Classes

  -x      Exclude spells that can only be cast by a class archetype.
          e.g. with '-x druid cleric' the regexp becomes '(druid|cleric)[^ ]'

Search patterns are case-insensitive perl regular expressions.  If multiple
search patterns are provided, they are joined together in a bracketed regexp
with '|' - e.g. 'wizard sorcerer' becomes '(wizard|sorcerer)'.

Examples:
   $script -l 012 druid
   $script rope
   $script -x cleric trickery | grep -vi druid
__EOF__

  exit 1
}

# re-order args
# http://mywiki.wooledge.org/ComplexOptionParsing#Rearranging_arguments
arrange_opts() {
    local flags args optstr="$1"
    shift

    while (($#)); do
        case "$1" in
            --) args+=("$@")
                break;
                ;;
            -*) flags+=("$1")
                if [[ $optstr == *"${1: -1}:"* ]]; then
                    flags+=("$2")
                    shift
                fi
                ;;
            * ) args+=("$1")
                ;;
        esac
        shift
    done
    OPTARR=("${flags[@]}" "${args[@]}")
}

known_opts="hnbl:Cx"
arrange_opts "$known_opts" "$@"
set -- "${OPTARR[@]}"

NAMEONLY=''
FULLWORD=''
LEVELS=''
NOCLASSES=''
CORECLASS=''

while getopts "$known_opts" opt; do
    case "$opt" in
        h) usage ;;
        n) NAMEONLY='-n' ;;
        b) FULLWORD='-b' ;;
        l) LEVEL="${LEVEL}${OPTARG}" ;;
        C) NOCLASSES=1 ;;
        x) CORECLASS=1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

[ -z "$1" ] && usage

filter1=(cat)
filter2=(cat)

[ -n "$LEVEL" ] && filter1=(grep "Level: [$LEVEL]")
[ -n "$NOCLASSES" ] && filter2=(sed -e 's/[[:space:]]*Classes:.*//')

joinarray() { local IFS="$1"; shift; echo "$*"; }

REGEXP="($(joinarray '|' "$@"))"
[ -n "$CORECLASS" ] && REGEXP="$REGEXP[^ ]"

#declare -p filter1 filter2 REGEXP
#echo ./grep-spell.sh $NAMEONLY $FULLWORD "$REGEXP"

#./grep-spell.sh $NAMEONLY $FULLWORD "$REGEXP" |
grep-dnd-spell.pl $NAMEONLY $FULLWORD "$REGEXP" |
    grep -E '(Name|Level|School|Classes):' |
    awk 'NR % 4 == 1 { a=$0 ; next } NR % 4 == 2 {b=$0 ; next} NR % 4 == 3 { c=$0 ; next} { printf "%-10s %-10s %-40s %s\n",  b, c, a, $0 }'  |
    sort |
    "${filter1[@]}" | "${filter2[@]}"

