#!/bin/bash

# At 1st we need the root access for all --> so we need to check the root access 
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
# creating a variable here
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE 

# Check the user has root privileges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR: please run this script with root access $N" | tee -1 $LOG_FILE
    exit 1 #if you want to manually exit then give other than 0, upto 127
else
    echo "You are running with the root access" &>>$LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is $G SUCCESS $N" | tee -a $LOG_FILE  # tee command --> adds single input to the multiple outputs to the screen and also to the file.
    else 
        echo -e "$2 is $R FAILURE $N" | tee -a $LOG_FILE 
        exit 1
    fi
}

cp mongo.repo /etc/yum.repos.d/mongodb.repo # /mongo.repo can be given with any name of our choice but .repo is must
VALIDATE $? "Copying MongoDB repo" # it can be either mongo.repo or mongodb.repo, but having .repo is mandatory.

dnf install mongodb-org -y &>>$LOG_FILE      # Here we need to redirect the log files by using &>>$LOG_FILE
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