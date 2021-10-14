#!/bin/sh
#
# Copyright (c) 2021 Sean Davies <sean@city17.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

set -e
umask 0077

__version=0.3

blocklist=/var/unbound/etc/badhosts

die()
{
	echo "$1" 1>&2
	exit 1
}

usage()
{
	die "usage: ${0##*/} [-fgpsx | -v]"
}

cleanup()
{
	if [ -f "${tmpfile}" ]; then
		rm -f "${tmpfile}"
	fi
}

droproot()
{
	local _user=_ftp

	eval su -s /bin/sh ${_user} -c "'$*'" || exit 1
}

mktmpfile()
{
	local _i=0 _file

	until _file=/tmp/${0##*/}.$(openssl rand -hex 8) && [ ! -f "${_file}" ]; do
		_i=$((_i + 1))
		if [ "$_i" -ge 1000 ]; then
			die "${0##*/}: failed to create temp file"
		fi
	done
	touch "${_file}"
	tmpfile="${_file}"
}

fetchblocklist()
{
	local _data _list=$1

	if [ "${xflag}" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
		_data=$(droproot ftp -N "${0##*/}" -MVo - "${_list}")
	else
		_data=$(ftp -N "${0##*/}" -MVo - "${_list}") || exit 1
	fi

	if [ -z "${_data}" ]; then
		die "${0##*/}: failed to download blocklist"
	fi
	echo "${_data}" | processblocklist
}

processblocklist()
{
	awk '/^0\.0\.0\.0/ {
		print "local-zone: \""$2"\" redirect\nlocal-data: \""$2" A 0.0.0.0\""
	}' >"${tmpfile}"

	if [ ! -s "${tmpfile}" ]; then
		die "${0##*/}: failed to create blocklist"
	fi
}

blocklisturl()
{
	local _url

	case ${list} in
	1)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts' ;;
	3)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts' ;;
	5)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling/hosts' ;;
	7)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts' ;;
	9)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts' ;;
	11)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-porn/hosts' ;;
	13)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn/hosts' ;;
	15)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts' ;;
	17)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social/hosts' ;;
	19)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-social/hosts' ;;
	21)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-social/hosts' ;;
	23)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-social/hosts' ;;
	25)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-social/hosts' ;;
	27)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-porn-social/hosts' ;;
	29)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-social/hosts' ;;
	31)	_url='https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts' ;;
	*)	die "${0##*/}: internal error" ;;
	esac
	echo ${_url}
}

list=1
vflag=0
xflag=0
while getopts fgpsvx arg; do
	case ${arg} in
	f)	[ "${fflag:-0}" -eq 0 ] || usage
		fflag=1
		list=$((list + 2)) ;;
	g)	[ "${gflag:-0}" -eq 0 ] || usage
		gflag=1
		list=$((list + 4)) ;;
	p)	[ "${pflag:-0}" -eq 0 ] || usage
		pflag=1
		list=$((list + 8)) ;;
	s)	[ "${sflag:-0}" -eq 0 ] || usage
		sflag=1
		list=$((list + 16)) ;;
	v)	vflag=1 ;;
	x)	xflag=1 ;;
	*)	usage ;;
	esac
done
shift $((OPTIND - 1))
[ "$#" -eq 0 ] || usage

if [ "${vflag}" -eq 1 ]; then
	if [ "${list}" -gt 1 ] || [ "${xflag}" -eq 1 ]; then
		usage
	fi
	echo "${0##*/}-${__version}"
	exit 0
fi

if [ "$(uname -s)" != "OpenBSD" ]; then
	die "${0##*/}: unsupported operating system"
fi

if [ "${xflag}" -eq 0 ]; then
	if [ "$(id -u)" -ne 0 ]; then
		die "${0##*/}: needs root privileges"
	fi
fi

trap 'cleanup' EXIT
mktmpfile

fetchblocklist "$(blocklisturl)"
if [ "${xflag}" -eq 0 ]; then
	if ! cmp "${tmpfile}" ${blocklist} >/dev/null 2>&1; then
		if [ -f "${blocklist}" ]; then
			mv -f ${blocklist} ${blocklist}.bck
		fi
		install -Fm 644 "${tmpfile}" ${blocklist}
		unbound-control reload >/dev/null
	fi
	if ! grep -Eq "include: \"?${blocklist}\"?" /var/unbound/etc/unbound.conf; then
		die "${0##*/}: unbound.conf: include statement missing"
	fi
else
	cat "${tmpfile}"
fi
