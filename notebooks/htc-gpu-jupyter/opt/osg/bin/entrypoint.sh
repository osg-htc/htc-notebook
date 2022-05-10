#!/bin/sh
# Prepare the host before starting the notebook server.

set -eu

_idtokens_dir="$HOME/.condor/tokens.d"
_sssd_socket="/var/lib/sss/pipes/nss"


#---------------------------------------------------------------------------
# When running as "jovyan", fall back on the original HTC setup.


if [ "$(id -u)" = "1000" ]; then
  exec /.entrypoint.sh "$@"
fi


#---------------------------------------------------------------------------
# Otherwise, assume that we're running as some OSPool user:
#
#   1. Wait for sssd to create its socket.
#   2. Copy the skeleton directory.
#   3. Write the user's HTCondor IDTOKEN to a file.


until test -e "${_sssd_socket}"; do
  printf 'Waiting for %s to be created\n' "${_sssd_socket}"
  sleep 2
done

if [ -d /etc/skel ]; then
  for f in /etc/skel/.* /etc/skel/*; do
    if [ -f "$f" ] && [ ! -e "$HOME/$(basename -- "$f")" ]; then
      cp "$f" "$HOME"
    fi
  done
fi

if [ -n "${_osg_HTCONDOR_IDTOKEN:-}" ]; then
  if [ ! -d "${_idtokens_dir}" ]; then
    mkdir -p "${_idtokens_dir}"
    chmod u=rwx,go= "${_idtokens_dir}"
  fi
  printf '%s' "${_osg_HTCONDOR_IDTOKEN}" > "${_idtokens_dir}/$(hostname)"
fi

exec "$@"
