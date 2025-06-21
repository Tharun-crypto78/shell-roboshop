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

# Check the cart has root privileges or not
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

# Following the commands present in the git repo cart documentation
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20"
 
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs:20"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $n"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading  cart"

rm -rf /app/* # to remove the content present inside the app directory
cd /app 
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzipping cart"

npm install &>>LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service  #At present we're in the app location of the script --> which don't contain catalogue.service so it will fail --> If it have to should work irrelevant of wherever it is present then give "absolute path"
VALIDATE $? "Copying cart service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
systemctl start cart
VALIDATE $? "Starting cart"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

# cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
# dnf install mongodb-mongosh -y &>>$LOG_FILE
# VALIDATE $? "Installing MongoDB Client"

# STATUS=$(mongosh --host mongodb.tharun78daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
# if [ $STATUS -lt 0 ]
# then
#     mongosh --host mongodb.tharun78daws84s.site </app/db/master-data.js &>>$LOG_FILE
#     VALIDATE $? "Loading data into MongoDB"
# else
#     echo -e "Data is already loaded ... $Y SKIPPING $N"
# fi

