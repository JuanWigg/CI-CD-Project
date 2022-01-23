# CI/CD Pipeline using Jenkins, Docker and AWS.
In this project i will apply my knowledge about Terraform, Docker, and Jenkins. We will try to build an infraestructure on Amazon EC2, formed by a Jenkins Master, a Jenkins Slave, and a Web Server running with Docker.

## How to - Step by Step guide to using the project.
### Step 1
First of all, you need to deploy the infraestructure using the Terraform file *(Terraform/main.tf)*. However, you still need to create the ECR Repo and the IAM Role to let the EC2 instances acces the repo.

### Step 2
Enter to the Jenkins Master using *ip:8080* and configure the new Admin user. 

### Step 3
After creating our admin user, we need to add more nodes to our Jenkinsmaster. We can do this by going to *http://JenkinsIP:8080/manage -> Config nodes -> Add node*

### Step 4
Configure first pipeline using the Jenkinsfile located at *Jobs/mvn_test_build_docker* folder. 
Also, use the **"GitHub hook trigger for GITScm polling" Build Trigger** and remember to put the URL of the GitHub repo on the *GitHub Project* field.


### Step 5
Configure the second pipeline for the project. This time we will use the Jenkinsfile located at *Jobs/deploy_on_web* folder.
On the build trigger section we gotta use the **"Build after other projects" Build Trigger** and we need to specify the previous pipeline we created.

Remember to select the appropiate Jenkinsfile for the pipeline like we did on the previous step.
