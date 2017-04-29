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
cs_mode = ''

#-------------------------------------------------------------------------------

class pipenodevisitor(ast.nodevisitor):
	def visitfor(self, n, parts):
		global menucnt
		global cs_mode

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
				if cs_mode == 'menu':
					print(',dbg:    [' + str(menucnt) + '] show values of iterator: ' + iterator)
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

				if cs_mode == 'eval':
					print('CS_DBG_MARK_BEGIN' + str(menucnt))
					print('csit=0;for '+iterator+' in ' + header + '\ndo (( csit++ )); echo "( $csit ) '+iterator+' = $'+iterator+'"; done')
					print('CS_DBG_MARK_END' + str(menucnt))
				menucnt += 1

			if part.kind is 'list' or part.kind is 'command':
				spaces = ' ' * (part.pos[0])
				for_body=cmd[part.pos[0]:part.pos[1]]

				if cs_mode == 'menu':
					print(',dbg:    [' + str(menucnt) + '] run body with custom iterator: ' + iterator)

				#stdout = eval
				if cs_mode == 'eval':
					print('CS_DBG_MARK_BEGIN' + str(menucnt))
					print('read -p ",dbg: set iterator \\"'+iterator+'\\" value: " '+iterator+'; '+for_body)
					print('CS_DBG_MARK_END' + str(menucnt))
				menucnt += 1

				if cs_mode == 'menu':
					print(',dbg:    [' + str(menucnt) + '] step through iterations')

				if cs_mode == 'eval':
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
	cs_mode=sys.argv[3]

	if cs_mode != "out" and cs_mode != "eval" and cs_mode != "menu":
		print("cs_script_debugger.py: use \"out\" or \"eval\" as the 3rd arg", file=sys.stderr);
		print(cs_mode, file=sys.stderr)
		exit()

	with open(cs_file, 'r') as myfile:
		cmd = myfile.read()
	parsed = parser.parse(cmd)

	if False:
		print("\n<script>")
		print(cmd)
		print("</script>")

	if False:
		print("\n<bashlex ast dump>")
		for p in parsed:
			print(p.dump())
		print("</bashlex ast dump>\n")

	if False:
		print("\n<top lvl commands dump>")
		for p in parsed:
			print('----------')
			print(cmd[p.pos[0]:p.pos[1]])
		print("</top lvl commands  dump>\n")

	if cs_cnt >= len(parsed):
		if cs_mode == 'eval':
			print("CS_SCRIPT_END")
	else:
		if cs_mode == 'out':
			print(cmd[parsed[cs_cnt].pos[0]:parsed[cs_cnt].pos[1]])

		visitor = pipenodevisitor()
		visitor.visit(parsed[cs_cnt])
