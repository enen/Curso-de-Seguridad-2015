#!/bin/bash

SERVER=192.168.7.201
PORT1=49013
PORT2=36027
PORT3=51039
PORTSSH=62025

echo -n 'mmm' | ncat -w201ms $SERVER $PORT1
echo -n 'mmm' | ncat -w201ms $SERVER $PORT2
echo -n 'mmm' | ncat -w201ms $SERVER $PORT3

ssh -p $PORTSSH $SERVER

