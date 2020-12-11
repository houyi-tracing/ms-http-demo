#!/bin/bash

echo "Input your command:"
read cmd

echo "Command to run on remote nodes:"
echo "${cmd}"
while true; do
        echo -n "Continue(y/N)?"
        read option
        case $option in
        (Y | y)
                break;;
        (N | n)
                exit 1;;
        (*)
                echo "Wrong option: ${option}";;
        esac
done

node_hosts=$( cat /etc/hosts | grep "node[0-9]*.local" | awk '{print $2}' )
echo "Running command on remote hosts:"
echo $node_hosts
echo ""
for host in $node_hosts; do
    echo "Output from $host:"
    ssh root@$host "$cmd"
    echo ""
done

echo "Done"
