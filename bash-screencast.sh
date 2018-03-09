#!/bin/bash -efu
### This file is covered by the GNU General Public License,
### which should be included with bash-screencast.sh as the file LICENSE.

TERM_COLUMNS="$(tput cols)"
TERM_LINES="$(tput lines)"

### Creates a mask of equal length string.
### Usage: fill_mask var str [full-length]
fill_mask()
{
__fill_mask()
{
	local m=
	while :; do
		case $((${#1} - ${#m})) in
			0) break ;;
			1) m="$m?" ;;
			2) m="$m??" ;;
			3) m="$m???" ;;
			4) m="$m????" ;;
			5) m="$m?????" ;;
			6) m="$m??????" ;;
			7) m="$m???????" ;;
			8) m="$m????????" ;;
			9) m="$m?????????" ;;
			*) m="$m??????????" ;;
		esac
	done
	__fill_masko="${m#$2}"
}
	local __fill_masko
	__fill_mask "$2" "${3:-?}"
	unset -f __fill_mask
	eval "$1=\$__fill_masko"
}

string()
{
	local c m s="$1"

	fill_mask m "$s"
	while [ "${#s}" != 0 ]; do
		c="${s%$m}"

		printf '%s' "$c"
		sleep "${2:-0.05}"

		s="${s#?}"
		m="${m#?}"
	done
}

savePosition()
{
	echo -ne '\033[s'
	"$@"
	echo -ne '\033[u'
}

pauseMark()
{
	echo -ne '\033[s'
	echo -ne '\r'
	[ -n "${1-}" ] && echo '.' || echo ' '
	echo -ne '\033[u'
}

KEY=
pause()
{
	local a n IFS=','
	pauseMark
	for a in ${PAUSE-}; do
		[ "$a" = "$1" ] ||
			continue
		pauseMark 1
		read -s -n1 KEY ||:
		pauseMark
		break
	done
}

prompt()
{
	local cwd="$PWD"
	[ "$cwd" != "$HOME" ] &&
		cwd="${cwd##*/}" ||
		cwd='~'
	echo -ne " [\033[1;36m$(date +'%T') @ $cwd\033[0m]$ "
	sleep 0.3
}

shell()
{
	while read -p "$(prompt)" -e string; do
		[ "$string" != 'quit' ] ||
			break
		eval "$string"
	done
}

comment()
{
	pause before
	echo -n ' $ '
	pause prompt
	echo -ne '\033[34;1m'
	string "$*" 0.02
	echo -e '\033[0m'
	pause after
	echo
}

next()
{
	local i

	i="$TERM_COLUMNS"
	while [ "$i" != 0 ]; do
		echo -n '#'
		i=$(($i-1))
	done
	echo

	i="$TERM_LINES"
	while [ "$i" != 0 ]; do
		echo
		i=$(($i-1))
	done
	echo -ne '\033[1;1H'
}

quit()
{
	pause before
	prompt
	pause prompt
	echo -ne '\033[32;1m'
	string "That's all! Questions ?"
	echo -ne '\033[0m'
	pause after
	echo
}

showCommand()
{
	prompt
	pause prompt
	string "$*"
	sleep 0.5
	pause command
}

skipResult()
{
	echo -e '\033[90;1m<<< SKIP EXECUTION >>>\033[0m'
}

run()
{
	pause before
	showCommand "$*"
	echo
	if [ "${KEY-}" != 's' ]; then
		eval "$*" ||:
	else
		skipResult "$*"
	fi
	pause after
	echo
}

runFilter()
{
	local filter="$1"; shift
	pause before
	showCommand "$*"
	echo
	if [ "${KEY-}" != 's' ]; then
		{
			eval "$*"
		} | {
			eval "$filter"
		} ||:
	else
		skipResult "$*"
	fi
	pause after
	echo
}

if [ "$#" = 0 ]; then
	printf 'Usage: %s script\n' "${0##*/}"
	exit 0
fi

. "$@"
