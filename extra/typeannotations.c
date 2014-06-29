#include "Python.h"
#include "opcode.h"
#include "extra/typeannotations.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>


static FILE* fh = NULL;

/*
 * Memory Management Notes:
 *
 * PyList_SetItem: borrows the reference
 * PyList_Append: creates a new reference
 * PyDict_GetItemString: borrows the reference
 * PyObject_GetAttrString: returns a new reference
 *
 * Py_XINCREF and Py_XDECREF should be used when the argument may be null.
 */

/*
 * Utility functions.
 */

/**
 * Concatenates the passed arguments with a dot.
 *
 * NULL arguments are ignored. The arguments are released afterwards.
 */
PyObject* _PyString_JoinWithDots(PyObject* object1,
                                PyObject* object2,
                                PyObject* object3) {
    PyObject *list = PyList_New(0);
    PyObject *separator = PyString_InternFromString(".");
    if (object1 != NULL) {
        PyList_Append(list, object1);
    }
    if (object2 != NULL) {
        PyList_Append(list, object2);
    }
    if (object3 != NULL) {
        PyList_Append(list, object3);
    }

    PyObject * result = _PyString_Join(separator, list);
    Py_DECREF(separator);
    Py_DECREF(list);

    return result;
}

#define GET_MACRO(_1, _2, _3, NAME, ...) NAME
#define PyString_JoinWithDots2(o1, o2) _PyString_JoinWithDots((o1), (o2), NULL)
#define PyString_JoinWithDots3(o1, o2, o3) _PyString_JoinWithDots((o1), (o2), (o3))
#define PyString_JoinWithDots(...) GET_MACRO(__VA_ARGS__, PyString_JoinWithDots3, PyString_JoinWithDots2)(__VA_ARGS__)


/**
 * Checks that an object can be a module name.
 *
 * If the name is empty or __builtin__, it returns NULL.
 */
PyObject* ModuleAsPyString(PyObject* object) {
    if(object != NULL && PyString_Check(object) && PyString_Size(object) != 0) {
        PyObject* builtin_str = PyString_InternFromString("__builtin__");
        int is_builtin = _PyString_Eq(object, builtin_str);
        Py_DECREF(builtin_str);
        if (is_builtin) {
            return NULL;
        }
        //Py_INCREF(object);
        return object;
    }

    return NULL;
}

// Copied from Objects/typeobject.c
static PyObject* type_name(PyTypeObject *type) {
    const char *s;

    if (type->tp_flags & Py_TPFLAGS_HEAPTYPE) {
        PyHeapTypeObject* et = (PyHeapTypeObject*)type;

        Py_INCREF(et->ht_name);
        return et->ht_name;
    }
    else {
        s = strrchr(type->tp_name, '.');
        if (s == NULL)
            s = type->tp_name;
        else
            s++;
        return PyString_FromString(s);
    }
}

// Modified from Object/classobject.c
static PyObject* instance_repr(PyInstanceObject *inst) {
    PyObject *classname, *mod;
    char *cname;
    classname = inst->in_class->cl_name;
    mod = PyDict_GetItemString(inst->in_class->cl_dict, "__module__");
    if (classname != NULL && PyString_Check(classname)) {
        cname = PyString_AsString(classname);
    } else {
        cname = "?";
    }
    if (mod == NULL || !PyString_Check(mod)) {
        return PyString_FromFormat("?.%s", cname);
    } else {
        return PyString_FromFormat("%s.%s", PyString_AsString(mod), cname);
    }
}

PyObject* PyObject_CallAsPyString(PyObject* object);

PyObject* PyObject_AsPyString(PyObject* object) {
    if (object == NULL) {
        return NULL;
    }

    if (PyInstance_Check(object)) {
        return instance_repr((PyInstanceObject*) object);
    }

    return PyObject_CallAsPyString(Py_TYPE(object));
}

PyObject* PyObject_CallAsPyString(PyObject* object) {
    PyObject *result, *module, *module_tmp, *self;
    PyObject *function, *function_tmp, *class;
    if (PyFunction_Check(object)) {
        module = ModuleAsPyString(((PyFunctionObject*)object)->func_module);
        function = ((PyFunctionObject*)object)->func_name;
        result = PyString_JoinWithDots(module, function);
        //Py_XDECREF(module);
        return result;
    } else if (PyCFunction_Check(object)) {
        module = ModuleAsPyString(((PyCFunctionObject*)object)->m_module);
        self = PyObject_AsPyString(((PyCFunctionObject*)object)->m_self);
        function = PyString_FromString(((PyCFunctionObject*)object)->m_ml->ml_name);
        result = PyString_JoinWithDots(module, self, function);
        //Py_XDECREF(module);
        Py_XDECREF(self);
        Py_DECREF(function);
        return result;
    } else if (PyMethod_Check(object)) {
        // See the implementation of instancemethod_repr
        class = NULL;
        if (PyMethod_GET_CLASS(object) != NULL) {
            class = PyObject_CallAsPyString(PyMethod_GET_CLASS(object));
        }
        if (PyFunction_Check(PyMethod_GET_FUNCTION(object))) {
            function = ((PyFunctionObject*)PyMethod_GET_FUNCTION(object))->func_name;
            Py_XINCREF(function);
        } else {
            function = PyString_InternFromString("???");
        }
        if (PyMethod_GET_SELF(object) == NULL) {
            // Unbounded method
            function_tmp = function;
            function = PyString_FromFormat("%s<U>",
                                           PyString_AsString(function_tmp));
            Py_DECREF(function_tmp);
        }
        result = PyString_JoinWithDots(class, function);
        Py_XDECREF(class);
        Py_XDECREF(function);
        return result;
    } else if (PyType_Check(object)) {
        module_tmp = PyObject_GetAttrString(object, "__module__");  // new reference
        module = ModuleAsPyString(module_tmp);
        class = type_name((PyTypeObject*)object);
        // class = PyString_FromString(((PyTypeObject*)object)->tp_name);
        result = PyString_JoinWithDots(module, class);
        //Py_XDECREF(module);
        Py_XDECREF(module_tmp);
        Py_XDECREF(class);

        return result;
    } else if (PyClass_Check(object)) {
        // see class_repr in classobject.c
        module = PyDict_GetItemString(((PyClassObject*)object)->cl_dict,
                                      "__module__");  // shared-reference
        class = ((PyClassObject*)object)->cl_name;
        result = PyString_JoinWithDots(module, class);
        return result;
    }

    return PyString_FromString(Py_TYPE(object)->tp_name);
}

