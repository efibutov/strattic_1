#!/bin/bash
echo "RUNNING NGNX"
nginx
echo "MySQL daemon"
mysqld &
echo "------------------ALL SERVICES ARE RUNNING-----------------"
/usr/local/bin/get_date.sh > /tmp/log
/bin/bash
