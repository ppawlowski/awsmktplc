#!/usr/bin/env sh

set -e

if [ -z "$PRODUCT_ID" ]; then
  echo "Error: PRODUCT_ID environment variable is not set"
  exit 1
fi

REGION="us-east-1"

entity_details=$(aws marketplace-catalog describe-entity \
  --catalog "AWSMarketplace" \
  --entity-id "$PRODUCT_ID" \
  --region "$REGION" \
  --output json)

oldest_version_delivery_id=$(echo "$entity_details" | jq -r '[.DetailsDocument.Versions[] | 
    select(.DeliveryOptions[].Visibility == "Public") | 
    { creationDate: .CreationDate, id: .DeliveryOptions[] | select(.Visibility == "Public") | .Id }] | 
    min_by(.creationDate) | 
    .id')

change_set=$(cat <<EOF
{
  "ChangeSet": [
    {
      "ChangeType": "RestrictDeliveryOptions",
      "Entity": {
        "Identifier": "$PRODUCT_ID",
        "Type": "AmiProduct@1.0"
      },
      "DetailsDocument": {
        "DeliveryOptionIds": [
          "$oldest_version_delivery_id"
        ]  
      }
    }
  ]
}
EOF
)

echo "Oldest version delivery ID: $oldest_version_delivery_id"

aws marketplace-catalog start-change-set \
    --catalog "AWSMarketplace" \
    --cli-input-json "$change_set" \
    --query 'ChangeSetId' \
    --region "$REGION" \
    --output text
