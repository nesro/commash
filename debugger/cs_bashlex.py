#!/usr/bin/env python
# https://github.com/nesro/commash

# READ THIS:
#
# commash bashlex wrapper:
#
# 1) get a bash command to be executed from arguments, this script is called as:
#    local bashlex_out=$(~/.commash/debugger/cs_bashlex.py "$cmd")
# 2) print choices in a nice way for the user to the stderr
# 3) print choices in a nice way for bash to the stdout
# 4) exit the script and let bash do the rest
#

# BUGS:
# multiline commands are not printed nicely. idk if it's worth it to
# support that now
#
# echo "a
# b" | grep a
#            ^-- [1] show pipe flow
#

#-------------------------------------------------------------------------------


# TODO:
# this has similar functionality, look up how they visit AST
# https://github.com/idank/explainshell
#
# break command into commands that could be run separately. show them in nice
# CLI ASCII? and allow some actions
# - run only part of the command
# - show what flow through a pipeline

# yacc grammar
# http://git.savannah.gnu.org/cgit/bash.git/tree/parse.y?id=df2c55de9c87c2ee8904280d26e80f5c48dd6434#n388

#-------------------------------------------------------------------------------
# some ideas worth implementing?
#
# echo a | grep a
#        ^-- [1] echo a
#
# for a in files*; do ...; done
# ^-- [1] print for cycle iterators
#
#-------------------------------------------------------------------------------

from __future__ import print_function

import sys
from bashlex import parser, ast
cmd = ' '.join(sys.argv[1:])

menucnt = 1

#-------------------------------------------------------------------------------

# import platform
# print('python version: ' + platform.python_version())

#-------------------------------------------------------------------------------

# ast.nodevisitor class is here:
# https://github.com/idank/bashlex/blob/master/bashlex/ast.py#L28

#-------------------------------------------------------------------------------

class pipenodevisitor(ast.nodevisitor):
	# XXX: I'm stupid. I don't need this to traverse recursively
	# def visitpipeline(self, n, parts):
	# 	print('visitpipeline!', file=sys.stderr)
	# 	return True
	#
	# def visitcommand(self, n, parts):
	# 	print('visitcommand!', file=sys.stderr)
	# 	return True
	#
	# def visitword(self, n, word):
	# 	print('visitword!', file=sys.stderr)
	# 	return True

	def visitpipe(self, n, parts):
		global menucnt
		# print(n.dump())
		spaces = ' ' * (n.pos[0])

		# stderr for user
		print(spaces + '^-- [' + str(menucnt) + '] show pipe flow: '+ cmd[0:n.pos[0]] +'', file=sys.stderr)

		# stdout for bash
		print(cmd[0:n.pos[0]])
		menucnt += 1
		return True


	def visitcommandsubstitution(self, n, command):
		global menucnt
		spaces = ' ' * (n.pos[0])

		# stderr for user
		print(spaces + '^-- [' + str(menucnt) + '] show substituion: '+ cmd[n.pos[0]:n.pos[1]] +'', file=sys.stderr)

		# stdout for bash
		print('echo "' + cmd[n.pos[0]:n.pos[1]] + '"')
		menucnt += 1


#-------------------------------------------------------------------------------
if __name__ == '__main__':
	# print('~~~~ commash bashlex begin ~~~~\n')


	parsed = parser.parse(cmd)

	if False:
		print("\n<bashlex ast dump>", file=sys.stderr)
		for p in parsed:
			print(p.dump(), file=sys.stderr)
		print("</bashlex ast dump>\n", file=sys.stderr)

	print(cmd, file=sys.stderr)
	visitor = pipenodevisitor()
	for p in parsed:
		visitor.visit(p)

	# print >> sys.stderr, 'My error message'
	# print("fatal error", file=sys.stderr)

	# print('\n~~~~ commash bashlex end   ~~~~')
#-------------------------------------------------------------------------------

# print(*(sys.argv))

# TODO: print this complete AST only when in some debugging mode
# if True:
# 	print('~~ bashlex ast of: "' + cmd + '" ~~')
#
# 	parts = parser.parse(cmd)
#
#
#
# 	# for p in parts:
# 	# 	print(p.dump())
# 	# print('~~ ^^^^')
#
# 	positions = []
# 	for p in parts:
# 		print(p)
# 		visitor = nodevisitor(positions)
#         visitor.visit(p)
# 		# print(ast.dump())
#
# 	print('~~ bashlex end ~~')

# class innernodevisitor(ast.nodevisitor):
# 	def visitcommand(self, n, parts):
# 		print('<inner node>')
# 		print(n.dump())
# 		print(n.pos[0])
# 		print('</inner node>')
# 		print('')
# 		return False
#
# class nodevisitor(ast.nodevisitor):
# 	def __init__(self, positions):
# 		self.positions = positions
# 		print(positions)
#
# 	def visitpipeline(self, n, parts):
# 		print('<visitpipeline>')
# 		print('     <visitpipeline dump>')
# 		print(n.dump())
# 		print('     </visitpipeline dump>')
#
#  		for p in parts:
# 			inv = innernodevisitor()
# 			inv.visit(p)
#
# 		print('</visitpipeline>')
# 		print('')
#
# 		return True
#-------------------------------------------------------------------------------
