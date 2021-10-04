# The Pipeline
The app is fully contained under the app/ subfolder.  Most of the stuff at the top-level is bootstrapping.

## Triggering the build (Assumes the pipeline is already setup)
1. Make your changes to this source repo.
2. Push changes.

(Both the "Hello World" app and the infrasturcture stuff to deploy it both exist in this repo.  This is for sake of completeness, however, the better pattern would be to have these in separate repos.)

## Future Improvements for the Pipeline
* Don't just use :latest; come up with versioning system

## Setting up the Pipeline
### Pre-requisites
In order to run the Jenkins pipeline, at minimum you require:
* A Jenkins build host
* A target Kubernetes cluster to deploy to
* The Jenkins build host must be configured to talk to the Kubernetes cluster (e.g., .kubeconfig credentials)

The Infrasturcture bootstrapping below gets this going from scratch in a new AWS environment.

### Steps to create the Jenkins Pipeline
1. Log into your Jenkins build host
2. Create a new Pipline job named "Hello Pipeline"
3. The description can be "Hello Pipeline example".  Everything else can be defaults.
4. The pipeline can be found in the pipeline.jenkins file in the repo.


## Future Improvements
* Automate deployment of the pipeline, using something like the Jenkins Configuration as Code plugin.  https://www.jenkins.io/projects/jcasc/



# The Infrastructure
Both the "Hello World" app and the infrasturcture stuff to deploy it both exist in this repo.  This is for sake of completeness, however, the better pattern would be to have these in separate repos.

## Bootstrapping
If you are running in AWS, you can use the bootstrap scripts below to configure the environment.

*Notes*:

1. The bootstrapped build environment is *not* secure.  It is *not* intended for any sort of production use.  It is a minimal, bare-bones configuration to get a working AWS environment with a Jenkins build host (on a single EC2 instnace) able to deploy into an EKS cluster.  This bootstrapping is intended for individual development sandboxes only.  The bootstrapping will leave your Jenkins host with port 8080 exposed to whichever NAT IP you ran the bootstrapping from.  The Jenkins admin password is left as default from /var/lib/jenkins/secrets/initialAdminPassword
2. This bootstrapping process assumes you do *not* have a VPN connection to your AWS VPC (which is normal.)  Therefore, public IP access is required.  This is not an ideal setup as it requires many endpoints to be publicly available, and has a very large surface area of security risk.
3. The bootstrapped EKS environment is open to the Internet.  https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html
4. Seriously, the bootstrap is only meant as an example.  It does a lot of local-dev things, like setting SecurityGroup Ingresses to be from your current NAT IP.  It has stuff open to the Internet.  There are version locks and hardcoded things.  I wouldn't put anything valuable here...

### Bootstrapping Pre-requisites
Of course, even if you are using the bootstrap, there are a few prerequisite requirements :)
1. You must have an AWS account with CLI administrator access.  Securely managing these keys is out of scope for this exercise.
2. You must have already created an AWS keypair, and have access to the private key.  Securely managing these keys is also out of scope for this exercise.
3. You must already have a VPC setup.   This VPC must already have appropriate subnets, Internet Gateways, NAT gateways, routing tables, etc. setup.  (Using the default VPC configuration AWS gives you is likely fine, however I have not tested with a default VPC.)
4. Your subnets must be configured as "public" and auto-assign a public IP to resources.  This bootstrapping assumes you do *not* have a VPN connection to the VPC.
5. You must manually create the EKS IAM Role for now.  See https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html.   This role must have a principle for EKS as well, e.g.:
```
    ...
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
```
6. You must also manually create the Jenkins IAM Role.  Attach the following inline policy to this role:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "*"
        }
    ]
}
```
7. You must also manually create the EKS nodegroup.

### Bootstrapping Process
0. Make sure your working environment is correctly configured to point at the AWS environment.  (e.g., set AWS_PROFILE and AWS_DEFAULT_REGION)
1. Edit bootstrap-eks.bash.  Update the variables at the top as appropriate.
2. Run bootstrap-eks.bash.
3. Edit bootstrap-jenkins.bash.  Update the variables at the top as appropriate.
4. Run bootstrap-jenkins.bash.  Follow the manual instructions at the end to finish the Jenkins installation.

# Future Improvements
Future improvements are mixed below, but there are two high-level designs we could aim for:
1) More ephemeral build enviroments that come and go as needed, or
2) More permament build environments that are managed as traditional infrastructure

* Automating the remaining manual stuff (not automated yet do to non-trivialness of said automation.)
* Run Jenkins securely (e.g., not just expose port 8080)
* Run Jenkins with higher availability
* Put a reverse proxy (nginx, apache, etc.) in front of Jenkins
* Run Jenkins ephemerally on a Kubernetes build cluster
* Ship logs off to remote location
* Tag resources for tracking, automation, cost analysis / etc.
## Bootstrapping
Tons of improvements could be made to the bootstrap process, but are most likely out of scope for this exercise.

Regardless, potential things might include:
* Configuring Jenkins with https://plugins.jenkins.io/configuration-as-code/ instead of restoring the backup...
* Using Terraform or Cloudformation to manage the resources (presently the bootstrap scripts are not very idempotent)
* A build infrastructure that can build itself, with appropriate bootstrapping to maintain a direct acyclic graph of dependencies
* Automatically discovering upstream OS images (instead of hardcoding AMIs) and incorporating these into the test pipeline
