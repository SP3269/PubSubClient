# PubSubClient
AWS Lambda function to push messages to a Pub/Sub topic in GCP

## Development notes
- GCP: created PubSub topic and service account with PubSub Publisher permissions; generated _P12_ credentials of the service account;
- Stored the P12 (Base64-encoded) in AWS Secrets Manager as text, key name `P12Key` (used in the code);
- AWS: created IAM user `robot` in a group `roboter`; granted Secrets Manager permission; generated access key and secret for the user;
- AWS Tools for PowerShell installation - had to use `Set-AWSCredential -AccessKey AK... -Secret Pr... -StoreAs default`, as `Initialize-AWSDefaultConfiguration` didn't update the profile (verify with `Get-AWSCredential -ListProfileDetail`)
- Installed the `AWSLambdaPSCore` module and generated the Lambda from template: `New-AWSPowerShellLambda -ScriptName SNSProcessor -Template SNSSubscription`
