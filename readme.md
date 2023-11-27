
# DP1001 - Jenkins, ECR, EKS
### (TL;DR attached the the bottom)
### *this repository was private for all of the development process but now it's public since i'm done with this project
This project shows how to take a "local" nodejs-reactjs application and dockerize it. After docker images were made, I tested them locally with docker-compose. The next step was to create a jenkins pipeline that would compile the images and push them to ECR (Amazon Elastic Container Registry). When that was done, the final step was to create some kubernetes templates and launch it with EKS (Elastic Kubernetes Service), later I had it maintained automatically as a jenkins step. In summary this project demonstrates the basics of a CI pipeline and kubernetes.  


![Pipeline](https://s3.amazonaws.com/meister.public.resources/dp1001-pipeline.png)


## Project components

### Source code
the source code was built by 'rbilag'. From beginning, I wanted to dockerize a project with a nice visual representation so I have chosen one of the great [Clone-Wars](https://github.com/GorvGoyl/Clone-Wars) collection.  
I randomly decided that i'll go with a netflix clone , but out of the bunch that were there (about 8), I aimed for one with as few third-party dependencies as possible (actually just "moviedb"), and avoided the less documented ones since my understanding of nodejs and react is little.  
Eventually i went with "[Roseflix](https://github.com/rbilag/roseflix)" project which involves: Typescript, reactjs, nodejs and mongodb (with help of "mongoose" library).

### Containerization
The original project is spreaded across two repositories. One for frontend, one for backend, and it also has an instruction to use a momgodb atlas, so I already assumed it will take 3 containers for the whole project without out-sourcing the db part.  

**mongodb container -** Just grabbed one of the latest mongodb images, created admin credentials as env vars and left it with the original port of 27017. I also tested the project with a cloud db on "mongodb atlas". Works great, just change the connection string and it will work.  

**backend container -** Even though the project was originally built on nodejs 14, I wanted to give it an upgrade. Versions 17 and above got me all sorts of strange errors which i lack the Javascript skills to solve. Version 16 required a long rebuild of the dependencies file in every build (actually I tried to build it by myself.. and failed) so i settled on 15.13  
Rest of the work was just moving the env vars from a "config.env" file to the Dockerfile, changed the "npm run" attribute from "dev" to "prod".

**frontend container -** Node version 15.13 for same reasons as before. I created two versions of the Dockerfile.  
**First** version intended for development is simple, just move the variables of ".env" file to the Dockerfile, and set a "PORT" to use a port of my choice. Unfortunately the developer didn't include a "prod" script in the "package.json file".  
**Second** version is a multi-step Dockerfile which first compiles the Javascript files using the default "build" command. Unfortunately env var references in the code are getting "sealed" at this stage and cannot be changed later. Maybe if I knew more about nodejs I could fix it.  
Second step imports from first step the "build" folder which react generates, then sets the environment mode to production and install dependencies. Another hassle is the npm web server doesn't work for prod builds, thus requires use of an external web server. I went with "serve" which is light and sufficient for the task.  

By using multi-step build i managed to reduce the image size (uncompressed) from 559MB to 400MB.

### Docker-compose
Really the simplest file there is, haven't moved any env file out because this was just for local testing. I only made sure that all of the containers have hostnames and are on same network for easy access from the backend to the mongodb container.  
Since compiled reactjs runs from the browser it didn't matter if I used "host.docker.internal" or just "localhost" to communicate with the backend

### Jenkins
Jenkins runs on an ec2 instance. It has: Java, docker, aws-cli, kubectl. I even made a bash script which installs and verifies all of the components, although making an AMI of it will be better.  

The first pipeline (source file "Jenkinsfile-BuildImage") is triggered by a push webhook from a private GitHub repository. It knows which images to build/update by a text file called "Images.txt". Each line on the file is both an image name to be created, and the name of the folder who contains the required files (under the root path, if the file is empty creation will be skipped). when an image is ready it will be pushed to AWS ECR. after it is done with the images, it triggers the kuberenetes update pipeline, clear the docker cache and clear the workspace.

(I also made a jenkinsfile which pushes the images to a private DockerHub repo, source file is "Jenkinsfile-Dockerhub").

The second pipeline (source file "Jenkinsfile-update_k8s") just executes "kubectl apply -f" for any kuberenetes template which resides in "k8s" folder and it's name is on "k8s_templates.txt". The pipeline also indicated if it was automatically triggered by "BuildImage" pipeline or by itself. at last the pipeline clears the workspace.
The pipeline also deals with two problems i had due to the nature of the project, more on that in the "compensations" section.

### ECR
ECR (Amazon Elastic Container Registry) was chosen because i was already familiar with Dockerhub and wanted to try another container hosting platform. Fortunately, if I ran jenkins server on ec2 and and use ECR, i could set up images upload process without supplying any credentials, just by assigning IAM role with "AmazonElasticContainerRegistryPublicFullAccess" policy to the instance. Complied images are [available here.](https://gallery.ecr.aws/z2m4y8s8/dp1001)

### EKS
Setting up the cluster for the first time was relatively demanding since it required manual creation of IAM roles and VPC settings. Especially the process of granting cluster management to another IAM user in the account (edit the "aws-auth" config-map in vi editor from the cloudshell console).  

After the initial configurations, all of the next times when I had to launch the cluster went fast. I configured node-groups and load-balancers as for my needs and they all went well.

It is infamous that EKS is a bit harder to learn than AKS and GKE but i wasn't aware that it is also pricier than them. it costs 0.10$ per hour per cluster, I had to use one t2.small node (instead of the free t2.micro) because the frontend container demand a bit more memory which also resulted in 0.023$ per hour

![jenkins_build_image](https://s3.amazonaws.com/meister.public.resources/dp1001/jenkins_build_image.png)
(build image and push was skipped since the images file was empty on this run, later on, a clean workspace stage was added)

![jenkins_secrets_list](https://s3.amazonaws.com/meister.public.resources/dp1001/jenkins_secrets.png)
first secret is for github, second is for dockerhub (not in use), third is the the api key to put in the k8s template.

### ECR
ECR (Amazon Elastic Container Registry) was chosen because i was already familiar with Dockerhub and wanted to try another container hosting platform. Forunately, if I ran jenkins server on ec2 and and use ECR, i could set up images upload process without supplying any credentials, just by assigning IAM role with "AmazonElasticContainerRegistryPublicFullAccess" policy to the instance. Complied images are [avalible here.](https://gallery.ecr.aws/z2m4y8s8/dp1001)

### EKS
Setting up the cluster for the first time was relatively demanding since it required manual creation of IAM roles and VPC settings. Especially the process of granting cluster management to another IAM user in the account (edit the "aws-auth" config-map in vi editor from the cloudshell console).  

After the initial configurations, all of the next times when i had to launch the cluster went fast. I configured node-groups and load-balancers as for my needs and they all went well.

It is infamous that EKS is a bit harder to learn than AKS and GKE but i wasn't aware that it is also pricier than them. it costs 0.10$ per hour per cluster, i had to use one t2.small node (instead of the free t2.micro) because the frontend container demand a bit more memory which also resulted in 0.023$ per hour

![eks_list](https://s3.amazonaws.com/meister.public.resources/dp1001/list_pods_svc_nodes.png)

## Compensations

Due to the nature of such project, and to consider I had some knowledge and time limitations, I had to build things a bit crooked. Here is the list of them:
* **Deleting the cluster after every use -** for private educational use like I did which avarages at 2 hours a day, there's no justification for paying 2.4$ a day just to not go through cluster lunch, it's a bit of a shame that Amazon doesn't give it for free to small users like Microsoft and Google do.
* **Not using a secret manager -** aws secret manager charges 0.4$ per secret per month, and while "hcp vault" does offers 25 first secrets for free, they both require complex initial configuration on the cluster. Since I delete the cluster every day, it will be a burden to work with them. Because of that i keep the "moviedb" api key only on jenkins itself, and inject it to the secrets template only at deployment.
* **Using public repository instead of a private one -** AWS charge some money for the private ecr while the public one is free. I could use my already tested, private DockerHub, but I wanted to diversify with ECR.
* **Not hiding the mongodb credentials in the dockerfile and in backend k8s template** -  dockerfile env vars could be applied with the docker command line on the jenkins pipeline to avoid storing credentials on scm. connection string could be saved with a secret manager on a production scale cluster.
* **Using the dev frontend image instead of prod image -** because of the more "efficient" process of making the prod image, env vars which defined at first stage are being sealed into the image and cannot be changed later. Maybe there's a solution for that during the build process but I'm not that of an nodejs expert to look it up. Moreover, since I don't have a permanent URL for the api backend, have to wait for it to come up and then inject it at the frontend template, luckily I automated the task on the "k8s update" jenkinsfile.
* **Barely using jenkins modules -** Although i first tried the docker module for jenkins, it caused a lot of errors which just wast worth the time for debugging. Maybe i'll use modules for more complicated tasks.
## Future improvements
* Make a helm char for the kubernetes templates
* Work with a secret manager
* Integrate the mongodb container with a persistent volume (already have k8s template ready), install aws csi driver to provision an EBS volume
* Change CI system to "GitHub Actions", simpler to configure and can use github secrets for secrets management.

## credits

- [@rbilag](https://github.com/rbilag/roseflix) - for the original project. all javascript code was made by her.

### Final result
![frontend_in_browser](https://s3.amazonaws.com/meister.public.resources/dp1001/frontend_in_browser.png)
## TL;DR (by ChatGPT)
The project, named DP1001, demonstrates the containerization of a Node.js-React.js application using Docker. The source code, a Netflix clone named "Roseflix," involves TypeScript, React.js, Node.js, and MongoDB. The project is containerized into three parts: MongoDB, backend (Node.js), and frontend (React.js). Docker Compose is used for local testing.

Jenkins is employed for continuous integration and deployment. Two pipelines are created: one for building and pushing Docker images to Amazon ECR (Elastic Container Registry) and another for updating Kubernetes templates on Amazon EKS (Elastic Kubernetes Service).

The project uses ECR for container hosting and EKS for managing Kubernetes clusters. Due to cost considerations, the cluster is deleted after each use. Compromises include not using a secret manager, utilizing a public repository, and other adjustments for educational and cost-saving purposes.

Future improvements include creating a Helm chart for Kubernetes templates, Persistent Volumes, working with a secret manager, and exploring other CI systems like GitHub Actions.
