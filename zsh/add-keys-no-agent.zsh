# /bin/zsh
# jpd customizations - SSH from OneDrive
# in WSL use Windows System Environment Variable ONEDRIVECONSUMER
# Which can be set in Windows Settings -> System -> About -> Advanced System Settings -> Environment Variables
# Add one for WSLENV=ONEDRIVECONSUMER/p

if [[ $OneDriveConsumer -eq "" && $(uname -s) -eq "Darwin" ]]; then
    OneDriveConsumer=/Volumes/Macintosh\ HD/Users/jpd/OneDrive
    export ONEDRIVECONSUMER=/Volumes/Macintosh\ HD/Users/jpd/OneDrive
fi

echo Looking for keys in: $OneDriveConsumer/.ssh

# get ssh keys from onedrive
cp $ONEDRIVECONSUMER/ssh/*_rsa ~/.ssh/
chmod 600 ~/.ssh/*_rsa
ssh-add ~/.ssh/*_rsa