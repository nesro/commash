#!/usr/bin/python

# this is really a mess now

import sys
import bashlex

print('')

#with open(sys.argv[1], 'r') as myfile:
#        data = myfile.read().replace('\n\n', '\n')

#parts = bashlex.parse(sys.argv[1])

parts = bashlex.parse(' '.join(sys.argv[1:]))

#print(data)

#parts = bashlex.parse(data)

for ast in parts:
    print ast.dump()


print('')

