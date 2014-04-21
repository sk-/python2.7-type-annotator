class A(object):
    def foo(self, x, y, *args, **kwargs):
        return x

    def __call__(self, foo):
        return foo

def foo(a, b=None, *args, **kwargs):
    return a
