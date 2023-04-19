# .bashrc

#
# Source global definitions. (DO NOT EDIT!)
#
if [[ -f /etc/bashrc ]]; then
    source /etc/bashrc
fi

# BEGIN ANSIBLE MANAGED BLOCK - Setup environment for Lua, Lmod & EasyBuild.
if [[ -f "/apps/modules//modules.bashrc" ]]; then
    source "/apps/modules//modules.bashrc"
fi
# END ANSIBLE MANAGED BLOCK - Setup environment for Lua, Lmod & EasyBuild.

#
# User specific personal settings, aliases and functions below this comment.
# Do *not* edit the global settings above!
#

if ! [[ "${PATH}" =~ "${HOME}/bin:" ]]; then
    PATH="${HOME}/bin:${PATH}"
fi
if ! [[ "${PATH}" =~ "${HOME}/.local/bin:" ]]; then
    PATH="${HOME}/.local/bin:${PATH}"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=
