#!/bin/bash

exec > >(tee -i gen_tests_and_run.log)
sleep .1

# ----------------------------------------------------------------------------
#
# gen_tests_and_run.sh: SQL - generate and run test data.
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
echo "Start Test Data Generation and Run"
echo "-------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "-------------------------------------------------------------------------"

# Setting sqlparse options ...............................................
# "true": compacted / "false": detailed.
export GENERATE_COMPACTED="true"
export GENERATE_CT="true"
export GENERATE_EUNIT="false"
export GENERATE_PERFORMANCE="true"
export GENERATE_RELIABILITY="true"
export HEAP_SIZE="+hms 33554432"
export LOGGING="false"
export MAX_BASIC=250
test/gen_tests.sh

echo "Start EUnit Tests"
SOURCEFILES_OLD=SOURCEFILES
SOURCEFILES=
rebar3 eunit
SOURCEFILES=SOURCEFILES_OLD

echo "Start Common Tests"
rebar3 ct

echo "Start Coverage Analysis"
rebar3 cover

echo "Start Dialyzer"
rebar3 dialyzer

echo "Start geas (Guess Erlang Application Scattering)"
rebar3 as test geas

echo "-------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "-------------------------------------------------------------------------"
echo "End   $0"
echo "========================================================================="

exit 0
