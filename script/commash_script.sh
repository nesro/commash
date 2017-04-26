#!/bin/bash
# https://github.com/nesro/commash

# first draft of a script debugger
# this just use bashlex to step over top level commands
# TODO: be able to "step in" complex commands like if, for, while.
#       this shouldn't be _that_ hard imho

main() {

	if (( $# < 1 )); then
			echo "usage: $0 [script]"
			return
	fi

	local input_file=$1

	for (( cs_dbg_i=0 ; cs_dbg_i < 10000 ; cs_dbg_i++ )); do

		ret=$(./cs_script_debugger.py "$cs_dbg_i" <(grep -o '^[^#]*' $input_file))

		if [[ $ret == "CS_SCRIPT_END" ]]; then
			echo ",script debugger: input ended"
			break
		fi

		echo -e ",dbg: ${cs_dbg_i}th command:\n"
		echo "$ret"
		echo ""

		while :; do
			echo ",dbg: Choose:"
			echo ",dbg:    [r]un"
			echo ",dbg:    [q]uit"

			while read -rsn1 k; do
				case "$k" in
				r)
					echo -e ",dbg: eval:\n"
					eval "$ret"
					echo ""
					break 2
					;;
				q)
					break 3
					;;
				*)
					echo ",dbg: [r]un, [q]uit"
					;;
				esac
			done
		done

	done
}

main "$@"
