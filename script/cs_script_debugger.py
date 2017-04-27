#!/usr/bin/env python
# https://github.com/nesro/commash

#-------------------------------------------------------------------------------

from __future__ import print_function
import sys
from bashlex import parser, ast

#-------------------------------------------------------------------------------

# global variables
menucnt = 1
cmd = ''

#-------------------------------------------------------------------------------

class pipenodevisitor(ast.nodevisitor):
	def visitfor(self, n, parts):
		global menucnt
		iterator=None
		header_from=0
		header_to=0
		header=None
		for_body=None

		for part in parts:
			# find the string representing the iterator
			if part.kind is 'word' and iterator is None:
				spaces = ' ' * (part.pos[0])
				iterator=part.word

				#stderr = show
				print(',dbg:    [' + str(menucnt) + '] show values of iterator: ' + iterator, file=sys.stderr)
				#menucnt += 1

			# find the string representing the list of things we want to iterate
			# for now, I will just cut things between "in" and ";"
			if part.kind is 'reservedword' and part.word == 'in':
				header_from=part.pos[0]+3 # 3 == 'in '
				#print(' ' * header_from + '^-- [' + str(menucnt) + '] iterate', file=sys.stderr)

			if part.kind is 'reservedword' and part.word == 'do':
				header_to=part.pos[0]
				header=cmd[header_from:header_to]
				assert iterator != 'csit'

				#stdout = eval
				print('CS_DBG_MARK_BEGIN' + str(menucnt))
				print('csit=0;for '+iterator+' in ' + header + '\ndo (( csit++ )); echo "( $csit ) '+iterator+' = $'+iterator+'"; done')
				print('CS_DBG_MARK_END' + str(menucnt))
				menucnt += 1

			if part.kind is 'list' or part.kind is 'command':
				spaces = ' ' * (part.pos[0])
				for_body=cmd[part.pos[0]:part.pos[1]]

				#stderr = show
				print(',dbg:    [' + str(menucnt) + '] run body with custom iterator: ' + iterator, file=sys.stderr)
				#stdout = eval
				print('CS_DBG_MARK_BEGIN' + str(menucnt))
				print('read -p ",dbg: set iterator \\"'+iterator+'\\" value: " '+iterator+'; '+for_body)
				print('CS_DBG_MARK_END' + str(menucnt))
				menucnt += 1

				#stderr = show
				print(',dbg:    [' + str(menucnt) + '] step through iterations', file=sys.stderr)
				#stdout = eval
				print('CS_DBG_MARK_BEGIN' + str(menucnt))
				print('csit=0\n'\
					'for '+iterator+' in '+ header +'\ndo ' \
					'(( csit++ ))\n' \
					'echo ",dbg: $csit iteration, '+iterator+'=$'+iterator+'"\n' + \
					for_body + \
					"""
	while :; do
		echo ",dbg: Choose: [n]ext, [b]reak"
		while read -rsn1 k; do
			case $k in
				n)
					echo ",dbg: next!"
					break 2
					;;
				b)
					echo ",dbg: break!"
					break 3
					;;
				*)
					;;
			esac
		done
	done
""" \
					'done')
				print('CS_DBG_MARK_END' + str(menucnt))
				menucnt += 1


				#print(part, file=sys.stderr)
				#print('part: '+ cmd[part.pos[0]:part.pos[1]], file=sys.stderr)
		return True

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

	if cs_cnt >= len(parsed):
		print("CS_SCRIPT_END", file=sys.stdout)
	else:
		print(cmd[parsed[cs_cnt].pos[0]:parsed[cs_cnt].pos[1]], file=sys.stderr)
		print("", file=sys.stderr)
		print(",dbg: Choose:", file=sys.stderr)
		print(",dbg:    [r]un", file=sys.stderr)
		print(",dbg:    [q]uit", file=sys.stderr)

		visitor = pipenodevisitor()
		visitor.visit(parsed[cs_cnt])
