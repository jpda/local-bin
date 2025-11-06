# Git branch summary with "last change" timestamps
# ai generated, use caution

git-summary() {
    setopt local_options
    setopt pipefail
    unsetopt nomatch 2>/dev/null || true

    # Colors (safe)
    local c_reset="" c_dim="" c_red="" c_green="" c_yellow="" c_blue="" c_magenta="" c_cyan=""
    _gs_safe_colors() {
        if [[ -n "${ZSH:-}" && -r "${ZSH}/lib/colors.zsh" ]]; then
            source "${ZSH}/lib/colors.zsh" 2>/dev/null || true
        fi
        if autoload -U colors 2>/dev/null && colors 2>/dev/null; then
            c_reset=${reset_color}
            c_red=$fg[red]; c_green=$fg[green]; c_yellow=$fg[yellow]; c_blue=$fg[blue]
            c_magenta=$fg[magenta]; c_cyan=$fg[cyan]
            if (( ${+terminfo[dim]} )); then
                c_dim=${terminfo[dim]}
            fi
        elif command -v tput >/dev/null 2>&1; then
            c_reset=$(tput sgr0 || true)
            c_red=$(tput setaf 1 || true); c_green=$(tput setaf 2 || true); c_yellow=$(tput setaf 3 || true)
            c_blue=$(tput setaf 4 || true); c_magenta=$(tput setaf 5 || true); c_cyan=$(tput setaf 6 || true)
            c_dim=$(tput dim 2>/dev/null || true)
        fi
    }
    _gs_safe_colors

    # Ensure we're in a git repo
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "${c_red}Not a git repository${c_reset}" >&2
        return 1
    fi

    # Resolve default branch (prefers origin, then any remote, then local main/master)
    _gs_resolve_default_branch() {
        local def=""
        def=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
        [[ -n "$def" ]] && { echo "$def"; return; }
        def=$(git symbolic-ref -q --short refs/remotes/*/HEAD 2>/dev/null | sed 's#^.*/##' | head -n1 || true)
        [[ -n "$def" ]] && { echo "$def"; return; }
        local b
        for b in main master; do
            if git show-ref --verify --quiet "refs/heads/$b"; then echo "$b"; return; fi
        done
        git rev-parse --abbrev-ref HEAD
    }
    local DEFAULT_BRANCH; DEFAULT_BRANCH=$(_gs_resolve_default_branch)

    # Gather local branches
    local -a LOCAL_BRANCHES=()
    while IFS= read -r b; do
        [[ -n "$b" ]] && LOCAL_BRANCHES+=("$b")
    done < <(git for-each-ref --format='%(refname:short)' refs/heads | sort)

    # Helpers
    _gs_ahead_behind_upstream() {
        local b=$1
        if git rev-parse --abbrev-ref "$b@{upstream}" >/dev/null 2>&1; then
            git rev-list --count --left-right "${b}@{upstream}...${b}" 2>/dev/null | awk '{print $1" "$2}'
        else
            echo "NA NA"
        fi
    }
    _gs_upstream_gone() {
        local b=$1
        if git rev-parse --abbrev-ref "$b@{upstream}" >/dev/null 2>&1; then
            git rev-parse "$b@{upstream}" >/dev/null 2>&1 || return 0   # gone
            return 1
        else
            return 2
        fi
    }
    _gs_unmerged_vs_default() {
        local b=$1
        if [[ "$b" == "$DEFAULT_BRANCH" ]]; then
            echo 0; return
        fi
        git rev-list --count --right-only "${DEFAULT_BRANCH}...${b}" 2>/dev/null || echo 0
    }
    # Format a ref's last commit date as "YYYY-MM-DD HH:MM"
    _gs_last_change() {
        local ref=$1
        # Use committerdate for “last change” feeling; fallback to author if needed
        local d
        d=$(git log -1 --date=format:'%Y-%m-%d %H:%M' --format='%cd' -- "$ref" 2>/dev/null) || d=""
        if [[ -z "$d" ]]; then
            # Try resolving ref to a commit explicitly (handles fully qualified refs)
            local sha
            sha=$(git rev-parse -q --verify "$ref^{commit}" 2>/dev/null) || sha=""
            if [[ -n "$sha" ]]; then
                d=$(git show -s --date=format:'%Y-%m-%d %H:%M' --format='%cd' "$sha" 2>/dev/null) || d=""
            fi
        fi
        if [[ -z "$d" ]]; then
            echo "—"
        else
            echo "$d"
        fi
    }

    # Buckets
    local -a unpushed=() upstream_gone_list=() no_upstream=() unmerged_vs_default_list=()
    local -a gone_remote_tracking=()
    local -A ab_counts=()

    # Compute local branch statuses
    local b ahead behind commits last
    for b in "${LOCAL_BRANCHES[@]}"; do
        read -r ahead behind <<<"$(_gs_ahead_behind_upstream "$b")"
        last=$(_gs_last_change "refs/heads/${b}")
        if [[ "$ahead" != "NA" ]]; then
            ab_counts[$b]="$ahead $behind"
            if (( ahead > 0 )); then
                unpushed+=("$b (ahead $ahead, behind $behind)  ${c_dim}last: $last${c_reset}")
            fi
            if _gs_upstream_gone "$b"; then
                upstream_gone_list+=("$b (was tracking $(git rev-parse --abbrev-ref "$b@{upstream}" 2>/dev/null || echo '?'))  ${c_dim}last: $last${c_reset}")
            fi
        else
            no_upstream+=("$b  ${c_dim}last: $last${c_reset}")
        fi
        commits=$(_gs_unmerged_vs_default "$b")
        if (( commits > 0 )); then
            unmerged_vs_default_list+=("$b (+${commits} vs ${DEFAULT_BRANCH})  ${c_dim}last: $last${c_reset}")
        fi
    done

    # Detect remote-tracking branches that are gone on remote (stale)
    local line rt rt_last
    while IFS= read -r line; do
        rt=$(sed -n 's/.*would prune] \([^ ]\+\)$/\1/p' <<<"$line")
        if [[ -n "$rt" ]]; then
            # Try to show last change for the remote-tracking ref if still present locally
            rt_last=$(_gs_last_change "refs/remotes/${rt}")
            gone_remote_tracking+=("${rt}  ${c_dim}last: ${rt_last}${c_reset}")
        fi
    done < <(git remote -v | awk '{print $1}' | sort -u | xargs -I{} git remote prune --dry-run {} 2>/dev/null)

    # Current branch
    local CURRENT_BRANCH
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")

    # Printing helpers
    _gs_section() {
        local title=$1
        echo "${c_magenta}==> ${title}${c_reset}"
    }
    _gs_print_list() {
        local -a arr
        arr=("$@")
        if (( ${#arr[@]} == 0 )); then
            echo "    (none)"
            return
        fi
        local item
        for item in "${arr[@]}"; do
            echo "    • $item"
        done
    }

    # Print report
    echo "${c_blue}Git Branch Summary${c_reset}"
    echo "${c_dim}Repo:${c_reset} $(basename "$(git rev-parse --show-toplevel)")"
    echo "${c_dim}Current:${c_reset} $CURRENT_BRANCH"
    echo "${c_dim}Default:${c_reset} $DEFAULT_BRANCH"
    echo

    _gs_section "Local branches with unpushed commits"
    _gs_print_list "${unpushed[@]}"
    echo

    _gs_section "Local branches tracking a remote whose upstream is gone"
    _gs_print_list "${upstream_gone_list[@]}"
    echo

    _gs_section "Local branches with no upstream configured"
    _gs_print_list "${no_upstream[@]}"
    echo

    _gs_section "Local branches with commits not in ${DEFAULT_BRANCH}"
    _gs_print_list "${unmerged_vs_default_list[@]}"
    echo

    _gs_section "Stale remote-tracking branches (would prune)"
    _gs_print_list "${gone_remote_tracking[@]}"
    echo

    echo "${c_cyan}Hints:${c_reset}"
    echo "    • Show last change for one branch: git log -1 --date=human --format='%cd %h %s' <branch>"
    echo "    • Prune stale remote-tracking branches: git remote prune <remote>"
    echo "    • Clean local branches merged into ${DEFAULT_BRANCH}: git branch --merged ${DEFAULT_BRANCH}"
}
