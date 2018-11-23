#!/bin/bash
export ORACLE_HOME="/opt/oracle/product/11.2.0.3_cl"

/swlocal/oracle/bin/sqlldr USERID=user/password@example.com:4444/usqkbosp5 CONTROL=/directory/ctl/FREEZED.ctl &> /dev/null

