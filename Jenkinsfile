pipeline { 
    environment { 
        registryCredential = 'e8563297-2fc5-419b-87b0-562e9b7856ae' 
        dockerImage = '' 
    }
    agent any 
    stages { 
        stage('Get EKS Creds') {
	    steps {
              sh 'aws eks --region us-west-2 update-kubeconfig --name example-deploy-k8s'
            }
	}
        stage('Clone from GitHub') { 
            steps { 
                git 'https://github.com/DranoTheCat/simple-pipeline-example'
            }
        } 
        stage('Build App') { 
            steps { 
                script { 
                    dockerImage = docker.build "dranothecat/simple-k8s-hello:latest"
                }
            } 
        }
        stage('Push App to Dockerhub') { 
            steps { 
                script { 
                    docker.withRegistry( '', registryCredential ) { 
                        dockerImage.push 'latest'
                    }
                } 
            }
        } 
        stage('Deploy App to Kubernetes') { 
            steps {
                script {
                    sh 'kubectl apply -f deploy-to-kubernetes.yaml'
                }
            }
        }
    }
}
