import sys
from pathlib import Path

# --- CRITICAL FIX: Add project root to Python path for module resolution ---
# This ensures that 'scripts.terraform.reader' can be found.
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
sys.path.append(str(PROJECT_ROOT))
# --------------------------------------------------------------------------

# Import modules from our project structure
from scripts.terraform.reader import get_terraform_outputs, TerraformReaderError
from scripts.aws.ec2_manager import launch_builder_instances, terminate_builder_instances, EC2ManagerError
from scripts.aws.ami_manager import build_golden_amis_and_update_templates, AMIManagerError
from scripts.aws.asg_manager import update_asgs_and_monitor_rollout, ASGManagerError

# The rest of the script uses the previously calculated paths
FRONTEND_USER_DATA_PATH = SCRIPT_DIR / "config" / "frontend_user_data.sh"
BACKEND_USER_DATA_PATH = SCRIPT_DIR / "config" / "backend_user_data.sh"

def load_user_data(file_path: Path) -> str:
    """Safely loads the content of a user data shell script."""
    try:
        with open(file_path, 'r') as f:
            return f.read()
    except FileNotFoundError:
        print(f"Error: User Data file not found at {file_path}", file=sys.stderr)
        sys.exit(1)

def run_pipeline():
    """
    Main orchestration function for the Golden AMI pipeline.
    Ensures temporary resources are cleaned up.
    """
    print("--- Starting Golden AMI Update Pipeline ---")
    
    # Variables to track created resources for cleanup
    builder_instance_ids = []
    
    try:
        # 1. READ CONFIGURATION INPUTS
        print("\n--- Step 1: Reading Configurations ---")
        terraform_outputs = get_terraform_outputs(PROJECT_ROOT / "infra") # Use PROJECT_ROOT here
        
        user_data_frontend = load_user_data(FRONTEND_USER_DATA_PATH)
        user_data_backend = load_user_data(BACKEND_USER_DATA_PATH)
        
        print("   Configuration data loaded successfully.")
        
        # 2. LAUNCH BUILDER INSTANCES
        builder_instance_ids = launch_builder_instances(
            terraform_outputs=terraform_outputs,
            user_data_frontend=user_data_frontend,
            user_data_backend=user_data_backend
        )
        
        # 3. CREATE AMIs AND LAUNCH TEMPLATE VERSIONS
        build_golden_amis_and_update_templates(builder_instance_ids, terraform_outputs)
        
        # 4. UPDATE ASGs AND ROLLOUT
        update_asgs_and_monitor_rollout(terraform_outputs)
        
        print("\n--- PIPELINE SUCCESSFUL ---")

    except (TerraformReaderError, EC2ManagerError, AMIManagerError, ASGManagerError) as e:
        print(f"\n--- PIPELINE FAILED ---", file=sys.stderr)
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)
        
    finally:
        # 5. CLEANUP
        # This block ALWAYS runs, ensuring instances are terminated even on failure.
        if builder_instance_ids:
            terminate_builder_instances(builder_instance_ids)
        
        print("--- Pipeline Finished ---")

if __name__ == "__main__":
    run_pipeline()
