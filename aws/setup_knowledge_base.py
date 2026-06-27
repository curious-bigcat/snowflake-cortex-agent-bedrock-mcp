"""
AWS Bedrock Knowledge Base Setup
==================================
Creates S3 bucket, uploads documents, and guides creation of a
Bedrock Managed Knowledge Base.

The KB is then exposed as an MCP server via Lambda (deploy_oauth_proxy.py).

Prerequisites:
- AWS CLI configured with appropriate permissions
- boto3 installed: pip install boto3
- Region: us-east-1

Usage:
  python setup_knowledge_base.py
"""

import boto3
import json
import time
import os
from pathlib import Path

# Configuration
AWS_REGION = "us-east-1"
S3_BUCKET_NAME = "supply-chain-mfg-logistics-kb"
KB_NAME = "supply-chain-logistics-kb"
DOCS_DIR = Path(__file__).parent / "sample_documents"

# Initialize clients
s3 = boto3.client("s3", region_name=AWS_REGION)
bedrock_agent = boto3.client("bedrock-agent", region_name=AWS_REGION)
iam = boto3.client("iam", region_name=AWS_REGION)


def create_s3_bucket():
    """Create S3 bucket for knowledge base documents."""
    print(f"Creating S3 bucket: {S3_BUCKET_NAME}")
    try:
        s3.create_bucket(Bucket=S3_BUCKET_NAME)
        print(f"  ✓ Bucket created: {S3_BUCKET_NAME}")
    except s3.exceptions.BucketAlreadyOwnedByYou:
        print(f"  ✓ Bucket already exists: {S3_BUCKET_NAME}")
    except Exception as e:
        print(f"  ✗ Error: {e}")
        raise


def upload_documents():
    """Upload all sample documents to S3."""
    print("\nUploading documents to S3...")
    count = 0
    for root, dirs, files in os.walk(DOCS_DIR):
        for file in files:
            if file.endswith((".txt", ".md", ".json", ".csv")):
                local_path = Path(root) / file
                s3_key = f"documents/{local_path.relative_to(DOCS_DIR)}"
                s3.upload_file(str(local_path), S3_BUCKET_NAME, s3_key)
                count += 1
                print(f"  ✓ Uploaded: {s3_key}")
    print(f"  Total documents uploaded: {count}")


def create_kb_role():
    """Create IAM role for Bedrock Knowledge Base."""
    role_name = "BedrockKB-SupplyChain-Role"
    print(f"\nCreating IAM role: {role_name}")

    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"Service": "bedrock.amazonaws.com"},
                "Action": "sts:AssumeRole",
            }
        ],
    }

    try:
        response = iam.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=json.dumps(trust_policy),
            Description="Role for Bedrock KB to access S3 documents",
        )
        role_arn = response["Role"]["Arn"]
        print(f"  ✓ Role created: {role_arn}")
    except iam.exceptions.EntityAlreadyExistsException:
        role_arn = iam.get_role(RoleName=role_name)["Role"]["Arn"]
        print(f"  ✓ Role exists: {role_arn}")

    # Attach S3 read policy
    policy_doc = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["s3:GetObject", "s3:ListBucket"],
                "Resource": [
                    f"arn:aws:s3:::{S3_BUCKET_NAME}",
                    f"arn:aws:s3:::{S3_BUCKET_NAME}/*",
                ],
            },
            {
                "Effect": "Allow",
                "Action": [
                    "bedrock:InvokeModel",
                    "bedrock:InvokeModelWithResponseStream",
                ],
                "Resource": "arn:aws:bedrock:*::foundation-model/*",
            },
        ],
    }

    policy_name = "BedrockKB-S3-Access"
    try:
        iam.put_role_policy(
            RoleName=role_name,
            PolicyName=policy_name,
            PolicyDocument=json.dumps(policy_doc),
        )
        print(f"  ✓ Policy attached: {policy_name}")
    except Exception as e:
        print(f"  ! Policy attachment: {e}")

    # Wait for role propagation
    time.sleep(10)
    return role_arn


