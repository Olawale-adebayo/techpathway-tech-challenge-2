# TechPathway Tech Challenge 2: Full-Stack Deployment with Jenkins, Docker and AWS

A React frontend and a Node.js backend, containerised with Docker, pushed to Amazon ECR and deployed on Amazon ECS (Fargate) behind an Application Load Balancer. A Jenkins server on AWS builds and deploys both automatically on every push to GitHub. All infrastructure for the app is created with Terraform.

- **Frontend (public):** http://techpathway-alb-237264529.us-east-1.elb.amazonaws.com
- **Backend health/status:** http://techpathway-alb-237264529.us-east-1.elb.amazonaws.com/api/status
- **Jenkins:** http://3.230.231.18:8080 (login details are in the submission PDF)
- **Region:** us-east-1
- **Starter repo:** https://github.com/sholaolujobi/techpathway-tech-challenge-2

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

1. **Create the infrastructure** (needs AWS credentials, Terraform and the AWS CLI installed locally). Note the `app_url` output, which is the public frontend URL.

```bash
cd terraform
terraform init
terraform apply
```

2. **Set up Jenkins** on EC2 as described above, with Docker, Git and the AWS CLI installed, and the IAM role attached to the instance.
3. **Create a Pipeline job** in Jenkins: Definition = *Pipeline script from SCM*, SCM = Git, repository = this repo, branch = `main`, Script Path = `Jenkinsfile`. Click **Build Now** once.
4. From then on, every `git push` to `main` triggers a build and a deployment.

## How to test

1. Open the frontend URL in a browser. The page should show **SUCCESS** and a GUID, which proves the frontend reached the backend.
2. Open `<frontend URL>/api/status`. It should return JSON from the backend.
3. To test the pipeline end to end, change the heading in `frontend/src/App.js`, commit and push. Within about 2 minutes a new Jenkins build starts, and a few minutes later the new heading appears at the frontend URL.

## Run locally (optional)

```bash
# backend (runs on localhost:8080)
cd backend && npm ci && npm start
```

```bash
# frontend (runs on localhost:3000), in a second terminal
cd frontend && npm ci && npm start
```

## Clean up

```bash
cd terraform
terraform destroy
```

Then terminate the Jenkins EC2 instance and delete its security group, key pair, IAM role and the internet gateway if they are no longer needed.