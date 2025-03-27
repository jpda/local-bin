export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting macos kubectl)
source $ZSH/oh-my-zsh.sh

# Load normal adding
if [[ -d ~/.local/bin/zsh ]] then ;
	for f in ~/.local/bin/zsh/*.zsh; do
		source $f
	done
fi

[[ ! -f ~/.local/bin/.p10k/.p10k.zsh ]] || source ~/.local/bin/.p10k/.p10k.zsh

# Load p10k prompt addons
if [[ -d ~/.local/bin/.p10k ]] then ;
	for f in ~/.local/bin/.p10k/*.zsh; do
		source $f
	done
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi