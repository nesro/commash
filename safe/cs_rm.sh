#!/usr/bin/env bash
# https://github.com/nesro/commash

# command rm

# man page: man rm
# source code: http://lingrok.org/xref/coreutils/src/rm.c

# there is something like we want:
# http://bazaar.launchpad.net/~fmarier/safe-rm/trunk/view/head:/safe-rm

csfunc_rm()  {
	echo ", wrapper for rm"
	echo ", we will write what we think and then you can decide if you really want to do this"


#-------------------------------------------------------------------------------

	local removedir=0
	local save_opts="$@"

#-------------------------------------------------------------------------------
	OPTIND=1
	optspec=":dfirvIR-:"
	while getopts "$optspec" optchar; do
			echo ",:optchar: $optchar"
	    case "$optchar" in
	        -)
	            case "$OPTARG" in
	                loglevel)
	                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
	                    echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
	                    ;;
	                loglevel=*)
	                    val=${OPTARG#*=}
	                    opt=${OPTARG%=$val}
	                    echo "Parsing option: '--${opt}', value: '${val}'" >&2
	                    ;;
	                *)
	                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
	                        echo "Unknown option --${OPTARG}" >&2
	                    fi
	                    ;;
	            esac;;
	        d)
	            removedir=1
	            ;;
					f)
						echo "force"
						;;
					r|R)
						echo "recursive"
						;;
	        v)
	            echo "Parsing option: '-${optchar}'" >&2
	            ;;
	        *)
	            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
	                echo "Non-option argument: '-${OPTARG}'" >&2
	            fi
	            ;;
	    esac
	done


		shift $((OPTIND-1))

		if [ "$1" = "--" ]; then
			echo "shifting"
			shift
		fi

		if (( $# < 1 )); then
			echo ", rm: missing operands. nothing to do"
			return
		fi

		echo ",rm leftovers: $@"

#-------------------------------------------------------------------------------



	for f in $@; do
		# this is where the important stuff needs to happen
		# TODO: find files with the same extension and just count them?
		# TODO: fins symlinks?

		if [[ $f == "." ]]; then
			echo ",rm: you want to remove \".\", the current dir is: \"$PWD\""
		elif [[ $f == ".." ]]; then
			echo ",rm: you want to remove \"..\", that dir is \"$(realpath ..)\""
		elif [[ -d "$f" ]]; then
			echo ",rm: you want to remove the directory \"$f\""
		else
			echo ",rm: removing file \"$f\""
		fi
	done


	echo ",rm: do you want to [r]un, [q]uit or move to [t]rash:"
	echo ",rm: rm $save_opts"
	while read -rn1 k; do
		echo
		case "$k" in
		r)
			rm $save_opts
			cs_extern_rc=$?

			# notify user about the error if there is any
			csfunc_safe_hooks_after

			return
			;;
		q)
			echo ",rm: no action"
			return 0
			;;
		t)
			# TODO: do I even want this?
			mkdir -p ~/.commash/trash
			builtin mv $save_opts ~/.commash/trash
		*)
			echo ",rm: press [r]un or [q]uit"
			;;
		esac
	done
}
