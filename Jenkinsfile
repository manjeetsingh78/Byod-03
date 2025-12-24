pipeline {
    agent { label 'linux' }

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

        stage('Verify Tools') {
            steps {
                sh '''
                    echo "=== Tool Versions ==="
                    git --version
                    terraform version
                    ansible --version
                '''
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
                    sh 'terraform init -input=false'
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

        stage('Approve Apply') {
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
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

                        echo "EC2 ID: ${env.INSTANCE_ID}"
                        echo "EC2 IP: ${env.INSTANCE_IP}"
                    }
                }
            }
        }

        stage('Create Ansible Inventory') {
            steps {
                sh '''
                    echo "[splunk]" > dynamic_inventory.ini
                    echo "${INSTANCE_IP} ansible_user=ec2-user" >> dynamic_inventory.ini
                    cat dynamic_inventory.ini
                '''
            }
        }

        stage('Wait for EC2') {
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

        stage('Approve Destroy') {
            steps {
                input message: 'Approve Terraform Destroy?', ok: 'Destroy'
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
            sh 'rm -f dynamic_inventory.ini || true'
        }

        failure {
            sh 'terraform destroy -auto-approve -var-file=dev.tfvars || true'
        }

        aborted {
            sh 'terraform destroy -auto-approve -var-file=dev.tfvars || true'
        }

        success {
            echo '✅ BYOD-3 Pipeline completed successfully'
        }
    }
}
