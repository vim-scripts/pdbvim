#! /usr/bin/env python

"""A Python debugger."""

# (See pdb.doc for documentation.)

import sys
import linecache
import cmd
import bdb
import pdb
from repr import repr as _saferepr
import os
import re

__all__ = ["run", "pm", "Pdb", "runeval", "runctx", "runcall", "set_trace",
           "post_mortem", "help"]

def find_function(funcname, filename):
    cre = re.compile(r'def\s+%s\s*[(]' % funcname)
    try:
        fp = open(filename)
    except IOError:
        return None
    # consumer of this info expects the first line to be 1
    lineno = 1
    answer = None
    while 1:
        line = fp.readline()
        if line == '':
            break
        if cre.match(line):
            answer = funcname, filename, lineno
            break
        lineno = lineno + 1
    fp.close()
    return answer


# Interaction prompt line will separate file and call info from code
# text using value of line_prefix string.  A newline and arrow may
# be to your liking.  You can set it once pdb is imported using the
# command "pdb.line_prefix = '\n% '".
# line_prefix = ': '    # Use this to get the old situation back
line_prefix = '\n-> '   # Probably a better default

class MyPdb(pdb.Pdb):

    def __init__(self):
        pdb.Pdb.__init__(self)
    def format_stack_entry(self, frame_lineno, lprefix=': '):
        import linecache, repr
        frame, lineno = frame_lineno
        filename = self.canonic(frame.f_code.co_filename)
        s = "filename=" + filename + '\nlineno=' + `lineno` + ' '
        if frame.f_code.co_name:
            s = s + frame.f_code.co_name
        else:
            s = s + "<lambda>"
        if frame.f_locals.has_key('__args__'):
            args = frame.f_locals['__args__']
        else:
            args = None
        if args:
            s = s + repr.repr(args)
        else:
            s = s + '()'
        if frame.f_locals.has_key('__return__'):
            rv = frame.f_locals['__return__']
            s = s + '->'
            s = s + repr.repr(rv)
        line = linecache.getline(filename, lineno)
        if line: s = s + lprefix + line.strip()
        return s

# Simplified interface

def run(statement, globals=None, locals=None):
    MyPdb().run(statement, globals, locals)

def runeval(expression, globals=None, locals=None):
    return MyPdb().runeval(expression, globals, locals)

def runctx(statement, globals, locals):
    # B/W compatibility
    run(statement, globals, locals)

def runcall(*args):
    return apply(MyPdb().runcall, args)

def set_trace():
    MyPdb().set_trace()

# Post-Mortem interface

def post_mortem(t):
    p = MyPdb()
    p.reset()
    while t.tb_next is not None:
        t = t.tb_next
    p.interaction(t.tb_frame, t)

def pm():
    post_mortem(sys.last_traceback)


# Main program for testing

TESTCMD = 'import x; x.main()'

def test():
    run(TESTCMD)

# print help
def help():
    for dirname in sys.path:
        fullname = os.path.join(dirname, 'pdb.doc')
        if os.path.exists(fullname):
            sts = os.system('${PAGER-more} '+fullname)
            if sts: print '*** Pager exit status:', sts
            break
    else:
        print 'Sorry, can\'t find the help file "pdb.doc"',
        print 'along the Python search path'

mainmodule = ''
mainpyfile = ''

# When invoked as main program, invoke the debugger on a script
if __name__=='__main__':
    if not sys.argv[1:]:
        print "usage: pdb.py scriptfile [arg] ..."
        sys.exit(2)

    mainpyfile = filename = sys.argv[1]     # Get script filename
    if not os.path.exists(filename):
        print 'Error:', `filename`, 'does not exist'
        sys.exit(1)
    mainmodule = os.path.basename(filename)
    del sys.argv[0]         # Hide "pdb.py" from argument list

    # Insert script directory in front of module search path
    sys.path.insert(0, os.path.dirname(filename))

    run('execfile(' + `filename` + ')')
