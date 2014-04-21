python2.7-type-annotator
========================

Annotate the type of the arguments and return type of function calls.

This is a modification of the python interpreter that will log the argument
types and the return type of all function calls.

These modifications are released under the Apache 2 license. See LICENSE_THIS.

The code is organized as follows:
* extra: has the main routines to get the types and log them.
* test_annotations/: folder with the test for this wrapper.
* test.sh: script that runs the type annotations tests and some of the core
  Python ones. Not all tests are being run, as they take too much time to be
  run in Travis.
* Makefile.pre.in: changes to the compile process.
* Modules/python.c: added the call to initialize the annotator.
* Python/ceval.c: added the necessary calls to log the types before a call.
