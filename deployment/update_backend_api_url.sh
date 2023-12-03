#!/bin/bash

# Get the backend load-balancer url
bkend_lblncr_url=$(kubectl get svc | awk '/roseflix-backend-service/ { print $4 }')
# Adjust backend load-balancer url to match dualstack format
custom_bkend_lblncr_url="dualstack.${bkend_lblncr_url}."

# Get the frontend load-balancer url
frend_lblncr_url=$(kubectl get svc | awk '/roseflix-frontend-service/ { print $4 }')
# Adjust frontend load-balancer url to match dualstack format
custom_frend_lblncr_url="dualstack.${frend_lblncr_url}."

# hosted zone ID of meister.lol
meister_lol_hosted_zone_id="Z0348476221EWBX8SN5OZ"

# Route 53 Hosted Zone ID (Application Load Balancers, Classic Load Balancers) in us-east-1
# source: https://docs.aws.amazon.com/general/latest/gr/elb.html
elb_hosted_zone_id="Z35SXDOTRQ7X7K"


# Check if backend load-balancer url is empty, if not, update the dns record
if [ -z "$bkend_lblncr_url" ]; then
    echo "backend load-balancer url wasn't found."
else
    echo -e "The backend api of 'dp1001backend.meister.lol' will direct to:\n'$custom_bkend_lblncr_url'\n"
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$meister_lol_hosted_zone_id" \
        --change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "dp1001backend.meister.lol",
                    "Type": "A",
                    "AliasTarget": {
                        "HostedZoneId": "'"$elb_hosted_zone_id"'",
                        "DNSName": "'"${custom_bkend_lblncr_url}"'",
                        "EvaluateTargetHealth": false
                    }
                }
            }
        ]
    }'

fi

# Check if frontend load-balancer url is empty, if not, update the dns record
if [ -z "$frend_lblncr_url" ]; then
    echo "frontend load-balancer url wasn't found."
else
    echo -e "The frontend url of 'roseflix.meister.lol' will direct to:\n'$custom_frend_lblncr_url'\n"
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$meister_lol_hosted_zone_id" \
        --change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "roseflix.meister.lol",
                    "Type": "A",
                    "AliasTarget": {
                        "HostedZoneId": "'"$elb_hosted_zone_id"'",
                        "DNSName": "'"${custom_frend_lblncr_url}"'",
                        "EvaluateTargetHealth": false
                    }
                }
            }
        ]
    }'

fi