def create_knowledge_base(role_arn):
    """
    Create Bedrock Knowledge Base.
    
    Bedrock Managed KB is created via the AgentCore console/API and does NOT use
    the bedrock-agent CreateKnowledgeBase API. That older API requires a vector store.
    
    This function tries the AgentCore managed KB API first, then falls back to
    creating via AWS CLI command output for the user.
    """
    print(f"\nCreating Knowledge Base: {KB_NAME}")

    # Managed KB must be created via AWS Console (the boto3 bedrock-agent API
    # only supports customer-managed KBs with explicit vector stores)
    print("  Managed KB requires creation via AWS Console.\n")

    # If the AgentCore API is not available, provide console instructions
    print("  ╔══════════════════════════════════════════════════════════════╗")
    print("  ║  CREATE MANAGED KB VIA AWS CONSOLE                          ║")
    print("  ╠══════════════════════════════════════════════════════════════╣")
    print("  ║  1. Go to: Amazon Bedrock > AgentCore > Knowledge Bases     ║")
    print("  ║  2. Click 'Create Managed Knowledge Base'                   ║")
    print("  ║  3. Name: supply-chain-logistics-kb                         ║")
    print("  ║  4. Embedding: Managed (default)                            ║")
    print("  ║  5. Data source: Amazon S3                                  ║")
    print(f"  ║  6. S3 URI: s3://{S3_BUCKET_NAME}/documents/         ║")
    print("  ║  7. Chunking: Default                                       ║")
    print("  ║  8. Click 'Create Knowledge Base'                           ║")
    print("  ║  9. After creation, click 'Sync' to ingest documents        ║")
    print("  ╚══════════════════════════════════════════════════════════════╝")
    print()

    kb_id = input("  Enter the Knowledge Base ID after creating it (e.g., ABCDEFGHIJ): ").strip()
    if not kb_id:
        print("  No KB ID provided. Exiting.")
        raise SystemExit(1)
    
    print(f"  ✓ Using Knowledge Base ID: {kb_id}")
    return kb_id


def add_data_source_and_sync(kb_id):
    """
    For Managed KBs, data source is added via console during creation.
    This function prompts the user to confirm sync is complete.
    """
    print(f"\n  ╔══════════════════════════════════════════════════════════════╗")
    print(f"  ║  ADD DATA SOURCE & SYNC (via AWS Console)                   ║")
    print(f"  ╠══════════════════════════════════════════════════════════════╣")
    print(f"  ║  If you haven't already added the S3 data source:           ║")
    print(f"  ║  1. Go to KB '{kb_id}' in Bedrock console                   ║")
    print(f"  ║  2. Click 'Data sources' > 'Add data source'                ║")
    print(f"  ║  3. Type: Amazon S3                                         ║")
    print(f"  ║  4. S3 URI: s3://{S3_BUCKET_NAME}/documents/         ║")
    print(f"  ║  5. Click 'Add' then 'Sync'                                 ║")
    print(f"  ║  6. Wait for sync to complete (status: Available)            ║")
    print(f"  ╚══════════════════════════════════════════════════════════════╝")
    print()
    input("  Press Enter once the data source is synced and KB status is 'Available'...")


def main():
    print("=" * 60)
    print("AWS BEDROCK KNOWLEDGE BASE SETUP")
    print("=" * 60)

    # Step 1: S3 Bucket
    create_s3_bucket()

    # Step 2: Upload documents
    upload_documents()

    # Step 3: IAM Role for KB
    kb_role_arn = create_kb_role()

    # Step 4: Create Knowledge Base
    kb_id = create_knowledge_base(kb_role_arn)

    # Step 5: Add data source and sync (via console for Managed KB)
    add_data_source_and_sync(kb_id)

    print("\n" + "=" * 60)
    print("SETUP COMPLETE")
    print("=" * 60)
    print(f"\nKnowledge Base ID: {kb_id}")
    print(f"\nNext step:")
    print(f"  python deploy_oauth_proxy.py --kb-id {kb_id}")
    print(f"  (This creates the Lambda MCP server + API Gateway + Cognito)")


if __name__ == "__main__":
    main()
