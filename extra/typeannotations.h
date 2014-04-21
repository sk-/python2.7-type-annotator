#ifndef Py_TYPEANNOTATIONS_H
#define Py_TYPEANNOTATIONS_H
#ifdef __cplusplus
extern "C" {
#endif

#include "Include/Python.h"

void TypeAnnotations_Init(void);
void TypeAnnotations_Record(PyObject* object, PyObject* string_call);
PyObject* TypeAnnotations_CallToPyString(PyObject** stack_pointer,
										 int oparg, int opcode);

#ifdef __cplusplus
}
#endif
#endif /* !Py_TYPEANNOTATIONS_H */
