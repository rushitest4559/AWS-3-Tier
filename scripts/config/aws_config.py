# Configuration for AWS Pipeline

# Shared EC2 and AMI Settings
# NOTE: Resource IDs (SGs, LTs, ASG Names) are now read dynamically from Terraform outputs.

# Replace with a common base AMI (e.g., Amazon Linux 2 or Ubuntu)
BASE_AMI_ID = 'ami-06fa3f12191aa3337' 
INSTANCE_TYPE = 't2.micro'
AWS_REGION = 'ap-south-1' # Specify the region to use Boto3

# Timing and Wait Settings (in seconds)
WAIT_EC2_RUNNING = 300      # Max wait for EC2 to enter running state
WAIT_USER_DATA_COMPLETE = 300 # Critical: Wait 5 min for script execution signal (adjust as needed)
WAIT_AMI_AVAILABLE = 600    # Max wait for AMI creation (up to 10 minutes)
WAIT_ASG_ROLLOUT = 1800     # Max wait for ASG instance refresh (30 minutes)

# --- INSTANCE TAGS ---
# Tag keys used for identifying the builder instances
FRONTEND_TAGS = [{'Key': 'Name', 'Value': 'Builder-Frontend'}, {'Key': 'Role', 'Value': 'Frontend'}]
BACKEND_TAGS = [{'Key': 'Name', 'Value': 'Builder-Backend'}, {'Key': 'Role', 'Value': 'Backend'}]
