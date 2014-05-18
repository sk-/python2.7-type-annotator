python2.7-type-annotator
========================

Annotate the type of the arguments and return type of function calls.

This is a modification of the python interpreter that will log the argument
types and the return type of all function calls.

These modifications are released under the Apache 2 license. See LICENSE.

The code is organized as follows:
* extra: has the main routines to get the types and log them.
* test_annotations/: folder with the test for this wrapper.
* patches/Makefile.pre.in.patch: changes to the compile process.
* patches/python.c.patch: added the call to initialize the annotator.
* patches/ceval.c.patch: added the necessary calls to log the types before a call.
* build.sh: script that downloads the sources, applies the patches and compiles the sources.
* run.sh: script to run the included tests, python's regression suite, and numpy's tests.
  It will generate a file called python2_annotations.tsv.
* remove_multiple.py: script to remove those lines for which the call signature is duplicated.
  For example: if we have f(int)-> str and f(int)-> int, then this script will remove those lines.
