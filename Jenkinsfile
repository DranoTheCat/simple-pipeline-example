pipeline { 
    environment { 
        registry = "dranothecat/simple-k8s-hello" 
        registryCredential = 'e8563297-2fc5-419b-87b0-562e9b7856ae' 
        dockerImage = '' 
    }
    agent any 
    stages { 
        stage('Clone from GitHub') { 
            steps { 
                git 'https://github.com/DranoTheCat/simple-pipeline-example'
            }
        } 
        stage('Build App') { 
            steps { 
                script { 
                    dockerImage = docker.build registry + ":latest" 
                }
            } 
        }
        stage('Deploy App') { 
            steps { 
                script { 
                    docker.withRegistry( '', registryCredential ) { 
                        dockerImage.push() 
                    }
                } 
            }
        } 
    }
}
