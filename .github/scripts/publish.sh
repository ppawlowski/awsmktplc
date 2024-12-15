#!/usr/bin/env sh

set -e

# AMI ID from previous steps
# AMI_ID="ami-0420c4f1a6fb6722f"
if [ -z "$AMI_ID" ]; then
  echo "Error: AMI_ID environment variable is not set"
  exit 1
fi
if [ -z "$PRODUCT_ID" ]; then
  echo "Error: PRODUCT_ID environment variable is not set"
  exit 1
fi
if [ -z "$ROLE_ARN" ]; then
  echo "Error: ROLE_ARN environment variable is not set"
  exit 1
fi
if [ -z "$RELEASE" ]; then
  echo "Error: RELEASE environment variable is not set"
  exit 1
fi
REGION="us-east-1"

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
