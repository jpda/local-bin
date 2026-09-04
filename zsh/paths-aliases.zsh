# /bin/zsh
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:$HOME/.dotnet/tools:$HOME/.local/bin:$HOME/Library/Python/3.10/bin:$HOME/Library/Python/3.9/bin"
export PATH="$PATH:$HOME/.aspire/bin"
export PATH="$PATH:$HOME/.local/platform-tools"
export PATH="$PATH:/opt/homebrew/opt/node@20/bin"

hashb64() { printf "%s" "$1" | openssl sha256 -binary | base64; }
secret() {
    printf "%s" "$1" | shasum -a 256 | awk '{print $1}' | xxd -r -p | base64
}

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

command -v lsd &>/dev/null && alias ls='lsd --group-dirs first'
command -v gotop &>/dev/null && alias top='gotop -p'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias events='icalBuddy -ea -f -iep "title,datetime" -po "datetime,title" -df "%RD"'
alias today='events -n eventsToday'
alias upnext='events -n -li 1 eventsToday'
alias tomorrow='events eventsFrom:"tomorrow" to:"tomorrow"'
alias cleandotnet='find . -type d \( -name "obj" -o -name "bin" \) -exec rm -rf {} +'

refreshOfficeTemplates() {
    cp -r \
        "$ONEDRIVECONSUMER/Documents/Custom Office Templates/" \
        "$HOME/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"
}

cft() {
	local BASE_DIR="$HOME/.local/apps/chrome"
	local BINARY="$BASE_DIR/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
	local PROFILE="$BASE_DIR/profiles"
	local INSTALLER="$HOME/.local/bin/install_cft.sh"

	if pgrep -f "Google Chrome for Testing" >/dev/null; then
		true
	else
		if [[ -x "$INSTALLER" ]]; then
			"$INSTALLER"
			if [[ $? -ne 0 ]]; then
				echo "⚠️  Update check failed. Attempting to launch installed version..."
			fi
		else
			echo "⚠️  Installer script not found. Skipping update check."
		fi
	fi

	if [[ ! -x "$BINARY" ]]; then
		echo "❌ Binary not found. Install failed or script path is wrong."
		return 1
	fi

	mkdir -p "$PROFILE"
	nohup "$BINARY" \
		--user-data-dir="$PROFILE" \
		--no-first-run \
		--no-default-browser-check \
		"$@" >/dev/null 2>&1 &
}

# Add to your ~/.zshrc (or ~/.bashrc)
runenv() {
	local -a matches
	matches=( *Development.env(N) )
	local envfile="${ENVFILE:-${matches[1]:-.env}}"
	# local envfile="${ENVFILE:-$(ls *Development.env 2>/dev/null | head -n1)}"
	# envfile="${envfile:-.env}"

	if [[ ! -f "$envfile" ]]; then
		echo "No $envfile found in current directory"
		return 1
	fi

	# Read the .env file, skip comments and blank lines
	local env_args=()
	while IFS= read -r line || [[ -n "$line" ]]; do
		# Strip leading/trailing whitespace
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"
		# Skip comments and empty lines
		[[ -z "$line" || "$line" == \#* ]] && continue
		env_args+=("$line")
	done <"$envfile"

	env "${env_args[@]}" "$@"
}
