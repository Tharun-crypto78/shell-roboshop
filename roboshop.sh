#!/bin/bash

# Go to the instance and scroll down for the AMI_ID
AMI_ID="ami-09c813fb71547fc4f"
# in the top menu bar of the ID address --> select Security --> select security groups ID
SG_ID="sg-0dbb4d1864e2681be"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
#INSTANCES=("$@")
ZONE_ID="Z04142321DEUW88VF6DED" #go to hosted zones --> click HZ details --> copy HZ ID
DOMAIN_NAME="tharun78daws84s.site" # replace with your domain.

#Now we can loop it
for instance in ${INSTANCES[@]}
do
    # if [ $instance ] #privateIPaddress will be used when if not equal to frontend
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0dbb4d1864e2681be --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text) #if this command executes, we'll get the instance id which will be stored inside the INSTANCE_ID variable
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations [0].Instances[0]. PrivateIpAddress" --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations [0].Instances[0]. PublicIpAddress" --output text)
    fi
    echo "$instance IP address: $IP"

    aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
        "Comment": "Creating or updating a record set for cognito endpoint"
        ,"Changes": [{
         "Action"             : "UPSERT"
         ,"ResourceRecordSet" : {
              "Name"             : "'$instance'.'$DOMAIN_NAME'"
             ,"Type"            : "A"
             ,"TTL"             : 1
             ,"ResourceRecords" : [{
                "Value"         : "'$IP'"
                }] 
            }
        }]
    }'
done