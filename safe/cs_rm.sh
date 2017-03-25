#!/usr/bin/env bash
# https://github.com/nesro/commash

# commash wrapper for the rm command

cs_TRASHDIR="$cs_ROOTDIR/trash"

#-------------------------------------------------------------------------------

### we will use this trash "api"
# git clone https://github.com/andreafrancia/trash-cli.git
# cd trash-cli/
# python setup.py install --user

# trash-cli has really weird cli interface for us. our wrappers will be weird
# too

csfunc_trashcli_check() {
	local trash_restore_path
	trash_restore_path=$(type -p trash-restore)
	if [[ -z "$trash_restore_path" ]]; then
		echo ",: trash-cli with trash-restore command not installed, you can install it by runnnig:"
		echo ",: git clone https://github.com/nesro/trash-cli"
		echo ",: cd trash-cli"
		echo ",: python setup.py install --user"
		return 1
	fi
	return 0
}

csfunc_trashcli_rm() {
	trash_put=$(type -p trash-put)
	if [[ -z "$trash_put" ]]; then
		# TODO: make this path as a variable?
		if [[ -x ~/trash-cli/trash-put ]]; then
			trash_put=./trash-cli/trash-put
		else
			echo ",rm: trash-put command not found."
			return
		fi
	fi

	$trash_put "$1"
}

csfunc_trashcli_restore() {
	trash_restore=$(type -p trash-restore)
	if [[ -z "$trash_restore" ]]; then
		if [[ -x ~/trash-cli/trash-restore ]]; then
			trash_restore=./trash-cli/trash-restore
		else
			echo ",rm: trash-restore command not found."
			return
		fi
	fi

	$trash_restore --original-location "$(realpath "$1")"
}

csfunc_trashcli_discard() {
	trash_rm=$(type -p trash-rm)
	if [[ -z "$trash_rm" ]]; then
		if [[ -x ~/trash-cli/trash-rm ]]; then
			trash_put=./trash-cli/trash-rm
		else
			echo ",rm: trash-rm command not found."
			return
		fi
	fi
	$trash_rm "$1"
}

#-------------------------------------------------------------------------------

# We don't want the user to get used to the "safe" version of rm.
# This function gets aliased to rm from cs_safe.sh
csfunc_rm() {
	echo ",: Use ,rm for commash wrapper or /bin/rm for original rm."
}

# TODO: I can get non-expanded arguments (i.e.: *.txt) by:
# alias ,rm="set -f; csfunc_rm_cswrapp" and then "set +f" in the wrapper.
# but the shellcheck then complains about globbing, so we need to make
# an exception here. But I don't have time for it right now.
# http://stackoverflow.com/questions/11456403/stop-shell-wildcard-character-expansion
alias ,rm="csfunc_rm_cswrapp"
# TODO: pretype the fixed command?

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

#-------------------------------------------------------------------------------
# functions for summing up what to delete

# I want a nice sum-up what was deleted to quickly show to the user

# # based on:
# # http://unix.stackexchange.com/questions/18236/how-do-i-find-the-overlap-of-two-strings-in-bash
# common_prefix() {
#   local n=0
# 	if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ "$1" == "$2" ]]; then
# 		echo "!"
# 		return
# 	fi
#   while [[ "${1:n:1}" == "${2:n:1}" ]]; do
#     ((n++))
#   done
#   echo "${1:0:n}"
# }
#
# csfunc_rm_show_dirs() {
# 	while IFS='' read -r l || [[ -n "$l" ]]; do
# 		while IFS='' read -r l2 || [[ -n "$l2" ]]; do
# 			echo "l: $l l2: $l2 c: $(common_prefix "${l%/*}" "${l2%/*}")"
# 		done < "$f"
# 	done < "$f"
# }

#-------------------------------------------------------------------------------

csfunc_rm_trash_files() {
	local ts trashfile

	# TODO: This will probably mess up with files containing spaces
	# and or newlines.
	local leftovers=("$@")
	if ! csfunc_trashcli_check; then
		echo ",rm trash: trash-cli not available. No action."
		return
	fi

	mkdir -p $cs_TRASHDIR

	ts=$(date +%Y-%m-%d-%H-%M-%S-%N)
	trashfile="$cs_TRASHDIR/$ts"
	if [[ -f $trashfile ]]; then
		echo ",rm trash: Something went wrong. The file $trashfile already exists."
		return
	fi

	#echo ",rm: leftovers=$leftovers"

	for f in "${leftovers[@]}"; do
		echo ",rm trash: trashing file $(realpath $f)" # XXX XXX
		if ! trash-put "$f"; then
			echo "rm trash: trash-put \"$f\" has failed"
		fi

		realpath "$f" >> "$trashfile"
	done

	echo ",rm trash: Done. Use ,t or ,trash handle trashed bundles"
}


