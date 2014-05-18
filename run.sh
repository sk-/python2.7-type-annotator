#!/bin/bash

# run if user hits control-c
control_c() {
  echo -e "\nCancelled. User hit Ctrl+C.";
  exit 2;
}

check_return_code() {
	if [ "$?" != "0" ]; then
		echo 'Error:' $1 'failed'
		exit 1;
	fi
}

stats() {
	echo "Size:" `du -hc /tmp/python-types-* | tail -n 1 | cut -f 1`;
	echo "Lines:" `cat /tmp/python-types-* | wc -l`;
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

PYTHON_NAME="python2"
VIRTUALENV="${PYTHON_NAME}_env";
PYTHON_EXE=`readlink -f $PYTHON_NAME`;
BASE_INSTALL=`dirname $PYTHON_EXE`;
BASE_INSTALL=`dirname $BASE_INSTALL`;

# Remove previous annotations
rm /tmp/python-types-* 2> /dev/null;

# Run our own tests
$PYTHON_EXE test_annotations/test_annotations.py;
check_return_code 'test_annotations.py';

# Run python unittests
# Note: do not use a virtualenv as test_distutils, test_site and test_trace
# will fail.
# Remove test_tempfile and test_uuid as they fail (uuid fails only in Travis).
rm $BASE_INSTALL/Lib/test/test_tempfile.py $BASE_INSTALL/Lib/test/test_uuid.py
$PYTHON_EXE $BASE_INSTALL/Lib/test/regrtest.py;
check_return_code 'Python test suite';

stats;
if [ "$TRAVIS" == "true" ]; then
	echo "Running on travis, so exitting.";
	exit 0;
fi

# Setup a virtualenv
rm -rf $VIRTUALENV 2> /dev/null;
mkdir $VIRTUALENV;
virtualenv -p $BASE_INSTALL/bin/python $VIRTUALENV;
source $VIRTUALENV/bin/activate

# Run numpy unittests.
pip install nose
pip install numpy
python -c 'import numpy; numpy.test()'
check_return_code 'Numpy';

# Deactivate the virtualenv
deactivate

# Collect type information
stats;
sort -u /tmp/python-types-* | python remove_multiple.py > "${PYTHON_NAME}_annotations.tsv"
echo "Size:" `du -hc "${PYTHON_NAME}_annotations.tsv" | tail -n 1 | cut -f 1`;
echo "Lines:" `cat "${PYTHON_NAME}_annotations.tsv" | wc -l`;
