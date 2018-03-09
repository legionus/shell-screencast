#!/bin/bash -efu
### This file is covered by the GNU General Public License,
### which should be included with screencast.bash as the file LICENSE.

TERM_COLUMNS="$(tput cols)"
TERM_LINES="$(tput lines)"

string()
{
	local s="$1"
	for (( i=0; i < ${#s}; i++ )); do
		printf "%s" "${s:$i:1}"
		sleep "${2:-0.05}"
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
