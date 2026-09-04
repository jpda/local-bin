# /bin/zsh
# homebrew autocompletions
if type brew >/dev/null 2>&1; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

if command -v ngrok >/dev/null 2>&1; then
    eval "$(ngrok completion)"
fi
