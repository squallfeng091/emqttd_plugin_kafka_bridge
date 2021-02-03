#!/bin/bash

exec > >(tee -i gen_tests.log)
sleep .1

# ----------------------------------------------------------------------------
#
# gen_tests.sh: SQL - generating test data.
#
# Copyright (c) 2012-18 K2 Informatics GmbH.  All Rights Reserved.
#
# This file is provided to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file
# except in compliance with the License.  You may obtain
# a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------

echo "========================================================================="
echo "Start $0"
echo "-------------------------------------------------------------------------"
echo "Start Test Data Generation"
echo "-------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "-------------------------------------------------------------------------"

if [ -d "_build/test/lib/sqlparse/test/generated" ]; then
    rm -rf _build/test/lib/sqlparse/test/generated
fi
if [ -d "test/generated" ]; then
    rm -rf test/generated
fi

rebar3 as test compile

# Setting sqlparse options ...............................................
if [ "$GENERATE_COMPACTED" == "" ]; then
    # true: compacted / false: detailed.
    export GENERATE_COMPACTED="true"
    export GENERATE_CT="true"
    export GENERATE_EUNIT="false"
    export GENERATE_PERFORMANCE="true"
    export GENERATE_RELIABILITY="true"
    export HEAP_SIZE="+hms 33554432"
    export LOGGING="false"
    export MAX_BASIC=250
fi

# Starting test data generator ...........................................
erl -noshell -pa _build/test/lib/sqlparse/test $HEAP_SIZE -s sqlparse_generator generate -s init stop

if [ -f "code_templates" ]; then
    ls -l code_templates
    rm code_templates
fi

echo "-------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "-------------------------------------------------------------------------"
echo "End   $0"
echo "========================================================================="

exit 0
