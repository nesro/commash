#!/bin/bash
# https://github.com/nesro/commash

set -u

# test me:
# cd ~/.commash/script/
# ./commash_script.sh test.sh

# first draft of a script debugger
# this just use bashlex to step over top level commands
# TODO: be able to "step in" complex commands like if, for, while.
#       this shouldn't be _that_ hard imho

# TODO: FIXME: running the py script three times is not ok

# XXX: bashlex fail when the input starts with a newline

#-------------------------------------------------------------------------------

# first arg is the code to debug
csfunc_dbg_src() {
	local src_to_dbg="$1"
	local src_ident="$2"
	local src_ident_str=""

	# a loop is used here becuase printing nothing with seq/printf is hard
	local for_i
	for (( for_i=0; for_i < $src_ident ; for_i++ )); do
		 src_ident_str="$src_ident_str  "
	done
	#echo "src_ident=$src_ident,src_ident_str=\"$src_ident_str\""

	local bashlex_out bashlex_eval bashlex_menu cs_dbg_i

	for (( cs_dbg_i=0 ; cs_dbg_i < 10000 ; cs_dbg_i++ )); do

		if false; then
			echo "src>>>\"$src_to_dbg\"<<<src"
		fi

		# XXX:
		bashlex_out="$(./cs_script_debugger.py "$cs_dbg_i" "$src_to_dbg" "out" $src_ident)"
		bashlex_eval="$(./cs_script_debugger.py "$cs_dbg_i" "$src_to_dbg" "eval" $src_ident)"
		bashlex_menu="$(./cs_script_debugger.py "$cs_dbg_i" "$src_to_dbg" "menu" $src_ident)"

		if [[ $bashlex_eval == "CS_SCRIPT_END" ]]; then
			echo "$src_ident_str,dbg: input in context has ended"
			break
		fi

		if false; then
			echo "bashlex_out=\"$bashlex_out\"(<bashlex_out)"
			echo "bashlex_eval=\"$bashlex_eval\"(<bashlex_eval)"
			echo "bashlex_menu=\"$bashlex_menu\"(<bashlex_menu)"
		fi

		echo -e "$src_ident_str,dbg: Next command:\n" # (cnt=$cs_dbg_i)

		echo "$bashlex_out"

		echo ""
		echo "$src_ident_str,dbg: Choose:"
		if [[ $bashlex_menu == *[![:space:]]* ]]; then
			echo "$bashlex_menu"
		fi
		echo "$src_ident_str,dbg:    [r]un"
		echo "$src_ident_str,dbg:    [q]quit	"

		while :; do
			while read -rsn1 k; do
				case "$k" in
				r)
					echo -e "$src_ident_str,dbg: eval begin:\n"
					eval "$bashlex_out"
					echo -e "\n$src_ident_str,dbg: eval end"
					break 2
					;;
				q)
					break 3
					;;
				[0-9])
					local to_eval="$( echo "$bashlex_eval" | awk '/CS_DBG_MARK_BEGIN'$k'/{flag=1;next}/CS_DBG_MARK_END'$k'/{flag=0}flag' )"

					if false; then
						echo "$src_ident_str,dbg: echo to eval begin:"
						echo "$to_eval"
						echo "$src_ident_str,dbg: echo to eval end."
					fi

					echo -e "$src_ident_str,dbg: eval begin"
					eval "$to_eval"
					echo -e "\n$src_ident_str,dbg: eval end"
					break 2
					;;
				*)
					echo -n "?"
					break
					;;
				esac
			done
		done
	done
}

main() {
	if (( $# < 1 )); then
			echo "usage: $0 [script]"
			return
	fi

	local input_file=$1

	# bashlex cannot handle comments and newlines (probably?), so we need to
	# grep first
	csfunc_dbg_src "$(grep -o '^[^#]*' "$input_file")" 0
}

main "$@"
