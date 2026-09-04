# /bin/zsh
# jpd customizations - SSH from OneDrive
# in WSL use Windows System Environment Variable ONEDRIVECONSUMER
# Which can be set in Windows Settings -> System -> About -> Advanced System Settings -> Environment Variables
# Add one for WSLENV=ONEDRIVECONSUMER/p

if [[ -z "${ONEDRIVECONSUMER:-}" && "$(uname -s)" == "Darwin" ]]; then
    export ONEDRIVECONSUMER="/Volumes/Macintosh HD/Users/jpd/OneDrive"
fi

ssh_keys_sync() {
    setopt local_options null_glob

    local src_dir dest_dir file
    local -a private_keys

    src_dir="${ONEDRIVECONSUMER}/ssh/keys"
    dest_dir="${HOME}/.ssh/keys"

    if [[ ! -d "$src_dir" ]]; then
        echo "ssh keys: source folder not found: $src_dir"
        return 0
    fi

    mkdir -p "$dest_dir"
    chmod 700 "$HOME/.ssh" "$dest_dir" 2>/dev/null || true

    rsync -a --delete "$src_dir"/ "$dest_dir"/ >/dev/null 2>&1 || {
        echo "ssh keys: sync failed"
        return 1
    }

    private_keys=()
    for file in "$dest_dir"/*; do
        [[ -f "$file" ]] || continue

        if [[ "$file" == *.pub ]]; then
            chmod 644 "$file" 2>/dev/null || true
        else
            chmod 600 "$file" 2>/dev/null || true
            if ssh-keygen -y -f "$file" >/dev/null 2>&1; then
                private_keys+=("$file")
            fi
        fi
    done

    if (( ${#private_keys[@]} == 0 )); then
        echo "ssh keys: none"
        return 0
    fi

    echo "ssh keys:"
    for file in "${private_keys[@]}"; do
        echo "  * ${file:t}"
        ssh-add "$file" >/dev/null 2>&1 || true
    done
}

ssh_keys_reset_agent() {
    setopt local_options null_glob

    local dest_dir file
    local -a private_keys

    dest_dir="${HOME}/.ssh/keys"

    if [[ ! -d "$dest_dir" ]]; then
        echo "ssh keys: destination folder not found: $dest_dir"
        return 0
    fi

    private_keys=()
    for file in "$dest_dir"/*; do
        [[ -f "$file" ]] || continue
        [[ "$file" == *.pub ]] && continue

        chmod 600 "$file" 2>/dev/null || true
        if ssh-keygen -y -f "$file" >/dev/null 2>&1; then
            private_keys+=("$file")
        fi
    done

    ssh-add -D >/dev/null 2>&1 || true

    if (( ${#private_keys[@]} == 0 )); then
        echo "ssh keys: agent cleared, no keys to load"
        return 0
    fi

    echo "ssh keys reloaded:"
    for file in "${private_keys[@]}"; do
        if ssh-add "$file" >/dev/null 2>&1; then
            echo "  * ${file:t}"
        else
            echo "  * ${file:t} (failed)"
        fi
    done
}

ssh_keys_reconcile() {
    ssh_keys_sync && ssh_keys_reset_agent
}

ssh_keys_sync
