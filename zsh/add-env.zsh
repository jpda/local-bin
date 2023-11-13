# /bin/zsh
if [[ -d ~/.local/etc ]] then ;
	for f in ~/.local/etc/*.env; do
		source $f
	done
fi
