# /bin/zsh
# jpd customizations - SSH from OneDrive
# in WSL use Windows System Environment Variable ONEDRIVECONSUMER
# Which can be set in Windows Settings -> System -> About -> Advanced System Settings -> Environment Variables
# Add one for WSLENV=ONEDRIVECONSUMER/p

if [[ -z "$OneDriveConsumer" && "$(uname -s)" == "Darwin" ]]; then
	OneDriveConsumer=/Volumes/Macintosh\ HD/Users/jpd/OneDrive
	export ONEDRIVECONSUMER=/Volumes/Macintosh\ HD/Users/jpd/OneDrive
fi

echo Looking for keys in: $OneDriveConsumer/ssh

# get keys from folder
keys=("${(@f)$(find "$ONEDRIVECONSUMER/ssh" -type f -print0 | xargs -0 grep -rl "PRIVATE KEY-")}")

cp "${keys[@]}" ~/.ssh/
dest_paths=("${keys[@]/#*\//$HOME/.ssh/}")
chmod 600 "${dest_paths[@]}"
ssh-add "${dest_paths[@]}"
