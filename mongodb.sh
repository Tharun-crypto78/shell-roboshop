#!/bin/bash

source ./common.sh
app_name=mongodb

check_root

cp mongo.repo /etc/yum.repos.d/mongodb.repo # /mongo.repo can be given with any name of our choice but .repo is must
VALIDATE $? "Copying MongoDB repo" # it can be either mongo.repo or mongodb.repo, but having .repo is mandatory.

dnf install mongodb-org -y &>>$LOG_FILE #Here we need to redirect log files by using &>>$LOG_FILE
VALIDATE $? "Installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting MongoDB"
# Now we need to change the file content inside the etc/mongodb.conf --> you can change it by using SED editor
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB"

print_time