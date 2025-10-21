import boto3
import time
import base64
from typing import List, Dict, Any

from scripts.config.aws_config import AWS_REGION, WAIT_AMI_AVAILABLE
# EC2ManagerError is imported to handle instance ID to tag mapping logic
from scripts.aws.ec2_manager import EC2ManagerError 

class AMIManagerError(Exception):
    """Custom exception for AMI and Launch Template management errors."""
    pass

# Initialize Boto3 clients
ec2_client = boto3.client('ec2', region_name=AWS_REGION)
ec2_resource = boto3.resource('ec2', region_name=AWS_REGION)

def create_ami_from_instance(instance_id: str, component_name: str) -> str:
    """
    Creates an AMI from a running EC2 instance and waits for it to become available.
    """
    ami_name = f"{component_name}-AMI-{time.strftime('%Y%m%d%H%M%S')}"
    print(f"     -> Creating AMI '{ami_name}' from instance {instance_id}...")

    try:
        response = ec2_client.create_image(
            InstanceId=instance_id,
            Name=ami_name,
            Description=f"Golden AMI for {component_name} pipeline run on {time.ctime()}",
            NoReboot=False # Recommended to ensure clean snapshot
        )
        ami_id = response['ImageId']
        print(f"     -> AMI creation started. ID: {ami_id}")

        print(f"     -> Waiting up to {WAIT_AMI_AVAILABLE}s for AMI to become 'available'...")
        # Use the built-in waiter for reliability
        waiter = ec2_client.get_waiter('image_available')
        waiter.wait(ImageIds=[ami_id], WaiterConfig={'Delay': 15, 'MaxAttempts': int(WAIT_AMI_AVAILABLE / 15)})
        
        print(f"     -> AMI {ami_id} is now available.")
        return ami_id

    except Exception as e:
        raise AMIManagerError(f"Failed to create AMI for {component_name}: {e}")

def create_launch_template_version(lt_id: str, ami_id: str, component_name: str) -> int:
    """
    Creates a new version of the specified Launch Template, updating the AMI ID
    and injecting specific user data (e.g., PM2 resurrect) if needed.
    """
    lt_client = boto3.client('ec2', region_name=AWS_REGION)
    version_description = f"AMI update {time.strftime('%Y%m%d%H%M%S')} for {component_name}"
    
    print(f"     -> Creating new Launch Template version for {lt_id} (New AMI: {ami_id})...")

    # --- Conditional User Data Injection ---
    user_data_base64 = None
    if component_name == 'Backend':
        # Script to start PM2 processes that were saved by the builder instance
        pm2_startup_script = """#!/bin/bash
/usr/local/bin/pm2 resurrect
echo "PM2 processes resurrected successfully."
"""
        # AWS requires UserData to be base64 encoded
        user_data_base64 = base64.b64encode(pm2_startup_script.encode('ascii')).decode('ascii')
        print(f"     -> Injecting PM2 resurrection script into Backend LT version.")
    
    lt_data = {'ImageId': ami_id}
    if user_data_base64:
        lt_data['UserData'] = user_data_base64
    # --- End Conditional User Data Injection ---

    try:
        response = lt_client.create_launch_template_version(
            LaunchTemplateId=lt_id,
            SourceVersion='$Latest',
            VersionDescription=version_description,
            LaunchTemplateData=lt_data
        )
        new_version_number = response['LaunchTemplateVersion']['VersionNumber']
        print(f"     -> New Launch Template Version created: {new_version_number}")
        return new_version_number
    
    except Exception as e:
        raise AMIManagerError(f"Failed to create new LT version for {lt_id}: {e}")

def build_golden_amis_and_update_templates(
    builder_instance_ids: List[str], 
    terraform_outputs: Dict[str, Any]
):
    """
    Orchestrates the AMI creation and Launch Template versioning process for 
    both Frontend and Backend.
    """
    print("\n--- Step 3: Creating AMIs and Updating Launch Templates ---")

    if len(builder_instance_ids) != 2:
        raise AMIManagerError("Expected exactly two builder instance IDs.")

    # Get instance details to determine which is which using the 'Role' tag
    try:
        instances = ec2_resource.instances.filter(InstanceIds=builder_instance_ids)
        instance_map = {}
        for instance in instances:
            role_tag = next((tag['Value'] for tag in instance.tags if tag['Key'] == 'Role'), 'Unknown')
            instance_map[role_tag] = instance.id
        
    except Exception as e:
        # We handle this as an AMIManagerError as it blocks the AMI creation process
        raise AMIManagerError(f"Failed to retrieve builder instance tags: {e}")


    # Define the pipeline configuration based on Terraform outputs
    pipeline_configs = [
        {
            'component': 'Frontend',
            'instance_id': instance_map.get('Frontend'),
            'lt_id': terraform_outputs.get('front_end_LT_id')
        },
        {
            'component': 'Backend',
            'instance_id': instance_map.get('Backend'),
            'lt_id': terraform_outputs.get('back_end_LT_id')
        }
    ]

    for config in pipeline_configs:
        component = config['component']
        instance_id = config['instance_id']
        lt_id = config['lt_id']

        if not instance_id or not lt_id:
            raise AMIManagerError(f"Missing instance ID ({instance_id}) or LT ID ({lt_id}) for {component}.")

        print(f"\n  --- Processing {component} ---")
        
        # 3a. Create new AMI
        new_ami_id = create_ami_from_instance(instance_id, component)
        
        # 3b. Create new Launch Template Version pointing to the new AMI (with conditional UserData)
        create_launch_template_version(lt_id, new_ami_id, component)

    print("\n  AMI creation and Launch Template versioning complete for both components.")
