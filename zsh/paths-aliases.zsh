# /bin/zsh
export PATH="$PATH:$HOME/.dotnet/tools:$HOME/.local/bin:$HOME/Library/Python/3.10/bin"
export PATH="$PATH:$HOME/.local/platform-tools"

command -v lsd &>/dev/null && alias ls='lsd --group-dirs first'
command -v gotop &>/dev/null && alias top='gotop -p'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias today='icalBuddy -f -iep "title,datetime" -po "datetime,title" -df "%RD" eventsToday'