#!/usr/bin/env python3
import os
import re
import sys
import pkg_resources

# Base directory for the application
APP_ROOT = "/app"
CUSTOM_NODES_DIR = os.path.join(APP_ROOT, "custom_nodes")
SCRIPTS_DIR = os.path.join(APP_ROOT, "scripts")

# Additional packages that might be needed
ADDITIONAL_PACKAGES = [
    "torch==2.6.0",
    "torchvision",
    "torchaudio",
    "xformers==0.0.29.post3",
    "opencv-python==4.8.0.76",
    "opencv-contrib-python==4.8.0.76",
    "sageattention==1.0.6",
    "bizyengine==1.2.4",
    "pyyaml",
]

def parse_requirement(req_str):
    """Parse a requirement string and return (package_name, specs)"""
    req_str = req_str.strip()
    if not req_str or req_str.startswith('#'):
        return None
    
    try:
        # Handle git repositories
        if 'git+https' in req_str:
            match = re.search(r'#egg=([^&]*)', req_str)
            if match:
                package_name = match.group(1)
                # Create a mock Requirement object for git dependencies
                req = type('obj', (object,), {'name': package_name, '__str__': lambda self: req_str})()
                return package_name.lower(), req
        
        req = pkg_resources.Requirement.parse(req_str)
        return req.name.lower(), req
    except Exception:
        # Fallback for complex git URLs or other unparseable lines
        if 'git+https' in req_str and '#egg=' in req_str:
            match = re.search(r'#egg=([^&]*)', req_str)
            if match:
                package_name = match.group(1)
                req = type('obj', (object,), {'name': package_name, '__str__': lambda self: req_str})()
                return package_name.lower(), req

        print(f"Warning: Could not parse requirement: {req_str}", file=sys.stderr)
        return None

def find_requirements_files(start_dir):
    """Find all requirements.txt files in a directory and its subdirectories."""
    found_files = []
    print(f"Scanning for requirements.txt in {start_dir}...", file=sys.stderr)
    for root, _, files in os.walk(start_dir):
        if "requirements.txt" in files:
            found_files.append(os.path.join(root, "requirements.txt"))
    # Also check the root app directory itself, not just custom_nodes
    if os.path.exists(os.path.join(APP_ROOT, "requirements.txt")):
        found_files.append(os.path.join(APP_ROOT, "requirements.txt"))
    
    # Remove duplicates
    return sorted(list(set(found_files)))


def main():
    all_requirements = {}
    
    # Load problematic packages to exclude them from the main requirements file
    excluded_packages = []
    problematic_req_path = os.path.join(SCRIPTS_DIR, "problematic_requirements.txt")
    try:
        with open(problematic_req_path, 'r') as f:
            for line in f:
                req = parse_requirement(line)
                if req:
                    name, _ = req
                    excluded_packages.append(name)
        print(f"Loaded {len(excluded_packages)} problematic packages to exclude.", file=sys.stderr)
    except FileNotFoundError:
        print("Warning: problematic_requirements.txt not found. No packages will be specially excluded.", file=sys.stderr)
    
    # Find all local requirements files
    req_files = find_requirements_files(CUSTOM_NODES_DIR)
    
    print(f"Found {len(req_files)} requirements.txt files:", file=sys.stderr)
    for rf in req_files:
        print(f"  - {rf}", file=sys.stderr)

    for req_file_path in req_files:
        try:
            with open(req_file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    req = parse_requirement(line)
                    if req:
                        name, requirement = req
                        if name in excluded_packages:
                            continue
                        # A simple policy: the first one parsed wins.
                        # Dockerfile installs torch/xformers first, so custom reqs can't override them.
                        # For others, we assume the user manages conflicts in their custom_nodes.
                        if name not in all_requirements:
                            all_requirements[name] = requirement
        except Exception as e:
            print(f"Warning: Could not read or process {req_file_path}: {e}", file=sys.stderr)

    # Add additional packages
    for pkg in ADDITIONAL_PACKAGES:
        req = parse_requirement(pkg)
        if req:
            name, requirement = req
            if name not in excluded_packages and name not in all_requirements:
                all_requirements[name] = requirement
    
    # Output final requirements
    output_path = os.path.join(APP_ROOT, "requirements.txt")
    with open(output_path, "w") as f:
        for name in sorted(all_requirements.keys()):
            # 忽略 pathlib 这个包，因为它是 python 自带的
            if name == "pathlib":
                continue
            f.write(f"{all_requirements[name]}\n")
    
    print(f"Successfully gathered {len(all_requirements)} packages in {output_path}", file=sys.stderr)

if __name__ == "__main__":
    main() 
