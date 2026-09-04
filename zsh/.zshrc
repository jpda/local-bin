export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting macos kubectl)

eval "$(brew shellenv)"

source "$ZSH/oh-my-zsh.sh"

if [[ -d ~/.local/bin/zsh ]]; then
    for f in ~/.local/bin/zsh/*.zsh; do
        source "$f"
    done
fi

[[ ! -f ~/.local/bin/.p10k/.p10k.zsh ]] || source ~/.local/bin/.p10k/.p10k.zsh

if [[ -d ~/.local/bin/.p10k/extras ]]; then
    for f in ~/.local/bin/.p10k/extras/*.zsh; do
        source "$f"
    done
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi