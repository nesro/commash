#!/bin/bash

clean() {
	echo "cleaning!"
}

trap clean SIGHUP SIGINT SIGTERM

sleep 5
