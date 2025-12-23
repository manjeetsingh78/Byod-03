pipeline {
    agent any
    
    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        SSH_CRED_ID = 'aws-deployer-ssh-key'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Initialization') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        echo "=== Current Directory ==="
                        sh 'pwd'
                        sh 'ls -la'
                        
                        echo "=== Initializing Terraform ==="
                        sh 'terraform init'
                        
                        echo "=== Displaying ${env.BRANCH_NAME}.tfvars content ==="
                        sh """
                            if [ -f ${env.BRANCH_NAME}.tfvars ]; then
                                cat ${env.BRANCH_NAME}.tfvars
                            else
                                echo "Warning: ${env.BRANCH_NAME}.tfvars not found"
                                ls -la *.tfvars || echo "No .tfvars files found"
                            fi
                        """
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        echo "=== Generating Terraform plan for branch: ${env.BRANCH_NAME} ==="
                        sh """
                            terraform plan \
                            -var-file="${env.BRANCH_NAME}.tfvars" \
                            -out=tfplan
                        """
                    }
                }
            }
        }
        
        stage('Validate Apply') {
            when {
                branch 'dev'
            }
            steps {
                script {
                    input message: 'Do you want to proceed with terraform apply?',
                          ok: 'Proceed',
                          submitter: 'admin'
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                branch 'dev'
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        echo "=== Applying Terraform changes ==="
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "=== Pipeline execution completed ==="
            cleanWs()
        }
        success {
            echo "=== Pipeline succeeded ==="
        }
        failure {
            echo "=== Pipeline failed ==="
        }
    }
}
