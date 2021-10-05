#!/bin/bash

AWS_REGION='us-west-2'
VPC_ID='vpc-304bec55'          # ID of VPC to deploy to
# TODO : This could be automatically created
CLUSTER_ROLE_ARN='arn:aws:iam::146311103463:role/example-deploy-k8s'
CLUSTER_NODEGROUP_ARN='arn:aws:iam::146311103463:role/Example_EKS_Nodegroup_Role'

# Get local IP
MYIP=$(curl https://icanhazip.com)

# TODO : Create IAM Roles and stuff

# Create the EKS cluster
VPC_SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPC_ID} |jq -r ".Subnets[].SubnetId" | tr "\n" "," | sed 's/,$//')
aws eks create-cluster --region ${AWS_REGION} --name example-deploy-k8s --kubernetes-version 1.21 --role-arn ${CLUSTER_ROLE_ARN} --resources-vpc-config subnetIds=${VPC_SUBNETS}

echo "Waiting for the cluster to become available..."
while [ "$(aws eks describe-cluster --region us-west-2 --name example-deploy-k8s --query "cluster.status")" == "\"CREATING\"" ]; do echo -n '.' ; sleep 5 ; done

# Create the EKS node groups
EKS_SUBNETS=$(echo ${VPC_SUBNETS} |sed 's/,/" "/g' |sed 's/$/"/' |sed 's/^/"/')
aws eks create-nodegroup --cluster-name example-deploy-k8s --nodegroup-name example-k8s-nodegroup --subnets ${EKS_SUBNETS} --node-role ${CLUSTER_NODEGROUP_ARN}
echo
echo "Note:  The nodegroup creation step can take a very long time, upwards of 10-15 minutes.  You can keep going with this in the background,
however the node group needs to be active before the pipeline will work."
echo

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
