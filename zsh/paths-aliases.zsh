# /bin/zsh
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:$HOME/.dotnet/tools:$HOME/.local/bin:$HOME/Library/Python/3.10/bin:$HOME/Library/Python/3.9/bin"
export PATH="$PATH:$HOME/.local/platform-tools"
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"

pwd_alias() { echo "$PWD"; }
loadenv() { source $(pwd_alias)/**/*.Development.env; }
loadconfigenv() { source $CONFIG_ROOT/*.env; }
hash() { printf $1 | openssl sha256 -binary | base64 ; }
secret() {
    echo -n "$1" | sha256sum | awk '{print $1}' | xxd -r -p | base64
}

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
alias refreshOfficeTemplates='cp -r $OneDriveConsumer/Documents/Custom\ Office\ Templates/ ~/Library/Group\ Containers/UBF8T346G9.Office/User\ Content.localized/Templates.localized'

alias workenv="cd $WORK_ROOT && loadenv"
alias isworkenv="cd $OIS_ROOT && loadenv"
alias runis='isworkenv && dotnet run -c Release'
alias hostis='ngrok --config $HOME/.local/etc/ngrok.yml,$OIS_ROOT/ngrok.yml start ois'
alias buildvm="$HOME/.local/bin/azbuildvm && loadconfigenv"
