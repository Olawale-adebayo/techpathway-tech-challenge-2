## TechPathway Tech Challenge 2: Full-Stack Deployment with Jenkins, Docker and AWS

A React frontend and a Node.js backend, containerised with Docker, pushed to Amazon ECR and deployed on Amazon ECS (Fargate) behind an Application Load Balancer. A Jenkins server on AWS builds and deploys both automatically on every push to GitHub. All infrastructure for the app is created with Terraform.

- **Frontend (public):** http://techpathway-alb-237264529.us-east-1.elb.amazonaws.com
- **Backend health/status:** http://techpathway-alb-237264529.us-east-1.elb.amazonaws.com/api/status
- **Jenkins:** http://3.230.231.18:8080 (login details are in the submission PDF)
- **Region:** us-east-1

## Architecture

```text
GitHub --(poll every 2 min)--> Jenkins (EC2) --build--> Docker images
                                                  |
                                          push to Amazon ECR
                                                  |
                                    ECS update-service (force new deployment)
                                                  |
Browser --> ALB :80 --+-- /      --> frontend service (nginx, port 80)
                      +-- /api/* --> backend service (Node, port 8080)
```

The frontend calls the backend on the same origin (`/api/...`), and the ALB routes `/api/*` to the backend. The backend allows the ALB origin through the `CORS_ORIGIN` environment variable.

## Jenkins on AWS: supporting resources

Jenkins was set up manually in the AWS console. It is publicly reachable on port 8080.

| Resource | Details |
|---|---|
| EC2 instance | `t3.medium`, Amazon Linux 2023, public IPv4 address, runs Jenkins, Docker, Git and the AWS CLI |
| Security group `Jenkins-sg` | Inbound TCP 22 (SSH) and TCP 8080 (Jenkins UI); all outbound allowed |
| Key pair `jenkins-key` | Used for SSH access to the instance |
| IAM role `techpathway-jenkins-role` | Attached to the instance as an instance profile, so no AWS keys are stored in Jenkins. Permissions: `AmazonEC2ContainerRegistryPowerUser` (login and push to ECR) plus an inline policy allowing `ecs:UpdateService`, `ecs:DescribeServices`, `ecs:DescribeClusters` and `ecs:ListServices` |
| Network | Default VPC with an internet gateway attached and a `0.0.0.0/0` route to it, so the instance is reachable from the internet and can reach GitHub, ECR and ECS |
| Swap and `/tmp` | A swap file and a larger `/tmp` were added so Jenkins' disk-space check passes on this instance size |

## Infrastructure as code (Terraform)

The `terraform/` folder creates, in `us-east-1`:

- **Network:** VPC (`10.0.0.0/16`), 2 public subnets in different availability zones, an internet gateway, a public route table and its associations
- **Security groups:** `alb-sg` (HTTP 80 from the internet) and `ecs-tasks-sg` (traffic allowed only from the ALB)
- **Load balancer:** Application Load Balancer, HTTP listener, frontend and backend target groups, and a listener rule sending `/api/*` to the backend
- **ECR:** `techpathway-frontend` and `techpathway-backend` repositories
- **ECS:** cluster `techpathway-cluster`, CloudWatch log groups, a task execution role, backend and frontend task definitions, and two Fargate services (`techpathway-backend`, `techpathway-frontend`)

## CI/CD pipeline (Jenkinsfile)

Jenkins job `techpathway-pipeline` uses "Pipeline script from SCM" and polls GitHub every 2 minutes. No manual steps are needed after a push.

1. **Checkout:** pull the repo from GitHub
2. **Resolve AWS Account:** read the account ID from the instance role
3. **Build Images:** build the backend and frontend Docker images, tagged with the build number and `latest`
4. **Login to ECR:** `aws ecr get-login-password | docker login`
5. **Push Images:** push all tags to ECR
6. **Deploy to ECS:** `aws ecs update-service --force-new-deployment` for both services, then wait until both are stable

## How to deploy

1. **Create the infrastructure** (needs AWS credentials, Terraform and AWS CLI installed locally):
```bash
   cd terraform
   terraform init
   terraform apply
```
   Note the `app_url` output. This is the public frontend URL.
