#!/bin/bash

source ./common.sh
app_name=user

# Following the commands present in the git repo catalogue documentation
check_root
app_setup
nodejs_setup
systemd_setup
print_time