csfunc_rm_show_trashed_bundles() {
	local i=1

	for f in $cs_TRASHDIR/*; do
		t=${f##*/}

		if [[ ! $t =~ [0-9] ]]; then
			echo ",rm: invalid file in trash: $t"
			continue
		fi

		ry=$(echo "$t" | awk -F'-' '{ print $1 }')
		rm=$(echo "$t" | awk -F'-' '{ print $2 }')
		rd=$(echo "$t" | awk -F'-' '{ print $3 }')
		rH=$(echo "$t" | awk -F'-' '{ print $4 }')
		rM=$(echo "$t" | awk -F'-' '{ print $5 }')
		rS=$(echo "$t" | awk -F'-' '{ print $6 }')
		timestamp=$(date --date="$ry-$rm-$rd $rH:$rM:$rS" +"%s")

		#echo $t | awk -F'-' '{ print $1 "." $2 "." $3 " " $4 ":" $5 ":" $6 }'

		if (( show <= 0 )) || (( ( now - timestamp ) < show )); then
			echo -n "    [$i] "
			rms[$i]=$t
			echo -n "$ry.$rm.$rd $rH:$rM:$rS: "

			# XXX: This is very simple. I really want something more complex
			local cnt=0
			while IFS='' read -r line || [[ -n "$line" ]]; do
				if (( cnt < 1 )); then
					echo -n "$line "
				fi
				cnt=$(( cnt + 1 ))
			done < "$f"
			if (( cnt > 3 )); then
				echo -n "and $cnt others"
			fi


			# csfunc_rm_show_dirs "$f"
			echo
			#	echo "-----------"
		fi

		i=$(( i + 1 ))
	done
} # show trashed bundles

