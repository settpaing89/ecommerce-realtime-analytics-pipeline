# Create AWS resources config file
#!/bin/bash

# Get values from Terraform outputs
export GLUE_DATABASE=$(cd terraform && terraform output -raw glue_database_name)
export ATHENA_WORKGROUP=$(cd terraform && terraform output -raw athena_workgroup)
export GOLD_BUCKET=$(cd terraform && terraform output -raw gold_bucket_name)

echo "AWS Resources configured:"
echo "  Database: $GLUE_DATABASE"
echo "  Workgroup: $ATHENA_WORKGROUP"
echo "  Gold Bucket: $GOLD_BUCKET"
