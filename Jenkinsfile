pipeline {
    agent any

    parameters {
        choice(
            name: 'TF_ACTION',
            choices: ['apply', 'destroy'],
            description: 'Choose Terraform action'
        )
    }

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
            when {
                expression { params.TF_ACTION == 'apply' }
            }
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
            when {
                expression { params.TF_ACTION == 'apply' }
            }
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
            when {
                expression { params.TF_ACTION == 'apply' }
            }
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-ssh-key',
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh '''
                    cd ansible
                    ansible-playbook -i inventory.ini playbooks/setup.yml \
                      --private-key "$SSH_KEY" \
                      --become
                    '''
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.TF_ACTION == 'destroy' }
            }
            steps {
                input message: "⚠️ Confirm Terraform DESTROY?"

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
