#!/usr/bin/env python
# https://github.com/nesro/commash

#-------------------------------------------------------------------------------

from __future__ import print_function
import sys
from bashlex import parser, ast

#-------------------------------------------------------------------------------

if __name__ == '__main__':

	cs_cnt=int(sys.argv[1])
	cs_file=sys.argv[2]

	with open(cs_file, 'r') as myfile:
		cmd = myfile.read()
	parsed = parser.parse(cmd)

	if False:
		print("\n<script>", file=sys.stdout)
		print(cmd)
		print("</script>", file=sys.stdout)

	if False:
		print("\n<bashlex ast dump>", file=sys.stderr)
		for p in parsed:
			print(p.dump(), file=sys.stderr)
		print("</bashlex ast dump>\n", file=sys.stderr)

	if False:
		print("\n<top lvl commands dump>", file=sys.stderr)
		for p in parsed:
			print('----------')
			print(cmd[p.pos[0]:p.pos[1]])
		print("</top lvl commands  dump>\n", file=sys.stderr)

	cnt=0
	for p in parsed:
		if cnt == cs_cnt:
			print(cmd[p.pos[0]:p.pos[1]], file=sys.stdout)
			exit()
		cnt += 1
	print("CS_SCRIPT_END", file=sys.stdout)

			# print('cnt=', file=sys.stdout)
			# exit()
			# print(cnt, file=sys.stdout)
			# print(' cs_cnt=', file=sys.stdout)
			# print(cs_cnt, file=sys.stdout)
