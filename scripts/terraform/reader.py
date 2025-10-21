import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any

class TerraformReaderError(Exception):
    """Custom exception for errors during Terraform output retrieval."""
    pass

def get_terraform_outputs(config_dir: Path) -> Dict[str, Any]:
    """
    Runs 'terraform init' and 'terraform output -json' in the specified directory,
    parses the output, and returns a dictionary containing the required keys.
    
    Args:
        config_dir: The path to the directory containing the Terraform files (infra/).
        
    Returns:
        A dictionary containing all validated Terraform output values.
        
    Raises:
        TerraformReaderError: If a command fails or a required output is missing.
    """
    
    print(f"   --- Running Terraform commands in: {config_dir} ---")
    
    # 1. Initialize Terraform
    print("   Initializing Terraform...")
    init_command = ["terraform", "init", "-input=false"]
    try:
        subprocess.run(
            init_command,
            cwd=config_dir,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        print("   Initialization successful.")
    except subprocess.CalledProcessError as e:
        raise TerraformReaderError(
            f"Terraform initialization failed. "
            f"Check your Terraform configuration in '{config_dir}'.\n"
            f"Error: {e.stderr.strip()}"
        )
        
    # 2. Retrieve outputs as JSON
    print("   Retrieving outputs...")
    output_command = ["terraform", "output", "-json"]
    try:
        result = subprocess.run(
            output_command,
            cwd=config_dir,
            capture_output=True,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError as e:
        raise TerraformReaderError(
            f"Terraform output failed. Have you run 'terraform apply'?\n"
            f"Error: {e.stderr.strip()}"
        )

    # Handle case where outputs might be empty (e.g., first run before apply)
    if not result.stdout.strip():
        raise TerraformReaderError("No Terraform outputs found. Please run 'terraform apply' first.")

    # 3. Parse JSON output
    try:
        raw_outputs = json.loads(result.stdout)
    except json.JSONDecodeError:
        raise TerraformReaderError("Failed to parse Terraform output as JSON.")
        
    # Extract the 'value' from the nested output structure
    outputs = {key: data['value'] for key, data in raw_outputs.items()}

    # 4. Validate and structure required outputs
    REQUIRED_KEYS = [
        "vpc_id",
        "public_subnet_id",
        "builder_instance_sg_id",
        "front_end_LT_id",
        "back_end_LT_id",
        "front_end_autoscaling_group_name",
        "back_end_autoscaling_group_name",
    ]
    
    validated_outputs = {}
    
    for key in REQUIRED_KEYS:
        if key not in outputs:
            raise TerraformReaderError(
                f"Required Terraform output key '{key}' is missing from outputs.tf or state file. "
                "Please verify your Terraform outputs."
            )
        validated_outputs[key] = outputs[key]
        
    print("   Outputs retrieved and validated.")
    
    return validated_outputs
