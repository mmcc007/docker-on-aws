# Terraform EC2 Docker Setup

This repository contains a Terraform configuration to set up an AWS EC2 instance that runs a Docker container. The Docker container uses the image `ghcr.io/cinnamon/kotaemon:main-full`, which is automatically deployed and runs a Gradio server.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed.
- AWS credentials configured (either via environment variables or through AWS CLI configuration).
- An SSH key pair. Ensure you have a public key available at `~/.ssh/aws-ssh-key.pub` or modify the configuration to point to your desired key location.

## Resources Created

1. **AWS Key Pair**: Creates an SSH key pair named `aws-ssh-key`.
2. **EC2 Instance**: Provisions an Ubuntu 24.04 instance.
3. **Security Group**: Creates a security group to allow:
   - SSH access on port 22.
   - Access to the Gradio server on port 7860.

## Usage

### Steps to Deploy

### Accessing the Docker Image

Once the EC2 instance is running, you can access the Docker container via the public DNS of the instance. The Docker container runs a Gradio server that is exposed on port 7860.

To access the Gradio interface, open a web browser and navigate to:

```
http://<PUBLIC_DNS>:7860
```

Replace `<PUBLIC_DNS>` with the actual public DNS name outputted by the Terraform script. You can also use the public IP address in place of the DNS name.

1. **Clone this repository**:
   ```sh
   git clone https://github.com/mmcc007/docker-on-aws
   cd docker-on-aws
   ```

2. **Initialize Terraform**:
   ```sh
   terraform init
   ```

3. **Apply the Terraform Configuration**:
   ```sh
   terraform apply
   ```
   Confirm the execution by typing `yes`. The script will output the public IP and DNS of the instance upon successful creation.

4. **Access the EC2 instance**:
   ```sh
   ssh -i ~/.ssh/aws-ssh-key ubuntu@<PUBLIC_IP>
   ```

### Upgrade Docker Image

The instance includes a script for upgrading the Docker image to the latest version.

To use the upgrade script, SSH into the instance and run:

```sh
sudo /usr/local/bin/upgrade_docker_image.sh
```

You can force an update by using the `--force` option:

```sh
sudo /usr/local/bin/upgrade_docker_image.sh --force
```

## Configuration Details

- **Docker Image**: The EC2 instance runs the Docker image `ghcr.io/cinnamon/kotaemon:main-full`. The image is exposed via Gradio at port 7860.
- **Upgrade Script**: The instance installs an upgrade script to fetch the latest Docker image version and redeploy the container if a new version is available or if the `--force` flag is provided.
- **Provisioners**: The Terraform configuration includes provisioners to output the public IP and DNS of the EC2 instance.

## Security Group Details

- **SSH Access**: Port 22 is open to allow SSH access from anywhere. Adjust this for better security.
- **Gradio Access**: Port 7860 is open to allow access to the Gradio server from anywhere.

## Notes

- Ensure your AWS credentials have permissions to create the resources specified in the configuration.
- The current setup uses a `t2.micro` instance, which may need adjustments based on the requirements of the Docker container.
- The AMI used is `ami-04dd23e62ed049936` (Canonical, Ubuntu, 24.04, amd64 noble image).

## Cleanup

To remove all resources created by Terraform, run:

```sh
terraform destroy
```
Confirm the destruction by typing `yes` when prompted.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.