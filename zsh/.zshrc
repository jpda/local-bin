# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

#ZSH_THEME="random"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting macos kubectl)
source $ZSH/oh-my-zsh.sh

# export PATH="$PATH:$HOME/.dotnet/tools:$HOME/.local/bin:$HOME/Library/Python/3.10/bin"
# export PATH="$PATH:$HOME/.local/platform-tools"

# command -v lsd &>/dev/null && alias ls='lsd --group-dirs first'
# command -v gotop &>/dev/null && alias top='gotop -p'
# alias l='ls -l'
# alias la='ls -a'
# alias lla='ls -la'
# alias lt='ls --tree'

# # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.local/bin/.p10k/.p10k.zsh ]] || source ~/.local/bin/.p10k/.p10k.zsh

# Load p10k prompt addons
if [[ -d ~/.local/bin/.p10k ]] then ;
	for f in ~/.local/bin/.p10k/*.zsh; do
		source $f
	done
fi
