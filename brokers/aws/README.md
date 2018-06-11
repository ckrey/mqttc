
```
#!/bin/sh
#
# http://docs.aws.amazon.com/iot/latest/developerguide/verify-pub-sub.html
#
register a free AWS IoT acount

# https://docs.aws.amazon.com/cli/latest/userguide/aws-cli.pdf
pip install awscli
~/.local/bin/aws iot help

# use your `Access Key ID`, `AWS Secret Access Key`, and choose a region, e.g. `eu-central-1`
~/.local/bin/aws configure

~/.local/bin/aws iot create-thing --thing-name "mqttc"
# note `thingArn`, `thingName`, and `thingId` 

~/.local/bin/aws iot create-keys-and-certificate --set-as-active
# note `certificateId` and `certificateArn`

~/.local/bin/aws iot describe-certificate --certificate-id $certificateId --output text --query certificateDescription.certificatePem > cert.pem
# store the private and public key in files thing-private-key.pem and thing-public-key.pem

# https://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html
# use one of the examples https://docs.aws.amazon.com/AmazonS3/latest/dev/example-policies-s3.html#iam-policy-ex0
~/.local/bin/aws iot create-policy --policy-name "PubSubToAnyTopic" --policy-document file://policy

~/.local/bin/aws iot attach-principal-policy --principal $certificateArn --policy-name "PubSubToAnyTopic"

~/.local/bin/aws iot attach-thing-principal --thing-name $thingName --principal $certificateArn 

~/.local/bin/aws iot describe-endpoint
# note `endpointAddress`

curl https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem -o rootCA.pem

mosquitto_sub --cafile rootCA.pem --cert cert.pem --key thing-private-key.pem -h $endpointAddress -t '#' -v -d
mosquitto_pub --cafile rootCA.pem --cert cert.pem --key thing-private-key.pem -h $endpointAddress -p 8883 -q 1 -d -t topic/test -i clientid2 -m "Hello, World"
openssl pkcs12 -in cert.pem -inkey thing-private-key.pem -out aws.p12 -export

```
