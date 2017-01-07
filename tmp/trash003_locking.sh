#-------------------------------------------------------------------------------
# locking
# TODO: add $$ to the lockfile for multple instances of bash running
# XXX is locking mandatory?

# XXX: make a different approach for SSD and/or RO mounted filesystem
csfunc_locked() {
	if [[ -f $cs_LOCKFILE ]]; then
		return 0 # true, not locked
	else
		return 1
	fi
}

csfunc_lock() {
	$TOUCH $cs_LOCKFILE
}

csfunc_unlock() {
	$RM -f $cs_LOCKFILE
}
