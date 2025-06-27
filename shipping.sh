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

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

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

dnf install maven -y &>>$LOG_FILE # it installs java also
VALIDATE $? "Installing Maven and Java"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir /app 
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downlaoding shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Moving and Renaming the Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon reload &>>$LOG_FILE
VALIDATE $? "Daemon Reload"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling Shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting Shipping" 

# Now we need to laod the data

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL"

mysql -h mysql.tharun78daws84s.site -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
mysql -h mysql.tharun78daws84s.site -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
mysql -h mysql.tharun78daws84s.site -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
VALIDATE $? "Loading the data into MySQL"

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart Shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE