removing a file:
	rm

changing a file:
	chmod - use getfacl/setfacl combo to restore files
	chown - use find to log owner and group and then restore it from this  log
	chgrp - (subset of chown, TBD)

rewriting a file:
	cp - log destination
	mv - log destination
	ln  (TBD)
	mkdir (TBD)
