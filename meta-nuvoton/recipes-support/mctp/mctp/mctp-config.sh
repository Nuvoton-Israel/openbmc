#!/bin/sh

busnum=0
netid=10
eid=160

# Bus owner side
mctp link set mctpi2c${busnum} net ${netid} up
mctp addr add ${eid} dev mctpi2c${busnum}
mctp discovery ${busnum}
