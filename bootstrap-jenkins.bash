#!/bin/bash

AMI_ID='ami-0964546d3da97e3ab' # https://cloud-images.ubuntu.com/locator/
INSTANCE_TYPE='t2.micro'       # Size / Class of instance
KEYPAIR_NAME='dhart-keypair'   # SSH keypair name
SUBNET_ID='subnet-f49a4483'    # Subnet of AZ to deploy to
VPC_ID='vpc-304bec55'          # ID of VPC to deploy to
JENKINS_IAM_ROLE='arn:aws:iam::146311103463:role/Example_Jenkins_Role' # ARN of IAM Role
PRIVATE_IDENTITY='~/.ssh/dhart-keypair.pem'  # Private key file that matches KEYPAIR_NAME

# Get local IP
MYIP=$(curl https://icanhazip.com)

# Create the Jenkins SG
# TODO : Check to see if an appropriate group already exists, rather than just erroring out if it does.  
aws ec2 create-security-group --description "Inbound Jenkins Access" --group-name "inbound-jenkins-access" --vpc-id ${VPC_ID} 
SG_ID=$(aws ec2 describe-security-groups --group-names inbound-jenkins-access |jq -r ".SecurityGroups[0].GroupId")
# Allow current NAT IP access
aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 22 --cidr ${MYIP}/32
aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 8080 --cidr ${MYIP}/32

# Create Jenkins EC2 instance
# TODO : Likewise, we should check to see if this instance already exists.  For now it will likely just create new ones here 
aws ec2 run-instances --image-id ${AMI_ID} --count 1 --instance-type ${INSTANCE_TYPE} --key-name ${KEYPAIR_NAME} --security-group-ids ${SG_ID} --subnet-id ${SUBNET_ID} \
	 --iam-instance-profile ${JENKINS_IAM_ROLE} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-host}]' | tee /dev/null
                                                                                    	# The | tee gets rid of the annoying the implied "less" AWS cli does
EC2_ID=$(aws ec2 describe-instances --filters Name=tag:Name,Values=jenkins-host Name=instance-state-name,Values=running |jq -r ".Reservations[0].Instances[0].InstanceId")

# Now Configure Jenkins EC2 instance
# TODO : Replace sleep with a while loop to go once the instance is back
sleep 300 # wait for Jenkins instance to be available
EC2_IP=$(aws ec2 describe-instances --instance-id ${EC2_ID} |jq -r ".Reservations[0].Instances[0].PublicIpAddress")
scp -i ${PRIVATE_IDENTITY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no .bootstrap-jenkins.payload ubuntu@${EC2_IP}:/tmp
ssh -i ${PRIVATE_IDENTITY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@${EC2_IP} bash -x /tmp/.bootstrap-jenkins.payload

echo "Please now access http://${EC2_IP}:8080 and unlock it.  The code is below.  Skip creating an initial user.  Leave Jenkins URL as-is.  Click Start Using Jenkins"
ssh -i ${PRIVATE_IDENTITY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@${EC2_IP} cat /var/lib/jenkins/secrets/initialAdminPassword
