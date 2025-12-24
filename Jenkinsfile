pipeline {
    agent { label 'linux' }

    tools {
        git 'Default'
        terraform 'terraform'
        ansible 'ansible'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        TF_IN_AUTOMATION    = 'true'
        TF_CLI_ARGS         = '-no-color'
        AWS_REGION          = 'us-east-1'
        AWS_DEFAULT_REGION  = 'us-east-1'
    }


    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        terraform init -input=false
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
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
                    sh 'terraform plan -var-file=dev.tfvars'
                }
            }
        }

        stage('Validate Apply') {
            steps {
                input message: 'Approve Terraform Apply for DEV?',
                      ok: 'Apply'
            }
        }

        stage('Terraform Apply & Capture Outputs') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        sh 'terraform apply -auto-approve -var-file=dev.tfvars'

                        env.INSTANCE_ID = sh(
                            script: 'terraform output -raw instance_id',
                            returnStdout: true
                        ).trim()

                        env.INSTANCE_IP = sh(
                            script: 'terraform output -raw instance_public_ip',
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }

        stage('Create Dynamic Inventory') {
            steps {
                sh '''
                    echo "[splunk]" > dynamic_inventory.ini
                    echo "${INSTANCE_IP} ansible_user=ec2-user" >> dynamic_inventory.ini
                '''
            }
        }

        stage('Wait for EC2 Health Check') {
            steps {
                sh '''
                    aws ec2 wait instance-status-ok \
                    --instance-ids ${INSTANCE_ID}
                '''
            }
        }

        stage('Install Splunk') {
            steps {
                ansiblePlaybook(
                    playbook: 'playbooks/splunk.yml',
                    inventory: 'dynamic_inventory.ini'
                )
            }
        }

        stage('Test Splunk') {
            steps {
                ansiblePlaybook(
                    playbook: 'playbooks/test-splunk.yml',
                    inventory: 'dynamic_inventory.ini'
                )
            }
        }

        stage('Validate Destroy') {
            steps {
                input message: 'Approve Terraform Destroy?',
                      ok: 'Destroy'
            }
        }

        stage('Terraform Destroy') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh 'terraform destroy -auto-approve -var-file=dev.tfvars'
                }
            }
        }
    }

    post {
        always {
            script {
                if (fileExists('dynamic_inventory.ini')) {
                    sh 'rm -f dynamic_inventory.ini'
                }
            }
        }

        failure {
            script {
                sh 'terraform destroy -auto-approve -var-file=dev.tfvars || true'
            }
        }

        aborted {
            script {
                sh 'terraform destroy -auto-approve -var-file=dev.tfvars || true'
            }
        }

        success {
            echo "BYOD-3 Pipeline completed successfully"
        }
    }
}
