#!/bin/bash

# At 1st we need the root access for all --> so we need to check the root access 
START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
# creating a variable here
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD # gives the pwd where the script is present

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE 

# Check the user has root privileges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #if you want to manually exit then give other than 0, upto 127
else
    echo "You are running with the root access" | tee -a $LOG_FILE
fi

# validate function takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE  # tee command --> adds single input to the multiple outputs to the screen and also to the file.
    else 
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE 
        exit 1
    fi
}

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling Default Redis Version"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling Redis:7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Edited redis.conf to accept remote connections"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling Redis"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Started Redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME $N" | tee -a $LOG_FILE