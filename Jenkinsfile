pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        ANSIBLE_HOST_KEY_CHECKING = "False"
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                terraform --version
                ansible --version
                aws --version
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                    cd terraform/environments/dev
                    terraform init
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                    cd terraform/environments/dev
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                sh '''
                cd terraform/environments/dev
                EC2_IP=$(terraform output -raw ec2_public_ip)

                cd ../../../ansible
                cat > inventory.ini <<EOF
[ec2]
dev ansible_host=$EC2_IP ansible_user=ec2-user ansible_python_interpreter=/usr/bin/python3
EOF
                '''
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-ssh-key',
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh '''
                    cd ansible
                    ansible-playbook -i inventory.ini playbooks/setup.yml \
                      --private-key $SSH_KEY \
                      --become
                    '''
                }
            }
        }

        stage('Terraform Destroy (Manual Approval)') {
            when {
                expression { return false }   // disabled by default
            }
            steps {
                input message: "Destroy EC2 instance?"
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                    cd terraform/environments/dev
                    terraform destroy -auto-approve
                    '''
                }
            }
        }
    }
}
