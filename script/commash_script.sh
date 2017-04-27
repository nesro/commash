#!/bin/bash
# https://github.com/nesro/commash

# first draft of a script debugger
# this just use bashlex to step over top level commands
# TODO: be able to "step in" complex commands like if, for, while.
#       this shouldn't be _that_ hard imho

#-------------------------------------------------------------------------------

main() {

	if (( $# < 1 )); then
			echo "usage: $0 [script]"
			return
	fi

	local input_file=$1

	for (( cs_dbg_i=0 ; cs_dbg_i < 10000 ; cs_dbg_i++ )); do

		echo -e "\n,dbg: Next command:\n"
		bashlex_out=$(./cs_script_debugger.py "$cs_dbg_i" <(grep -o '^[^#]*' $input_file))

		if [[ $ret == "CS_SCRIPT_END" ]]; then
			echo ",script debugger: input ended"
			break
		fi

		while :; do
			while read -rsn1 k; do
				case "$k" in
				r)
					echo -e ",dbg: eval begin:\n"
					eval "$ret"
					echo ""
					break 2
					;;
				q)
					break 3
					;;
				[0-9])
					local to_eval="$( echo "$bashlex_out" | awk '/CS_DBG_MARK_BEGIN'$k'/{flag=1;next}/CS_DBG_MARK_END'$k'/{flag=0}flag' )"

					if false; then
						echo ",dbg: echo to eval begin:"
						echo "$to_eval"
						echo ",dbg: echo to eval end."
					fi

					echo -e ",dbg: eval begin"
					eval "$to_eval"
					echo -e ",dbg: eval end"
					break 2
					;;
				*)
					echo -n "?"
					;;
				esac
			done
		done
	done
}

main "$@"
