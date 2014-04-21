import os
import re
import unittest

import helpers


class _StartTypeAnnotationsSentinel(object):
    pass


class _EndTypeAnnotationsSentinel(object):
    pass


_START_SENTINEL = _StartTypeAnnotationsSentinel()
_END_SENTINEL = _EndTypeAnnotationsSentinel()


def return_start_sentinel():
    return _START_SENTINEL


def return_end_sentinel():
    return _END_SENTINEL


class _TypeSentinel(object):
    _START_SENTINEL_RE = re.compile(r'^[a-zA-Z0-9_.]*return_start_sentinel\(\)\t[a-zA-Z0-9_.]*_StartTypeAnnotationsSentinel$')
    _END_SENTINEL_RE = re.compile(r'^[a-zA-Z0-9_.]*return_end_sentinel\(\)\t[a-zA-Z0-9_.]*_EndTypeAnnotationsSentinel$')

    def __init__(self, file_handler):
        self.annotations = None
        self.file_handler = file_handler

    def __enter__(self):
        self.file_handler.read()
        return_start_sentinel()
        return self

    def __exit__(self, type_unused, value_unused, traceback_unused):
        return_end_sentinel()
        self.annotations = self.file_handler.read()

    def get_annotations(self):
        all_annotations = self.annotations.split('\n')
        annotations = []
        in_block = False
        for annotation in all_annotations:
            if self._START_SENTINEL_RE.match(annotation):
                in_block = True
            elif self._END_SENTINEL_RE.match(annotation):
                break
            elif in_block:
                annotations.append(annotation)

        return annotations


def get_annotations_filename():
    return '/tmp/python-types-%d' % os.getpid()


class TestAnnotations(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.annotations_file = open(get_annotations_filename(), 'r')

    @classmethod
    def tearDownClass(cls):
        cls.annotations_file.close()

    def test_min(self):
        with _TypeSentinel(self.annotations_file) as types:
            min(2, 3)
            min((2, 3))

        self.assertEqual(
            ['min(int, int)\tint',
             'min(tuple)\tint'],
            types.get_annotations())

    def test_int(self):
        with _TypeSentinel(self.annotations_file) as types:
            int("42")
            int(42)

        self.assertEqual(
            ['int(str)\tint',
             'int(int)\tint'],
            types.get_annotations())

    def test_str(self):
        with _TypeSentinel(self.annotations_file) as types:
            str("42")
            str(42)
            "FoO".lower()

        self.assertEqual(
            ['str(str)\tstr',
             'str(int)\tstr',
             'str.lower()\tstr'],
            types.get_annotations())

    def test_user_defined_class(self):
        with _TypeSentinel(self.annotations_file) as types:
            a = helpers.A()
            a.foo(1, [])
            helpers.A.foo(a, 1, [])

        self.assertEqual(
            ['helpers.A()\thelpers.A',
             'helpers.A.foo(int, list)\tint',
             'helpers.A.foo<U>(helpers.A, int, list)\tint'],  # <U> means the method is unbounded
            types.get_annotations())

    def test_user_defined_function(self):
        with _TypeSentinel(self.annotations_file) as types:
            helpers.foo([])
            helpers.foo('')
            helpers.foo('', b='')
            helpers.foo('', *[])
            helpers.foo('', **{})
            helpers.foo('', *[], **{})
            helpers.foo('', b='', *[], **{})

        self.assertEqual(
            ['helpers.foo(list)\tlist',
             'helpers.foo(str)\tstr',
             'helpers.foo(str, b=str)\tstr',
             'helpers.foo(str, *args)\tstr',
             'helpers.foo(str, **kwargs)\tstr',
             'helpers.foo(str, *args, **kwargs)\tstr',
             'helpers.foo(str, b=str, *args, **kwargs)\tstr'],
            types.get_annotations())


# TODO(skreft): add testst for method wrappers: int.__hash__(1), (1).__hash__()


if __name__ == '__main__':
    unittest.main()
