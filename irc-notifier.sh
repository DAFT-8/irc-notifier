#!/bin/bash

until [ ! -e $NICK ]; do
  read -p $"IRC Nick (Default: listener) = " NICK
  [ ! "$NICK" ] && NICK="listener"
done

until [ ! -e $IRC_SERVER ]; do
  read -p $"IRC Server (Default: irc.oftc.net) = " IRC_SERVER
  [ ! "$IRC_SERVER" ] && IRC_SERVER="irc.oftc.net"
done

until [ ! -e $IRC_PORT ]; do
  read -p $"IRC Port (Default: 6697) = " IRC_PORT
  [ ! "$IRC_PORT" ] && IRC_PORT="6697"
done

until [ ! -e $CHANNEL ]; do
  read -p $"IRC Channel (Default: #daft-8) = " CHANNEL
  [ ! "$CHANNEL" ] && CHANNEL="#daft-8"
done

exec 3<>/dev/tcp/${IRC_SERVER}/${IRC_PORT}

echo "NICK ${NICK}" >&3
echo "USER ${NICK} 8 * : ${NICK}" >&3
echo "JOIN ${CHANNEL}" >&3

while read -u 3 -r line; do
    echo "${line}"

    if [[ "${line}" =~ "PING" ]]; then
        echo "PONG ${line#PING }" >&3
    fi

    if echo "${line}" | grep -q "PRIVMSG ${CHANNEL} :" && [[ ${line} != ${last_message} ]]; then
        sender=$(echo "${line}" | cut -d '!' -f 1 | cut -d ':' -f 2)
        message=$(echo "${line}" | cut -d ' ' -f 4- | cut -d ':' -f 2-)

	if command -v pkg >/dev/null; then
		$(adb shell cmd notification post -S bigtext -t "Message from ${sender}" "${CHANNEL}" "${message}") >/dev/null
	else
		$(notify-send "Message from ${sender}: ${message}") >/dev/null
	fi

        last_message="${line}"
    fi
done

exec 3<&-
exec 3>&-