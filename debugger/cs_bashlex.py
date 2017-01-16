#!/usr/bin/env python

# TODO:
# this has similar functionality, look up how they visit AST
# https://github.com/idank/explainshell
#
# break command into commands that could be run separately. show them in nice
# CLI ASCII? and allow some actions
# - run only part of the command
# - show what flow through a pipeline

import sys
import bashlex

# import platform
# print('python version: ' + platform.python_version())

# print(*(sys.argv))
cmd=' '.join(sys.argv[1:])

# TODO: print this complete AST only when in some debugging mode
if True:
	print('~~ bashlex ast of: "' + cmd + '" ~~')
	parts = bashlex.parse(cmd)
	for ast in parts:
		print(ast.dump())
	print('~~ bashlex end ~~')
