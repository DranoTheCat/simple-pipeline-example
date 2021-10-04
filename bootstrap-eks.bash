#!/bin/bash

AWS_REGION='us-west-2'
VPC_ID='vpc-304bec55'          # ID of VPC to deploy to
# TODO : This could be automatically created
CLUSTER_ROLE_ARN='arn:aws:iam::146311103463:role/example-deploy-k8s'

# Get local IP
MYIP=$(curl https://icanhazip.com)

# TODO : Create IAM Role

## Create EKS Security Groups
## TODO : Check to see if an appropriate group already exists, rather than just erroring out if it does.
#aws ec2 create-security-group --description "EKS Cluster Security Group" --group-name "example-deploy-k8s-cluster" --vpc-id ${VPC_ID}
#SG_ID=$(aws ec2 describe-security-groups --group-names example-deploy-k8s-cluster |jq -r ".SecurityGroups[0].GroupId")
## Allow cluster all access
#aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol all --source-group ${SG_ID}

# Create the EKS cluster
VPC_SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPC_ID} |jq -r ".Subnets[].SubnetId" | tr "\n" "," | sed 's/,$//')
aws eks create-cluster --region ${AWS_REGION} --name example-deploy-k8s --kubernetes-version 1.21 --role-arn ${CLUSTER_ROLE_ARN} --resources-vpc-config subnetIds=${VPC_SUBNETS}

echo "Waiting for the cluster to become available..."
while [ "$(aws eks describe-cluster --region us-west-2 --name example-deploy-k8s --query "cluster.status")" == "\"CREATING\"" ]; do echo -n '.' ; sleep 5 ; done

# Allow Jenkins to access EKS
ESCAPED_CLUSTER_ROLE_ARN=$(echo ${CLUSTER_ROLE_ARN} | sed 's:/:\\/:g')
aws eks update-kubeconfig --region ${AWS_REGION} --name example-deploy-k8s # This sets current-context as well
curl https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-10-29/aws-auth-cm.yaml | sed "s/<ARN of instance role (not instance profile)>/${ESCAPED_CLUSTER_ROLE_ARN}/" > aws-auth-cm.yaml
kubectl apply -f aws-auth-cm.yaml

echo "Please add the Jenkins IAM ARN as an approved role to the config map.  It will be edited when you press return.  Use the Jenkins ARN, the section you add should look something like this:
      ...
    - rolearn: arn:aws:iam::146311103463:role/Example_Jenkins_Role
      username: Jenkins
      groups:
        - system:masters
      ...
"
read ans
kubectl edit -n kube-system configmap/aws-auth

# Create the EKS cluster node group
echo "You will now need to create a Node Group Role:  https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html"
echo "After this, create a nodegroup for this EKS cluster.  Follow the process here:  https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html  I suggest using t3.micro for example purposes. Leave node configuration as 2 (should be defaults.)  All subnets can be included."
echo "You can move on to the Jenkins bootstrap while waiting for the node group creation to finish."