2. **Set up Jenkins** on EC2 as described above, with Docker, Git and the AWS CLI installed, and the IAM role attached to the instance.
3. **Create a Pipeline job** in Jenkins: Definition = *Pipeline script from SCM*, SCM = Git, repository = this repo, branch = `main`, Script Path = `Jenkinsfile`. Click **Build Now** once.
4. From then on, every `git push` to `main` triggers a build and a deployment.

## How to test

1. Open the frontend URL in a browser. The page should show **SUCCESS** and a GUID, which proves the frontend reached the backend.
2. Open `<frontend URL>/api/status`. It should return JSON from the backend.
3. To test the pipeline end to end, change the heading in `frontend/src/App.js`, commit and push. Within about 2 minutes a new Jenkins build starts, and a few minutes later the new heading appears at the frontend URL.

## Run locally (optional)

```bash
# backend
cd backend && npm ci && npm start
# frontend (second terminal)
cd frontend && npm ci && npm start
```

## Clean up

```bash
cd terraform
terraform destroy
```

Then terminate the Jenkins EC2 instance and delete its security group, key pair, IAM role and the internet gateway if they are no longer needed.

 **Tech Challenge 2 – Full-Stack Deployment with Jenkins, Docker & AWS**

### **Starter Code Repository**

You'll be working from this repo, which already includes the React frontend and Express backend you'll deploy:

👉 https://github.com/sholaolujobi/techpathway-tech-challenge-2

Clone the repo before you start.

You can modify the code if needed for your pipeline or infrastructure.

---

## **Challenge Duration**

You have 96 **hours** from the moment you receive this to complete everything.

---

## **What You're Being Tested On**

This challenge checks your understanding of:

- Cloud infrastructure
- Infrastructure as Code
- Automated deployments
- CI/CD concepts
- Documentation and clarity

You'll take an existing app and turn it into a fully automated deployment pipeline on AWS.

---

## **What You Need to Build**

### **1. Jenkins Setup**

- Launch a Jenkins server on AWS.
- Make sure it's publicly reachable.
- You can create everything manually (EC2, IAM, permissions, etc.).
- In your README, include a short description of the AWS resources that support your Jenkins instance.

---

### **2. Frontend & Backend Deployment**

Using the code from the repo:

- Containerize both the frontend and backend
- Deploy both apps on **AWS ECS**
- The **frontend must be publicly reachable** in a browser
- The frontend must successfully call the backend endpoint once deployed

---

### **3. CI/CD Pipeline**

Create a Jenkins pipeline that:

- Pulls your GitHub repo
- Builds both Docker images
- Logs in to ECR
- Pushes the images
- Triggers an update on your ECS services so the new versions deploy automatically

Pipeline should run end-to-end with no manual steps once triggered.

---

### **4. Terraform Infrastructure**

Use Terraform to create everything required for your deployment:

- VPC + subnets
- Internet access (IGW, route tables)
- Security groups
- ECS cluster
- Task definitions (frontend + backend)
- ECS services
- (Optional) ECR repositories

Terraform **does not need** to build your Jenkins server unless you want to.

---

## **How to Run the App Locally (for Testing)**

**Backend**

```
cd backend
npm ci
npm start
```

Runs on: `localhost:8080`

**Frontend**

```
cd frontend
npm ci
npm start
```

Runs on: `localhost:3000`

If everything works, the frontend will show **SUCCESS** and a GUID.

---

## **Important Config Files**

- **frontend/src/config.js** → set backend URL
- **backend/config.js** → CORS settings

---

# **How to Submit**

When you finish, put everything into **one PDF** and upload it in the Slack submission channel.

Your PDF must include:

1. **A screenshot of the deployed frontend**

    (The live app running in the browser.)

2. **A screenshot of your Jenkins pipeline after a successful run**
3. **Your GitHub repo link**

    This repo must include your Terraform files, Dockerfiles, Jenkinsfile, and any changes you made.

4. **The public URL of your frontend**
5. **The Jenkins server URL + login details**
6. **Short, simple instructions**

    A few lines on how to test or deploy your setup.

Once everything is inside the PDF, upload that PDF directly into the Slack channel.

That's your final submission.

---

## **How You'll Be Graded**

We'll review your work based on:

- Does the app run successfully on AWS?
- Does your Jenkins pipeline deploy both apps correctly?
- Is your Terraform code clean and accurate?
- How organized and clear is your repo + documentation?
