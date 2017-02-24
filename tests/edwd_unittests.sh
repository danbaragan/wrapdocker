#!/usr/bin/env bash

## Run this file. DO NOT SOURCE IT!

oneTimeSetUp() {
    # env
    export TERM=

    # stubs
    docker() { true; }
    docker-compose() { true; }
    git() { true; }

    # files
    cat >.env <<_eof_
EDW_VAR1=var1

#EDW_VAR2=commented
#  EDW_VAR3=commented

EDW_VAR4=var4
_eof_

    cat >.env.other <<_eof_
EDW_VAR1=varother
_eof_

    cat >deploy.manifest <<_eof_
file0.1
dir1/file1.1
dir2/
_eof_
}

oneTimeTearDown() {
    # remove files
    rm -f .env
    rm -f .env.other
    rm -f deploy.manifest
}

testStubs() {
    docker bla
    assertEquals "stub instead of docker" 0 $?
    docker-compose bla
    assertEquals "stub instead of docker-compose" 0 $?
    git bla
    assertEquals "stub instead of git" 0 $?
}


testEdwdEnvLoad() {
    local exportedEnv=`../edwd show_context`

    grep -q EDW_VAR1=var1 <<<$exportedEnv
    assertTrue "should export var" "$?"

    grep -q EDW_VAR2 <<<$exportedEnv
    assertFalse "should not export commented var" "$?"

    grep -q EDW_VAR3 <<<$exportedEnv
    assertFalse "should not export commented var" "$?"

    grep -q EDW_VAR4=var4 <<<$exportedEnv
    assertTrue "should export var after comment" "$?"

    grep -q EDW_VAR1000 <<<$exportedEnv
    assertFalse "should not export missing var" "$?"

    # load another env file
    exportedEnv=`../edwd -e .env.other show_context`
    grep -q EDW_VAR1=varother <<<$exportedEnv
    assertTrue "should export var from other file" "$?"

    grep -q EDW_VAR4 <<<$exportedEnv
    assertFalse "should not export var if not present" "$?"

    # load the intial env file back
    exportedEnv=`../edwd show_context`
    grep -q EDW_VAR1=var1 <<<$exportedEnv
    assertTrue "should export initial var back" "$?"
}

. shunit2
