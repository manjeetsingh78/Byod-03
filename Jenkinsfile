pipeline {
    agent any
    options {
        skipDefaultCheckout(true)
    }

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
                    bat '''
                        echo === Current Directory ===
                        cd

                        echo === Listing files ===
                        dir

                        echo === Initializing Terraform ===
                        terraform init

                        echo === Displaying tfvars file ===
                        if exist %BRANCH_NAME%.tfvars (
                            type %BRANCH_NAME%.tfvars
                        ) else (
                            echo WARNING: %BRANCH_NAME%.tfvars not found
                            dir *.tfvars
                        )
                    '''
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
                    bat '''
                        echo === Generating Terraform plan ===
                        terraform plan -var-file=%BRANCH_NAME%.tfvars -out=tfplan
                    '''
                }
            }
        }

        stage('Validate Apply') {
            when {
                branch 'dev'
            }
            steps {
                input message: 'Do you want to proceed with terraform apply?',
                      ok: 'Proceed'
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
                    bat '''
                        echo === Applying Terraform changes ===
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "=== Pipeline execution completed ==="
        }
        success {
            echo "=== Pipeline succeeded ==="
        }
        failure {
            echo "=== Pipeline failed ==="
        }
    }
}
