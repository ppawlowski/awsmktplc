#!/usr/bin/env sh

set -e

# AMI ID from previous steps
AMI_ID="ami-0420c4f1a6fb6722f"
PRODUCT_ID="prod-j7n25c6yvugho"
REGION="us-east-1"
ROLE_ARN="arn:aws:iam::541396506541:role/AccessAmiFromMarketplace"

if [ -z "$1" ]; then
  echo "Error: Release version must be provided as first argument"
  exit 1
fi

RELEASE="$1"

change_set=$(cat <<EOF
{
  "ChangeSet": [
    {
      "ChangeType": "AddDeliveryOptions",
      "Entity": {
          "Type": "AmiProduct@1.0",
          "Identifier": "$PRODUCT_ID"
      },
      "DetailsDocument": {
        "Version": {
          "VersionTitle": "$RELEASE",
          "ReleaseNotes": "Relese notes available on github"
        },
        "DeliveryOptions": [
          {
            "Details": {
              "AmiDeliveryOptionDetails": {
                "AmiSource": {
                  "AmiId": "$AMI_ID",
                  "AccessRoleArn": "$ROLE_ARN",
                  "UserName": "ec2-user",
                  "OperatingSystemName": "AMAZONLINUX",
                  "OperatingSystemVersion": "Amazon Linux 2023 AMI 2023.6.20241121.0 x86_64 HVM kernel-6.1"
                },
                "UsageInstructions": "This AMI is for free use",
                "RecommendedInstanceType": "t3.small",
                "SecurityGroups": [
                  {
                    "IpProtocol": "tcp",
                    "FromPort": 22,
                    "ToPort": 22,
                    "IpRanges": ["0.0.0.0/0"]
                  }
                ]
              }
            }
          }
        ]  
      }
    }
  ]
}
EOF
)

aws marketplace-catalog start-change-set \
    --catalog "AWSMarketplace" \
    --intent "APPLY" \
    --cli-input-json "$change_set" \
    --query 'ChangeSetId' \
    --region "$REGION" \
    --output json



# Submit the change set
# change_set_id=$(aws marketplace-catalog start-change-set \
#     --cli-input-json "$change_set" \
#     --query 'ChangeSetId' \
#     --output text)

# # Wait for change set to complete
# aws marketplace-catalog wait change-set-complete \
#     --change-set-id "$change_set_id"

# # Describe the change set to confirm
# aws marketplace-catalog describe-change-set \
#     --change-set-id "$change_set_id"