PyObject* CallArgumentsAsPyString(PyObject** stack_pointer, int na, int nk,
                                  int var_args, int var_kw) {
    PyObject *arguments_str, *separator, *argument_type, *object;
    PyObject *arguments = PyList_New(na + nk + var_args + var_kw);
    int i;

    for(i = 0; i < na; ++i) {
        PyList_SetItem(arguments, i, PyObject_AsPyString(*(stack_pointer + i)));
    }
    for(i = 0; i < nk; ++i) {
        argument_type = PyObject_AsPyString(*(stack_pointer + na + 2 * i + 1));
        PyList_SetItem(arguments, i + na,
                       PyString_FromFormat("%s=%s",
                                           PyString_AsString(*(stack_pointer + na + 2 * i)),
                                           PyString_AsString(argument_type)));
        Py_DECREF(argument_type);
    }

    // TODO(skreft): do something more meaningful for var_args and var_kwds.
    if (var_args) {
        PyList_SetItem(arguments, na + nk, PyString_InternFromString("*args"));
    }
    if (var_kw) {
        PyList_SetItem(arguments, na + nk + var_args,
                       PyString_InternFromString("**kwargs"));
    }

    separator = PyString_InternFromString(", ");
    arguments_str = _PyString_Join(separator, arguments);
    Py_DECREF(separator);
    Py_DECREF(arguments);

    return arguments_str;
}

/*
 * API function calls.
 */

/**
 * Initializes a file to log the type annotations.
 *
 * By default it creates the file '/tmp/python-types-<pid>'. The filename can be
 * controlled by using the environment variable PYTHON_ANNOTATE.
 *
 * To fully disable the annotations set PYTHON_ANNOTATE=false.
 */
void TypeAnnotations_Init() {
    char filename[256] = "";
    char* type_annotate = getenv("PYTHON_ANNOTATE");
    if (type_annotate == NULL) {
        snprintf(filename, 256, "/tmp/python-types-%d", (int) getpid());
    } else if (strcmp(type_annotate, "false") != 0) {
        strncpy(filename, type_annotate, 256);
    } else {
        return;
    }

    fh = fopen(filename, "w");
    // Set the buffer to by line.
    setvbuf(fh, NULL, _IOLBF, 0);
}

/**
 * Converts a call to a string.
 *
 * It will use a somewhat understandable representation of the caller (including
 * modules and classes if applicable) and use the type of the arguments. Named
 * arguments are shown with the used name. *args and **kwargs are not further
 * processed and they are just reported as '*args' and '**kwargs'.
 *
 * Examples:
 *  min(1, 2) -> min(int, int)
 *  foo(1, bar='bar') -> foo(int, bar=str)
 *  bar(1, *[], **{}) -> bar(int, *args, **kwargs)
 */
PyObject* TypeAnnotations_CallToPyString(PyObject **stack_pointer,
                                         int oparg, int opcode) {
    if (fh == NULL) {
        return NULL;
    }

    int na = oparg & 0xff;
    int nk = (oparg>>8) & 0xff;
    int n = na + 2 * nk;
    PyObject **pfunc, *func;
    PyObject *func_name, *args, *result;
    int var_args = 0;
    int var_kw = 0;
    if (opcode == CALL_FUNCTION_VAR || opcode == CALL_FUNCTION_VAR_KW) {
        n++;
        var_args = 1;
    }
    if (opcode == CALL_FUNCTION_KW || opcode == CALL_FUNCTION_VAR_KW) {
        n++;
        var_kw = 1;
    }
    pfunc = stack_pointer - n - 1;
    func = *pfunc;
    func_name = PyObject_CallAsPyString(func);
    args = CallArgumentsAsPyString(pfunc + 1, na, nk, var_args, var_kw);
    result = PyString_FromFormat("%s(%s)",
                                 PyString_AsString(func_name),
                                 PyString_AsString(args));
    Py_DECREF(args);
    Py_DECREF(func_name);

    return result;
}

/**
 * Records the type of the returned object as well as the original call.
 */
void TypeAnnotations_Record(PyObject* object, PyObject* string_call) {
    if (fh == NULL || object == NULL) {
        return;
    }

    PyObject* type = PyObject_AsPyString(object);
    fprintf(fh,
            "%s\t%s\n",
            PyString_AsString(string_call),
            PyString_AsString(type));
    Py_DECREF(type);
    Py_DECREF(string_call);
}
