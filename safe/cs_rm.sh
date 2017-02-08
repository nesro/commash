#!/usr/bin/env bash
# https://github.com/nesro/commash

# commash wrapper for the rm command

#-------------------------------------------------------------------------------

# We don't want the user to get used to the "safe" version of rm.

# This function gets aliased to rm from cs_safe.sh
csfunc_rm() {
	echo ",: use ,rm for commash wrapper or /bin/rm for original rm"
}
alias ,rm=csfunc_rm_cswrapp

#-------------------------------------------------------------------------------

# TODO: alias sudo='sudo ' to find our alias when using sudo
#       we probably want to use this wrapper even as a root?


# man page: man rm
# source code: http://lingrok.org/xref/coreutils/src/rm.c
# tests: http://lingrok.org/xref/coreutils/tests/rm/

# there is something like this
# http://bazaar.launchpad.net/~fmarier/safe-rm/trunk/view/head:/safe-rm
# but we can provide much more functionality and safety


# wrapper that makes rm work as trash-put
# https://github.com/PhrozenByte/rmtrash

# there is some official trash specification?
# https://www.freedesktop.org/wiki/Specifications/trash-spec/

# motivation: I think that both rm -i and rm -I are terrible and not usable
# at all...

#-------------------------------------------------------------------------------
# testing:

# mkdir dir
# touch {a..z}.txt {a..m}.png a b c.arj dir/{n..z}.c
# rm *
#
#
# ,rm: [r]emove, [q]uit, move to [t]rash
#
# ,rm: more [d]etails
# ,rm: [r]emove
# ,rm: move to [t]rash
# ,rm: [q]uit

#-------------------------------------------------------------------------------

# https://github.com/andreafrancia/trash-cli/blob/master/trashcli/put.py#L128
csfunc_rm_trash() {


	#-----------------------------------------------------------------------------
	# just rename in place

	# TODO: logfile
	for f in $leftovers; do
		echo ",: mv \"$f\" \".cstrash_$f\""
		mv "$f" ".cstrash_$f"
	done
	return
	#-----------------------------------------------------------------------------


	# TODO: what about adding another choice here: [c]ompress. that will
	# compress the files before moving them into the trash?

	# TODO: XXX: we don't handle symlinks now

	# TODO: do I even want this?
	# create a directory for all the things we're going to "remove"
	# because we want an easy method to revert the changes

	# 1) create the trash direcoty with timestamp as a name
	local ts=$(date +%Y-%m-%d-%H-%M-%S-%N)
	local trashdir="$cs_ROOTDIR/trash/$ts"
	if [[ -d $trashdir ]]; then
		echo ",rm: Something went wrong. The dir $trashdir already exists."
		return
	fi
	mkdir -p $trashdir
	echo ",rm: trashdir is: $trashdir"

	# 1) move every file/direcoty to the trash directory
	for f in $leftovers; do

		if [[ ! -e $f ]]; then
			echo ",rm trash: path \"$f\" doesn't exists. skipping"
			continue
		fi

		local fullpath=$(realpath $f | sed 's/\//CSDELIM/g')
		echo ",rm trash: mv $f \$trashdir"
		mv $f $trashdir/$fullpath
	done

	# file with info what happened
	echo "PWD=$PWD" > $trashdir/info.txt
	echo "whoami=$(whoami)" >> $trashdir/info.txt
	echo "hostname=$(hostname)" >> $trashdir/info.txt

	echo ",rm trash: done"
}

# arguments are files to delete
csfunc_rm_show_to_delete() {
	declare -A rmarr # count files with the same extension
	declare -A rmarrorig # save the filename for case there is only one file

	echo ",rm: list of files to remove:"
	for f in $@; do
		local rp=$(realpath $f)

		if [[ "$rp" == $PWD ]]; then
			echo ",rm: you want to delete \"$f\" which is your current directory!"
			continue
		fi

		if [[ $PWD =~ ^$rp ]]; then
			echo ",rm: you want to delete \"$f\" which is a directory in your current path!"
			continue
		fi

		if [[ -d "$f" ]]; then
			# TODO: add check if we run rm with -d for empty dirs or with -r
			echo ",rm: you want to delete directory \"$f\""
			continue
		fi

		## for regular files
		# count files with the same extension
		# if there is only 1 file in the end. show it
		if [[ -f "$f" ]]; then
			if [[ "$f" =~ \. ]]; then
				local ext="${f##*.}"
			else
				local ext=none
			fi
			rmarr[$ext]=$(( ${rmarr[$ext]} + 1 ))
			rmarrorig[$ext]="$rp"
			continue
		else
			echo ",rm: file \"$f\" doesn't exists"
		fi

	done

	# print regular files to remove
	for i in "${!rmarr[@]}"; do
		if (( ${rmarr[$i]} == 1 )); then
			echo ",rm: removing file: ${rmarrorig[$i]} "
		else
			if [[ $i == none ]]; then
				echo ",rm: removing ${rmarr[$i]} file$(csfunc_plural_s ${rmarr[$i]}) without an extension"
			else
		  	echo ",rm: removing ${rmarr[$i]} file$(csfunc_plural_s ${rmarr[$i]}) with extension $i"
			fi
		fi
	done
} #csfunc_rm_show_to_delete



csfunc_rm_cswrapp()  {
	echo ",rm: exectuing commash rm wrapper"

#-------------------------------------------------------------------------------

	# options
	local opt_d=0	# removedir
	local opt_r=0 # recursive
	local opt_f=0 # force
	local opt_i_always=0 # interactive
	local opt_i_sometimes=0
	local opt_i_never=0

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
					i)
						opt_i_always=1
						;;
					I)
						opt_i_sometimes=1
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
		echo ",rm: missing operands. Nothing to do."
		return
	fi

	# handle the -I option
	if [[ $opt_i_sometimes == 1 ]]; then
		if (( $# < 3 )); then
			echo ",rm: the -I option don't take effect since you're going to remove less than three files"
		else
			echo ",rm: we will not stand in the way if you want to try the -I option"
			csfunc_run_cmd_ask /bin/rm $save_opts
			return
		fi
	fi

	# handle the -i option
	if [[ $opt_i_always == 1 ]]; then
		echo ",rm: we will not stand in the way if you want to try the -i option"
		csfunc_run_cmd_ask /bin/rm $save_opts
		return
	fi

	# these should be only the files we want to remove. i.e. no flags like -fr
	local leftovers="$@"
	# echo ",rm leftovers: $@"

#-------------------------------------------------------------------------------
# iterate over files to remove and warn user about things he probably don't
# want to remove

	# TODO I don't care about symlinks yet.
	csfunc_rm_show_to_delete "$leftovers"

#-------------------------------------------------------------------------------
# prompt user about the action

	# TODO: [v]iew all the files?, [c]ompress into trash?
	echo ",rm: [r]emove, [q]uit, move to [t]rash"
set +e
	# echo ",rm: rm $save_opts"
	while read -rn1 k; do
		echo
		case "$k" in
		r)
			/bin/rm $save_opts
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
			csfunc_rm_trash $leftovers
			break
			;;
		*)
			echo ",rm: press [r]un or [q]uit"
			;;
		esac
	done
}
