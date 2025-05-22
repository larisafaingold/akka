# Akka

This project contains a sample Akka application, along with configurations for local execution and deployment to various platforms.

## Local Development & Execution

### Prerequisites
- Docker installed

### Build & Run Locally
1.  Build the container image:
    ```bash
    docker build -t akka-app .
    ```
2.  Run the application:
    ```bash
    docker run -p 5000:5000 akka-app
    ```
3.  Access the application at `http://127.0.0.1:5000`.

## AWS ECS Fargate Deployment (via Terraform)

This setup deploys the Akka application to AWS ECS Fargate, making it accessible via its private IP address within the configured VPC.

### Prerequisites
- AWS Account & IAM User with necessary permissions to create ECS, IAM, EC2 (Security Groups), CloudWatch Logs resources.
- AWS CLI configured with credentials (e.g., via `aws configure` or environment variables).
- Terraform installed.
- Docker installed (for pushing the image to a registry if not using a public one like `images.paas.redhat.com/rhel-ai-cicd/akka:latest`).

### Deployment Steps

1.  **Navigate to the deployment directory:**
    ```bash
    cd deployment
    ```

2.  **Update Image (If Necessary):**
    The current configuration in `deployment/main.tf` uses `image = "images.paas.redhat.com/rhel-ai-cicd/akka:latest"`.
    If you have your own image:
    *   Build and push your Docker image to a container registry (e.g., Amazon ECR, Docker Hub).
    *   Update the `image` value in `aws_ecs_task_definition.akka_app` within `deployment/main.tf` to point to your image URI.

3.  **Initialize Terraform:**
    This downloads the necessary provider plugins.
    ```bash
    terraform init
    ```

4.  **Review the Plan (Optional but Recommended):**
    See what resources will be created/modified.
    ```bash
    terraform plan
    ```

5.  **Apply the Configuration:**
    This will provision the AWS resources.
    ```bash
    # Ensure AWS_PROFILE is set if needed, e.g., export AWS_PROFILE=your-profile
    terraform apply -auto-approve
    ```

### Accessing the Service (AWS)
- Once deployed, the ECS tasks will be running in private subnets.
- To access the service, you'll need to get the private IP address of one of the running Fargate tasks. You can find this in the AWS ECS console by navigating to your cluster -> service -> tasks tab.
- The application, by default (as per the current `main.tf`), exposes port 5000. Access it via `http://<FARGATE_TASK_PRIVATE_IP>:5000`.
- Ensure you are accessing it from a machine within the same VPC or a peered VPC, or via a VPN connection that has access to the VPC. The security group `akka-internal-sg` by default allows access from `10.0.0.0/8`.

### Tagging (AWS)
- All created AWS resources are tagged with `Project = "aipcc-akka"`.
- Tags from the ECS Task Definition are propagated to the running ECS tasks.

### Cleaning Up (AWS)
To remove all AWS resources created by this configuration:
```bash
# Navigate to the deployment directory
cd deployment

# Ensure AWS_PROFILE is set if needed
terraform destroy -auto-approve
```

## OpenShift Deployment

This section outlines deploying the Akka application to an OpenShift cluster using the provided `deployment/openshift-deployment.yaml` file.

### Prerequisites
- OpenShift CLI (`oc`) installed and configured to connect to your cluster.
- The Docker image `images.paas.redhat.com/rhel-ai-cicd/akka:latest` (as specified in the YAML) should be accessible by your OpenShift cluster. If using a different image, update the `Deployment` in `deployment/openshift-deployment.yaml`.

### Deployment Steps

1.  **Login to OpenShift (if not already):**
    ```bash
    oc login ...
    ```

2.  **Target Namespace:**
    The `deployment/openshift-deployment.yaml` file specifies the namespace `rhel-ai-cicd--akka` for all its resources.
    Ensure this namespace exists or that you have permissions to create it if it's created by `oc apply`. Alternatively, modify the `namespace` fields in the YAML file to your desired project.
    If you need to be in a specific project before applying (and the YAML doesn't create it or you want to override):
    ```bash
    oc project rhel-ai-cicd--akka
    # or, if creating for the first time and the YAML doesn't handle it:
    # oc new-project rhel-ai-cicd--akka
    ```

3.  **Apply the Deployment Configuration:**
    ```bash
    oc apply -f deployment/openshift-deployment.yaml
    ```

### Accessing the Service (OpenShift)
- The `deployment/openshift-deployment.yaml` creates a `Service` (`akka-app-service`) that exposes the application on port 80 (forwarding to container port 5000).
- It also creates a `Route` (`akka-app-route`) to make the service accessible externally.

### Cleaning Up (OpenShift)
To remove the resources deployed to OpenShift using this YAML file:
```bash
oc delete -f deployment/openshift-deployment.yaml
```
