# The Pipeline
This repo contains a Jenkins pipeline to deploy a simple "Hello World" app, as well as tooling to create this reference infrastructure.

The app is intended to run in an AWS EKS cluster, however, could run in any Kubernetes cluster by modifying the Ingress method.  This deployment uses native AWS NLBs as the TLS termination point.

Both the "Hello World" app and the infrasturcture stuff to deploy it reside in this repo.  This is for sake of completeness, however, the better pattern would be to have these in separate repos.

The App itself and the pipeline to deploy it live at this level.  The bootstrap/ folder contains some scripts and instructions to setup a fresh test environment in AWS.

## Triggering the Application Build and Deploying the App (Assumes the pipeline is already setup)
1. Check out this repo.
2. Create a new branch (e.g., git checkout -b mybranch)
3. Make your changes.  Commit and push your branch.
4. Create a PR to merge your branch onto Main
5. Once merged, the build will automatically trigger within 5 minutes.

I ran out of time to do anything with ExternalDNS.  So, steps 6 and 7 are manual :(
6. Run `kubectl get service helloapp-service -owide` to get the DNS of the NLB
7. Update the CNAME For "hello.example.com" (e.g., "hello.dranosandbox.click") to point at this NLB

## Future Improvements for the Pipeline
* Don't just use :latest.  Decide on versioning convention.
* Setup GitHub to trigger the Jenkins install, vs. having the Jenkins build run on a schedule.  (This would require Jenkins to be accessable to GitHub, or to use an intermediate service.)
* Add lower QA environment.  This could enable an approval process after QA has been signed off (by human or AI).
* Deploy to a specific namespace instead of just default

## Setting up the Pipeline
### Pre-requisites
Note:  Due to using AWS' Network Load Balancers for SSL, this Kubernetes deployment is specific to AWS.

In order to run the Jenkins pipeline, you require:
* A registered DNS Zone in the AWS account
* A valid TLS cert in ACM for this Zone (Either issued by AWS, or imported from LetsEncrypt (https://letsencrypt.org/), etc.)
* A DockerHub account to store the application images (https://docs.docker.com/docker-hub/)
* A Jenkins build host with the Pipeline, Docker, and Docker Pipeline plugins.  Jenkins must be able to build Docker images.
* A target EKS Kubernetes cluster to deploy into, either named 'example-deploy-k8s', or replace references to this in Jenkinsfile
* Subnets tagged with Name "kubernetes.io/role/elb" and Value "1" for use by the Public Network Load Balancer
* The Jenkins build host must be configured to talk to the Kubernetes cluster (e.g., .kubeconfig credentials)

### Steps to create the Jenkins Pipeline
1. Log into your Jenkins build host over HTTP
2. Create a DockerHub Access Token for this Jenkins build host (https://hub.docker.com/settings/security) 
3. Under Manage Jenkins -> Manage Credentials -> Domains(global) -> Add Credentials, add the DockerHub Access Token from above.  (Use Username with password)  Give this an ID such as, 'jenkinscreddockerhubid'
4. Edit the Jenkinsfile in the local folder and update the Environment section appropriately:
```
    environment {
        registryCredential = 'jenkinscreddockerhubid'
        dockerImage = ''
```
5. Create a new Pipline job named "Hello Pipeline".
6. Under Build Triggers, enable "Poll SCM".  Set the following schedule to poll every 5 minutes:  H/5 * * * * 
6. For the Definition, use Pipeline script from SCM.  The SCM is Git, and the Repository URL is this Repo.  Since the repo is public, credentials are not needed here.
7. The description can be "Hello Pipeline example".  Everything else can be defaults.
8. The pipeline can be found in the Jenkinsfile file in the repo.

## Future Improvements
* Automate deployment and versioning of the pipeline
* Use triggers from GitHub instead of pollling; this would require Jenkins to be accessible from the Internet

# Bootstrapping the Jenkins and EKS example sandbox environment

See https://github.com/DranoTheCat/simple-pipeline-example/tree/master/bootstrap
