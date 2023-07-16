# /bin/zsh
# jpd customizations - SSH from OneDrive
# in WSL use Windows System Environment Variable ONEDRIVECONSUMER
# Which can be set in Windows Settings -> System -> About -> Advanced System Settings -> Environment Variables
# Add one for WSLENV=ONEDRIVECONSUMER/p

if [[ $OneDriveConsumer -eq "" && $(uname -s) -eq "Darwin" ]]; then
    OneDriveConsumer=/Volumes/Macintosh\ HD/Users/jpd/OneDrive
    export ONEDRIVECONSUMER=/Volumes/Macintosh\ HD/Users/jpd/OneDrive
fi

echo OneDrive root: $OneDriveConsumer

# get ssh keys from onedrive
cp $ONEDRIVECONSUMER/ssh/*_rsa ~/.ssh/
chmod 600 ~/.ssh/*_rsa

# Reuse an existing ssh-agent on login, or create a new one
GOT_AGENT=0

if test -n "$(find /tmp/ -maxdepth 1 -name 'ssh-*' -print -quit)"; then
    # found
    for FILE in $(find /tmp/ssh-* -type s -user ${LOGNAME} -name "agent.[0-9]*" 2>/dev/null); do
        SOCK_PID=${FILE##*.}
        PID=$(ps -fu${LOGNAME} | awk '/ssh-agent/ && ( $2=='${SOCK_PID}' || $3=='${SOCK_PID}' || $2=='${SOCK_PID}' +1 ) {print $2}')
        SOCK_FILE=${FILE}
        SSH_AUTH_SOCK=${SOCK_FILE}
        export SSH_AUTH_SOCK
        SSH_AGENT_PID=${PID}
        export SSH_AGENT_PID
        ssh-add -l >/dev/null
        if [ $? != 2 ]; then
            GOT_AGENT=1
            echo "Agent pid ${PID}"
            break
        fi
        echo "Skipping pid ${PID}"
    done
else
    # not found
fi

if [ $GOT_AGENT = 0 ]; then
    eval $(ssh-agent)
fi
ssh-add ~/.ssh/*_rsa

# exit trap
function killssh {
    ssh-agent -k
}

trap killssh EXIT