#!/bin/bash

# a script to install jenkins and then install docker.
# The script is intended systems with "apt-get" package manager
echo "Start of the script, this will install: jdk11, jenkins, docker"
if command -v apt-get &> /dev/null; then
    echo "apt-get is installed."
else
    echo "apt-get package manager is not installed. cannot proceed"
    exit 1
fi
## install java jdk11 as prerequisite ##
# switch to root
sudo -i
apt-get update
apt-get install fontconfig openjdk-11-jre -y
if java --version &> /dev/null; then
    echo "Java is installed."
    java --version
else
    echo "Java installation failed."
    echo "terminating script"
    exit 1
fi
## install jenkins ##
wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install jenkins
systemctl enable jenkins
systemctl start jenkins
if jenkins --version &> /dev/null; then
    echo "Jenkins is installed."
    jenkins --version
else
    echo "Jenkins installation failed."
    echo "terminating script"
    exit 1
fi
## install docker ##
# make sure there are not other docker installantions on the vm
apt-get remove docker docker-engine docker.io
apt-get update
apt install docker.io -y
snap install docker
# Check if Docker is installed
if docker --version &> /dev/null; then
    echo "Docker is installed."
    docker --version
else
    echo "Docker installation failed."
    echo "terminating script"
    exit 1
fi
# add the docker user to relevant groups to allow execution of command without being root
groupadd docker
usermod -aG docker ubuntu
usermod -aG docker jenkins
## install aws-cli ##
apt-get install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
#aws credential helper (for ECR)
apt install amazon-ecr-credential-helper -y
if aws --version &> /dev/null; then
    echo "aws-cli is installed."
    aws --version
else
    echo "aws-cli installation failed."
    echo "terminating script"
    exit 1
fi
## install kubectl ##
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
apt install amazon-ecr-credential-helper -y
if kubectl version --client &> /dev/null; then
    echo "kubectl is installed."
    kubectl version --client
else
    echo "kubectl installation failed."
    echo "terminating script"
    exit 1
fi

# if all went right, prompt to reboot the system
echo "installation done! a reboot is need for completion"
read -p "Do you want to reboot now? (y/n): " response

if [ "$response" == "y" ] || [ "$response" == "Y" ]; then
    echo "Rebooting the system..."
    sleep 2
    sudo reboot
else
    echo "Script aborted. No reboot."
fi