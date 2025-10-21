import boto3
import time
from typing import Dict, Any

from scripts.config.aws_config import AWS_REGION, WAIT_ASG_ROLLOUT

class ASGManagerError(Exception):
    """Custom exception for Auto Scaling Group management errors."""
    pass

# Initialize Boto3 ASG client
asg_client = boto3.client('autoscaling', region_name=AWS_REGION)

def initiate_instance_refresh(asg_name: str, component_name: str):
    """
    Initiates an Instance Refresh on the Auto Scaling Group to roll out the new 
    Launch Template version.
    
    Args:
        asg_name: The name of the Auto Scaling Group.
        component_name: 'Frontend' or 'Backend' for logging.
    """
    print(f"     -> Initiating Instance Refresh on {component_name} ASG ({asg_name})...")
    
    try:
        # Start the refresh operation
        response = asg_client.start_instance_refresh(
            AutoScalingGroupName=asg_name,
            Strategy='Rolling',
            Preferences={
                # Optional: specify minimum healthy percentage during refresh
                'MinHealthyPercentage': 90 
            }
        )
        refresh_id = response['InstanceRefreshId']
        print(f"     -> Instance Refresh started. ID: {refresh_id}")
        return refresh_id

    except Exception as e:
        raise ASGManagerError(f"Failed to initiate Instance Refresh for {asg_name}: {e}")

def monitor_instance_refresh(asg_name: str, refresh_id: str, component_name: str):
    """
    Polls the AWS API to wait for the Instance Refresh operation to complete.
    """
    print(f"     -> Monitoring {component_name} Instance Refresh (ID: {refresh_id})...")
    
    start_time = time.time()
    
    while True:
        try:
            response = asg_client.describe_instance_refreshes(
                AutoScalingGroupName=asg_name,
                InstanceRefreshIds=[refresh_id]
            )
            refresh_status = response['InstanceRefreshes'][0]['Status']
            
            elapsed_time = int(time.time() - start_time)
            
            if refresh_status == 'Successful':
                print(f"     -> SUCCESS: Instance Refresh for {component_name} completed successfully in {elapsed_time}s.")
                break
            
            if refresh_status in ['Failed', 'Cancelled']:
                status_reason = response['InstanceRefreshes'][0].get('StatusReason', 'No reason provided.')
                raise ASGManagerError(f"Instance Refresh for {component_name} failed. Status: {refresh_status}. Reason: {status_reason}")

            if elapsed_time > WAIT_ASG_ROLLOUT:
                raise ASGManagerError(f"Instance Refresh for {component_name} timed out after {WAIT_ASG_ROLLOUT}s. Status: {refresh_status}")

            print(f"     -> Refresh status for {component_name}: {refresh_status} (Time elapsed: {elapsed_time}s)...")
            time.sleep(30) # Wait 30 seconds before polling again
            
        except ASGManagerError:
            # Re-raise custom errors immediately
            raise
        except Exception as e:
            # Handle API or network errors
            print(f"     -> WARNING: Error while monitoring ASG refresh: {e}. Retrying in 30s.", file=sys.stderr)
            time.sleep(30)


def update_asgs_and_monitor_rollout(terraform_outputs: Dict[str, Any]):
    """
    Orchestrates the ASG update process. Assumes the latest Launch Template
    version has already been set as the default by ami_manager.py.
    """
    print("\n--- Step 4: Updating ASGs and Monitoring Rollout ---")
    
    # 1. Extract required names from Terraform outputs
    try:
        frontend_asg_name = terraform_outputs['front_end_autoscaling_group_name']
        backend_asg_name = terraform_outputs['back_end_autoscaling_group_name']
    except KeyError as e:
        raise ASGManagerError(f"Missing required Terraform ASG output: {e}")

    pipeline_configs = [
        {'component': 'Frontend', 'asg_name': frontend_asg_name},
        {'component': 'Backend', 'asg_name': backend_asg_name}
    ]
    
    # 2. Start refresh for both components
    refresh_ids = {}
    for config in pipeline_configs:
        asg_name = config['asg_name']
        component = config['component']
        refresh_id = initiate_instance_refresh(asg_name, component)
        refresh_ids[component] = (asg_name, refresh_id)

    # 3. Monitor both refreshes sequentially
    print("\n   --- Monitoring Instance Refreshes ---")
    for component, (asg_name, refresh_id) in refresh_ids.items():
        monitor_instance_refresh(asg_name, refresh_id, component)
        
    print("\n   ASG rollouts complete for both Frontend and Backend.")