csfunc_rm_list_trash() {
	# TODO: regex to check the file name format?
	declare -a rms

	local ry rm rd rH rM rS timestamp now show
	now=$(date +"%s")
	show=$(( ${1:-0} * 60 ))

	if (( show <= 0)); then
		# echo ",rm restore: showing all results. to show only x minutes, use ,rmr [minutes]"
		:
	fi

	# echo ",rm: Commash uses the freedesktop.org trash located " \
	# 	"in /home/n/.local/share/Trash. Commash collects bundles of deleted files" \
	# 	" so you can restore all files deleted by a single ,rm command."

	if ! ls $cs_TRASHDIR/* >/dev/null 2>&1; then
		echo ",trash: no files in trash"
		return
	fi

	while :; do # menu loop begin
		echo ",rm: Choose the bundle:"
		csfunc_rm_show_trashed_bundles
		echo "    [q]uit"

		# echo "    [m]ore deleted bundles" XXX: limit showed bundles for 10?
		# echo ",rm: Choose number [0-9] and action:"
		# echo ",rm:     [s]how all trashed files"
		# echo ",rm:     [r]estore"
		# echo ",rm:     [d]iscard from trash"
		# echo ",rm: Or:"
		# echo ",rm      [m]ore trashed items: $total"
		# echo ",rm      [q]uit"
		#echo ",rm: [m]ore trashed files"

		while read -rsn1 n; do
			case "$n" in
				[0-9])
					while :; do
						local chosen_file="$cs_TRASHDIR/${rms[$n]}"

						echo ",rm: Chosen bundle ${rms[$n]}."
						echo "    [a]nother - select different bundle"
						echo "    [s]how all trashed files"
						echo "    [r]estore"
						echo "    [d]iscard from the trash"
						echo "    [q]uit"

						while read -rsn1 action; do
							case "$action" in
								a)
									break 3
									;;
								s)
									echo "Showing all deleted files:"
									while IFS='' read -r l || [[ -n "$l" ]]; do
												echo "    $l"
									done < "$chosen_file"
									break
									;;
								r)
									echo "restore"

									while IFS='' read -r l || [[ -n "$l" ]]; do
										echo ",rm: restoring $l"
										csfunc_trashcli_restore "$l"
									done < "$chosen_file"
									mv "$cs_TRASHDIR"/{,.restored-}"${rms[$n]}"

									echo ",rm: bundle restored."
									return
									;;
								d)
									echo "discard"
									while IFS='' read -r l || [[ -n "$l" ]]; do
										echo ",rm: discarding $l"
										csfunc_trashcli_discard "$l"
									done < "$chosen_file"
									mv "$cs_TRASHDIR"/{,.discarded-}"${rms[$n]}"
									echo ",rm: bundle discarded from the trash."
									return
									;;
								q)
									# echo ",rm: quit"
									return
									;;
								*)
									echo ",rm: please press [adsrq]"
									;;
							esac
						done
					done
					;;
				m)
					echo ",rm: show more"
					;;
				q)
					echo ",rm: quit"
					return
					;;
				*)
					echo ",rm: choose a number of deleted items, show [m]ore, or [q]uit"
					;;
			esac
		done

done # menu loop begin

	# echo "choose:"
	# choice=$(head -1)
	#
	# while IFS='' read -r line || [[ -n "$line" ]]; do
	# 	echo ",rm restore: restoring $line"
	# 	csfunc_trashcli_restore "$line"
	# done < "$cs_TRASHDIR/${rms[$choice]}"
	#
	# mv "$cs_TRASHDIR"/{,.restored-}"${rms[$choice]}"
}
alias ,t="csfunc_rm_list_trash"
alias ,trash="csfunc_rm_list_trash"

# arguments are files to delete
csfunc_rm_show_to_delete() {
	declare -A rmarr # count files with the same extension
	declare -A rmarrorig # save the filename for case there is only one file
	local rp

	echo ",rm: Files to remove:"
	for f in "$@"; do
		rp=$(realpath $f)

		if [[ "$rp" == "$PWD" ]]; then
			echo ",rm:    You want to delete \"$f\" which is your current directory. !"
			continue
		fi

		if [[ $PWD =~ ^$rp ]]; then
			echo ",rm:    You want to delete \"$f\" which is a directory in your current path. !"
			continue
		fi

		if [[ -d "$f" ]]; then
			# TODO: add check if we run rm with -d for empty dirs or with -r
			echo ",rm:    Directory: \"$f\""
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
			echo ",rm:    File \"$f\" doesn't exists !"
		fi
	done

	# print regular files to remove
	for i in "${!rmarr[@]}"; do
		if (( ${rmarr[$i]} == 1 )); then
			echo ",rm:    Removing file: \"${rmarrorig[$i]}\""
		else
			if [[ $i == none ]]; then
				echo ",rm:    ${rmarr[$i]} file$(csfunc_plural_s ${rmarr[$i]}) without extension"
			else
				echo ",rm:    ${rmarr[$i]} file$(csfunc_plural_s ${rmarr[$i]}) with extension \"$i\""
			fi
		fi
	done
} #csfunc_rm_show_to_delete



csfunc_rm_cswrapp()  {
	# set +f
	# echo ",rm: exectuing commash rm wrapper"

#-------------------------------------------------------------------------------

	# options
	# local opt_d=0	# removedir
	# local opt_r=0 # recursive
	# local opt_f=0 # force
	local opt_i_always=0 # interactive
	local opt_i_sometimes=0
	# local opt_i_never=0

	local save_opts=("$@")

#-------------------------------------------------------------------------------
	OPTIND=1
	optspec=":dfirvIR-:"
	while getopts "$optspec" optchar; do
			#echo ",:optchar: $optchar"
	    case "$optchar" in
	        -)
	            case "$OPTARG" in
	                loglevel)
	                    val="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
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
						echo ",rm: todo removedir"
	            # removedir=1
	            ;;
					f)
						#echo "force"
						:
						;;
					i)
						opt_i_always=1
						;;
					I)
						opt_i_sometimes=1
						;;
					r|R)
						#echo "recursive"
						:
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
			csfunc_run_cmd_ask /bin/rm "${save_opts[@]}"
			return
		fi
	fi

	# handle the -i option
	if [[ $opt_i_always == 1 ]]; then
		echo ",rm: we will not stand in the way if you want to try the -i option"
		csfunc_run_cmd_ask /bin/rm "${save_opts[@]}"
		return
	fi

	# these should be only the files we want to remove. i.e. no flags like -fr
	# local leftovers="$*"
	# XXX test me pls
	local leftovers=("$@")

	# echo ",rm leftovers: $@"

#-------------------------------------------------------------------------------
# iterate over files to remove and warn user about things he probably don't
# want to remove

	# TODO I don't care about symlinks yet.
	csfunc_rm_show_to_delete "${leftovers[@]}"

#-------------------------------------------------------------------------------
# prompt user about the action

	# TODO: [c]ompress into trash?
	# echo ",rm: [r]emove, [q]uit, move to [t]rash"

	echo ",rm: Choose:"
	echo ",rm:    [r]emove files"
	echo ",rm:    [q]uit"
	echo ",rm:    [t]rash files"
	#echo ",rm:    [d]elayed removal"

	# echo ",rm: rm $save_opts"
	while read -rn1 k; do
		echo
		case "$k" in
		r)
			echo ",rm: /bin/rm ${save_opts[*]}"
			/bin/rm "${save_opts[@]}"
			cs_extern_rc=$?

			# notify user about the error if there is any
			csfunc_safe_hooks_after

			return
			;;
		q)
			return
			;;
		t)
			csfunc_rm_trash_files "${leftovers[@]}"
			break
			;;
		*)
			echo ",rm: press [r]un, [t]rash, or [q]uit"
			;;
		esac
	done
}
