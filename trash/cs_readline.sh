
CS_READLINE_BUFFER=''


cs_readline_setup() {
	csfunc_inside=1
	
	bind -x '"\C-o":cs_readline_hook'
	bind 'RETURN: "\C-o\n"'
	
	echo "cs_readline has been set up"
	
	csfunc_inside=0
}


cs_readline_hook() {
	csfunc_inside=1
	
	if [[ -n "$READLINE_LINE" ]]; then
		echo ",readline: $READLINE_LINE"
		
		CS_READLINE_BUFFER="$CS_READLINE_BUFFER $READLINE_LINE"

	fi
	
	csfunc_inside=0
}


# this function will get called in the promt command
cs_readline_prompt() {
	csfunc_inside=1
	
	
	CS_READLINE_BUFFER=''
	
	csfunc_inside=0
}

# this function will get called in the debug trap
cs_readline_debug_trap() {
	csfunc_inside=1
	
	echo "readline buffer:"
	echo "$CS_READLINE_BUFFER"
	
	csfunc_inside=0
}

echo "cs_readline.sh sourced"

