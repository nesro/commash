#!/usr/bin/env python

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

# TODO: now send information needed to commash and show the actual pipe flow
class pipenodevisitor(ast.nodevisitor):
	def visitpipe(self, n, parts):
		global menucnt
		# print(n.dump())
		spaces = ' ' * (n.pos[0])
		print(spaces + '^-- [' + str(menucnt) + '] show pipe flow')
		menucnt += 1

#-------------------------------------------------------------------------------

if __name__ == '__main__':
	print('~~~~ commash bashlex begin ~~~~\n')
	print(cmd)
	parsed = parser.parse(cmd)
	visitor = pipenodevisitor()
	for p in parsed:
		visitor.visit(p)
	print('Choose action: ')
	print('\n~~~~ commash bashlex end   ~~~~')



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
