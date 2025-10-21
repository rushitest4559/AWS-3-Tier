import boto3
import time
from typing import List, Dict, Any

from scripts.config.aws_config import (
    BASE_AMI_ID, INSTANCE_TYPE, AWS_REGION, 
    FRONTEND_TAGS, BACKEND_TAGS, 
    WAIT_EC2_RUNNING, WAIT_USER_DATA_COMPLETE
)

class EC2ManagerError(Exception):
    """Custom exception for EC2 management errors."""
    pass

# Initialize Boto3 EC2 client
ec2_client = boto3.client('ec2', region_name=AWS_REGION)

def launch_builder_instances(
    terraform_outputs: Dict[str, Any],
    user_data_frontend: str,
    user_data_backend: str
) -> List[str]:
    """
    Launches two EC2 instances (Frontend and Backend builders) in the public subnet 
    defined by Terraform outputs. Waits for them to reach the 'running' state.

    Args:
        terraform_outputs: Dictionary containing dynamic resource IDs from Terraform.
        user_data_frontend: The script to run on the frontend builder instance.
        user_data_backend: The script to run on the backend builder instance.
        
    Returns:
        A list of the launched instance IDs.
        
    Raises:
        EC2ManagerError: If instance launch fails or instances do not become ready.
    """
    print("\n--- Step 2: Launching Builder Instances ---")

    # Extract required IDs from Terraform outputs
    try:
        subnet_id = terraform_outputs['public_subnet_id']
        sg_id = terraform_outputs['builder_instance_sg_id']
        vpc_id = terraform_outputs['vpc_id'] # Note: vpc_id is currently not strictly needed for launch, but good to have for context/future checks.
    except KeyError as e:
        raise EC2ManagerError(f"Missing required Terraform output: {e}")

    # Configuration for the two instances
    instance_configs = [
        {
            'name': 'Frontend Builder',
            'user_data': user_data_frontend,
            'tags': FRONTEND_TAGS
        },
        {
            'name': 'Backend Builder',
            'user_data': user_data_backend,
            'tags': BACKEND_TAGS
        }
    ]

    launched_ids = []

    try:
        for config in instance_configs:
            print(f"   Launching {config['name']}...")
            
            response = ec2_client.run_instances(
                ImageId=BASE_AMI_ID,
                InstanceType=INSTANCE_TYPE,
                MinCount=1,
                MaxCount=1,
                UserData=config['user_data'],
                NetworkInterfaces=[{
                    'DeviceIndex': 0,
                    'AssociatePublicIpAddress': True, # Required for pulling code/installing packages
                    'SubnetId': subnet_id,
                    'Groups': [sg_id]
                }],
                TagSpecifications=[{
                    'ResourceType': 'instance',
                    'Tags': config['tags']
                }]
            )
            instance_id = response['Instances'][0]['InstanceId']
            launched_ids.append(instance_id)
            print(f"     -> Launched instance ID: {instance_id}")

        # Wait for instances to be running
        print("   Waiting for instances to enter 'running' state...")
        waiter = ec2_client.get_waiter('instance_running')
        waiter.wait(InstanceIds=launched_ids, WaiterConfig={'Delay': 15, 'MaxAttempts': int(WAIT_EC2_RUNNING / 15)})
        print("   Instances are running. Waiting for User Data to complete...")
        
        # --- CRITICAL WAIT FOR USER DATA ---
        # In a real environment, you would use Cloud-Init logs or a custom signal
        # (like pushing a metric to CloudWatch) instead of a simple sleep.
        print(f"   Sleeping for {WAIT_USER_DATA_COMPLETE} seconds for application setup (User Data) to finish...")
        time.sleep(WAIT_USER_DATA_COMPLETE)
        print("   User Data execution window complete.")
        
        return launched_ids

    except Exception as e:
        # If launching fails, we still want to ensure cleanup runs in main.py
        raise EC2ManagerError(f"Failed to launch or wait for EC2 instances: {e}")


def terminate_builder_instances(instance_ids: List[str]):
    """
    Terminates the builder instances. This is called in the 'finally' block 
    of the main pipeline for cleanup.
    """
    print("\n--- Step 5: Cleaning up Builder Instances ---")
    if not instance_ids:
        print("   No builder instances to terminate.")
        return

    try:
        print(f"   Terminating instances: {', '.join(instance_ids)}...")
        ec2_client.terminate_instances(InstanceIds=instance_ids)

        waiter = ec2_client.get_waiter('instance_terminated')
        waiter.wait(InstanceIds=instance_ids)
        print("   Cleanup complete. Instances terminated.")

    except Exception as e:
        print(f"   WARNING: Failed to terminate instances {instance_ids}: {e}", file=sys.stderr)
