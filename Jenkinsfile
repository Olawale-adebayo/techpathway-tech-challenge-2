pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
  }

  // Check GitHub every 2 minutes so a push triggers a build with no manual step.
  triggers {
    pollSCM('H/2 * * * *')
  }

  environment {
    AWS_REGION       = 'us-east-1'
    PROJECT          = 'techpathway'            // must match var.project_name in Terraform
    ECS_CLUSTER      = "${PROJECT}-cluster"
    FRONTEND_REPO    = "${PROJECT}-frontend"
    BACKEND_REPO     = "${PROJECT}-backend"
    FRONTEND_SERVICE = "${PROJECT}-frontend"
    BACKEND_SERVICE  = "${PROJECT}-backend"
    IMAGE_TAG        = "${BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Resolve AWS Account') {
      steps {
        // Credentials come from the EC2 instance's IAM role, so no keys are stored in Jenkins.
        script {
          env.ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
          env.REGISTRY   = "${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
        }
        echo "Deploying to registry ${env.REGISTRY}"
      }
    }

    stage('Build Images') {
      steps {
        sh '''
          docker build -t $REGISTRY/$BACKEND_REPO:$IMAGE_TAG  -t $REGISTRY/$BACKEND_REPO:latest  backend
          docker build -t $REGISTRY/$FRONTEND_REPO:$IMAGE_TAG -t $REGISTRY/$FRONTEND_REPO:latest frontend
        '''
      }
    }

    stage('Login to ECR') {
      steps {
        sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY'
      }
    }

    stage('Push Images') {
      steps {
        sh '''
          docker push $REGISTRY/$BACKEND_REPO:$IMAGE_TAG
          docker push $REGISTRY/$BACKEND_REPO:latest
          docker push $REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
          docker push $REGISTRY/$FRONTEND_REPO:latest
        '''
      }
    }

    stage('Deploy to ECS') {
      steps {
        sh '''
          aws ecs update-service --cluster $ECS_CLUSTER --service $BACKEND_SERVICE  --force-new-deployment --region $AWS_REGION > /dev/null
          aws ecs update-service --cluster $ECS_CLUSTER --service $FRONTEND_SERVICE --force-new-deployment --region $AWS_REGION > /dev/null
          aws ecs wait services-stable --cluster $ECS_CLUSTER --services $BACKEND_SERVICE $FRONTEND_SERVICE --region $AWS_REGION
        '''
      }
    }
  }

  post {
    success {
      echo 'Deployment finished: both ECS services are stable on the new images.'
    }
    failure {
      echo 'Pipeline failed. Check the stage logs above.'
    }
    always {
      sh 'docker image prune -f || true'
    }
  }
}
