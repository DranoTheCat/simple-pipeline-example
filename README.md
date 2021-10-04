# The Pipeline
Both the "Hello World" app and the infrasturcture stuff to deploy it both exist in this repo.  This is for sake of completeness, however, the better pattern would be to have these in separate repos.

The App itself and the pipeline to deploy it live at this level.  The bootstrap/ folder contains some scripts and instructions to setup a fresh test environment in AWS.

## Triggering the Application Build and Deploying the App (Assumes the pipeline is already setup)
1. Check out this repo.
2. Create a new branch (e.g., git checkout -b mybranch)
3. Make your changes.  Commit and push your branch.
4. Create a PR to merge your branch onto Main
5. Once merged, the build will automatically trigger.

## Future Improvements for the Pipeline
* Don't just use :latest.  Decide on versioning convention.

## Setting up the Pipeline
### Pre-requisites
In order to run the Jenkins pipeline, at minimum you require:
* A DockerHub account to store the application images (https://docs.docker.com/docker-hub/)
* A Jenkins build host
* A target Kubernetes cluster to deploy to
* The Jenkins build host must be configured to talk to the Kubernetes cluster (e.g., .kubeconfig credentials)

The Infrasturcture bootstrapping below gets this going from scratch in a new AWS environment.

### Steps to create the Jenkins Pipeline
1. Log into your Jenkins build host over HTTP
2. Create a DockerHub Access Token for this Jenkins build host (https://hub.docker.com/settings/security) 
3. Under Manage Jenkins -> Manage Credentials -> Domains(global) -> Add Credentials, add the DockerHub Access Token from above.  (Use Username with password)  Give this an ID such as, 'jenkinscreddockerhubid'
4. Edit the Jenkinsfile in the local folder and update the Environment section appropriately:
```
    environment {
        registry = "YourDockerhubAccount/YourRepository"
        registryCredential = 'jenkinscreddockerhubid'
        dockerImage = ''
```
5. Create a new Pipline job named "Hello Pipeline".
6. For the Definition, use Pipeline script from SCM.  The SCM is Git, and the Repository URL is this Repo.  Since the repo is public, credentials are not needed here.
7. The description can be "Hello Pipeline example".  Everything else can be defaults.
8. The pipeline can be found in the Jenkinsfile file in the repo.

## Future Improvements
* Automate deployment of the pipeline, using something like the Jenkins Configuration as Code plugin.  https://www.jenkins.io/projects/jcasc/
