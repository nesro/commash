#!/usr/bin/env bash

function errtrap {
    es=$?
    print "ERROR line $1: Command exited with status $es."
}
trap 'errtrap $LINENO' ERR
