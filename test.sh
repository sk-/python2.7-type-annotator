#!/bin/bash

# run if user hits control-c
control_c() {
  echo -e "\nCancelled. User hit Ctrl+C.";
  exit 2;
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT


BUILDPYTHON="python"
TESTPYTHON="./$BUILDPYTHON -Wd -3 -E -tt"
TESTS=(
		'test_annotations/test_annotations.py'
		'Lib/test/test_abc.py'
		'Lib/test/test_abstract_numbers.py'
		'Lib/test/test___all__.py'
		'Lib/test/test_array.py'
		'Lib/test/test_ast.py'
		'Lib/test/test_atexit.py'
		'Lib/test/test_augassign.py'
		'Lib/test/test_binop.py'
		'Lib/test/test_bool.py'
		'Lib/test/test_buffer.py'
		'Lib/test/test_bufio.py'
		'Lib/test/test_builtin.py'
		'Lib/test/test_bytes.py'
		'Lib/test/test_call.py'
		'Lib/test/test_capi.py'
		'Lib/test/test_class.py'
		'Lib/test/test_cmath.py'
		'Lib/test/test_codeop.py'
		'Lib/test/test_code.py'
		'Lib/test/test_coercion.py'
		'Lib/test/test_collections.py'
		'Lib/test/test_compare.py'
		'Lib/test/test_compileall.py'
		'Lib/test/test_compile.py'
		'Lib/test/test_compiler.py'
		'Lib/test/test_complex_args.py'
		'Lib/test/test_complex.py'
		'Lib/test/test_contains.py'
		'Lib/test/test_ctypes.py'
		'Lib/test/test_decorators.py'
		'Lib/test/test_defaultdict.py'
		'Lib/test/test_deque.py'
		'Lib/test/test_descr.py'
		'Lib/test/test_dictcomps.py'
		'Lib/test/test_dict.py'
		'Lib/test/test_dictviews.py'
		'Lib/test/test_dis.py'
		'Lib/test/test_enumerate.py'
		'Lib/test/test_exceptions.py'
		'Lib/test/test_fileio.py'
		'Lib/test/test_file.py'
		'Lib/test/test_float.py'
		'Lib/test/test_frozen.py'
		'Lib/test/test_funcattrs.py'
		'Lib/test/test_functools.py'
		'Lib/test/test_future_builtins.py'
		'Lib/test/test___future__.py'
		'Lib/test/test_future.py'
		'Lib/test/test_gc.py'
		'Lib/test/test_generators.py'
		'Lib/test/test_genexps.py'
		'Lib/test/test_getargs.py'
		'Lib/test/test_getopt.py'
		'Lib/test/test_global.py'
		'Lib/test/test_grammar.py'
		'Lib/test/test_hash.py'
		'Lib/test/test_heapq.py'
		'Lib/test/test_importhooks.py'
		'Lib/test/test_importlib.py'
		'Lib/test/test_import.py'
		'Lib/test/test_imp.py'
		'Lib/test/test_inspect.py'
		'Lib/test/test_int_literal.py'
		'Lib/test/test_int.py'
		'Lib/test/test_io.py'
		'Lib/test/test_isinstance.py'
		'Lib/test/test_iterlen.py'
		'Lib/test/test_iter.py'
		'Lib/test/test_itertools.py'
		'Lib/test/test_list.py'
		'Lib/test/test_longexp.py'
		'Lib/test/test_long_future.py'
		'Lib/test/test_long.py'
		'Lib/test/test_math.py'
		'Lib/test/test_memoryio.py'
		'Lib/test/test_memoryview.py'
		'Lib/test/test_modulefinder.py'
		'Lib/test/test_module.py'
		'Lib/test/test_mutex.py'
		'Lib/test/test_new.py'
		'Lib/test/test_opcodes.py'
		'Lib/test/test_openpty.py'
		'Lib/test/test_operator.py'
		'Lib/test/test_optparse.py'
		'Lib/test/test_os.py'
		'Lib/test/test_parser.py'
		'Lib/test/test_pow.py'
		'Lib/test/test_print.py'
		'Lib/test/test_profile.py'
		'Lib/test/test_property.py'
		'Lib/test/test_queue.py'
		'Lib/test/test_random.py'
		'Lib/test/test_repr.py'
		'Lib/test/test_re.py'
		'Lib/test/test_richcmp.py'
		'Lib/test/test_scope.py'
		'Lib/test/test_setcomps.py'
		'Lib/test/test_set.py'
		'Lib/test/test_sets.py'
		'Lib/test/test_slice.py'
		'Lib/test/test_sort.py'
		'Lib/test/test_string.py'
		'Lib/test/test_str.py'
		'Lib/test/test_structmembers.py'
		'Lib/test/test_struct.py'
		'Lib/test/test_structseq.py'
		'Lib/test/test_symtable.py'
		'Lib/test/test_syntax.py'
		'Lib/test/test_sysconfig.py'
		'Lib/test/test_sys.py'
		'Lib/test/test_tokenize.py'
		'Lib/test/test_traceback.py'
		'Lib/test/test_trace.py'
		'Lib/test/test_tuple.py'
		'Lib/test/test_typechecks.py'
		'Lib/test/test_types.py'
		'Lib/test/test_unary.py'
		'Lib/test/test_unicode.py'
		'Lib/test/test_unittest.py'
		'Lib/test/test_userdict.py'
		'Lib/test/test_userlist.py'
		'Lib/test/test_userstring.py'
		'Lib/test/test_warnings.py'
		'Lib/test/test_weakref.py'
		'Lib/test/test_weakset.py'
		'Lib/test/test_with.py'
		'Lib/test/test_xrange.py'
	)
TEST_OUTPUT="/tmp/python-test-output"
TEST_SUCCESS="true"

# Delete compiled files
find . -name '*.py[co]' -print | xargs rm -f

for test_file in "${TESTS[@]}";
do
	echo -n 'Testing' $test_file '..........';
	$TESTPYTHON $test_file &> $TEST_OUTPUT;
	if [ "$?" != "0" ]; then
		TEST_SUCCESS='false';
		echo ' Failed';
		cat $TEST_OUTPUT;
	else
		echo ' OK';
	fi
done

if [ "$TEST_SUCCESS" != "true" ]; then
	exit 1
fi
