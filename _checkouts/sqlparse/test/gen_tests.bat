@echo off
REM ----------------------------------------------------------------------------
REM
REM gen_tests.bat: SQL - generating test data.
REM
REM Copyright (c) 2012-18 K2 Informatics GmbH.  All Rights Reserved.
REM
REM This file is provided to you under the Apache License,
REM Version 2.0 (the "License"); you may not use this file
REM except in compliance with the License.  You may obtain
REM a copy of the License at
REM
REM   http://www.apache.org/licenses/LICENSE-2.0
REM
REM Unless required by applicable law or agreed to in writing,
REM software distributed under the License is distributed on an
REM "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
REM KIND, either express or implied.  See the License for the
REM specific language governing permissions and limitations
REM under the License.
REM
REM ----------------------------------------------------------------------------

> gen_tests.log (

    SETLOCAL enableDelayedExpansion

    ECHO =======================================================================
    ECHO Start %0
    ECHO -----------------------------------------------------------------------
    ECHO Start Test Data Generation
    ECHO -----------------------------------------------------------------------
    ECHO:| TIME
    ECHO -----------------------------------------------------------------------

    IF EXIST _build\test\lib\sqlparse\test\generated (
        DEL /Q /S _build\test\lib\sqlparse\test\generated
    )
    IF EXIST test\generated (
        DEl /Q /S test\generated
    )

    CALL rebar3 as test compile

    REM Setting sqlparse options ...............................................
    IF "%GENERATE_COMPACTED%" == "" (
        REM true: compacted / false: detailed.
        SET GENERATE_COMPACTED=true
        SET GENERATE_CT=true
        SET GENERATE_EUNIT=false
        SET GENERATE_PERFORMANCE=true
        SET GENERATE_RELIABILITY=true
        SET HEAP_SIZE=+hms 33554432
        SET LOGGING=false
        SET MAX_BASIC=250
    )

    REM Starting test data generator ...........................................
    erl -noshell -pa _build\test\lib\sqlparse\test %HEAP_SIZE% -s sqlparse_generator generate -s init stop

    IF EXIST code_templates (
        DIR code_templates
        DEL /Q code_templates
    )

    ECHO -----------------------------------------------------------------------
    ECHO:| TIME
    ECHO -----------------------------------------------------------------------
    ECHO End   %0
    ECHO =======================================================================

)
