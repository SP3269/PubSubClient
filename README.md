# PubSubClient
AWS Lambda function to push messages to a Pub/Sub topic in GCP

## Development notes
- GCP: created PubSub topic and service account with PubSub Publisher permissions; generated _P12_ credentials of the service account;
- Stored the P12 (Base64-encoded) in AWS Secrets Manager as text, key name `P12Key` (used in the code);
- AWS: created IAM user `robot` in a group `roboter`; granted Secrets Manager permission; generated access key and secret for the user;
- AWS Tools for PowerShell installation - had to use `Set-AWSCredential -AccessKey AK... -Secret Pr... -StoreAs default`, as `Initialize-AWSDefaultConfiguration` didn't update the profile (verify with `Get-AWSCredential -ListProfileDetail`)
- Installed the `AWSLambdaPSCore` module and generated the Lambda from template: `New-AWSPowerShellLambda -ScriptName SNSProcessor -Template SNSSubscription`
- Deployment using `Publish-AWSPowerShellLambda -ScriptPath .\SNSProcessor.ps1 -Name SNSProcessor -Region us-west-2`, adding IAM role `SNSProcessing` and attaching (initially) the `AWSLambdaBasicExecutionRole` IAM Policy
- Add IAM policy for Secrets Mamager
- Test with `aws lambda invoke --function-name SNSProcessor out`
- [Adding files to Lambda ZIP package](https://stackoverflow.com/questions/61932451/powershell-how-to-package-custom-modules-into-a-zip-package-for-aws-lamdba)
- Configuration into the environment: `$config = gc ./config.json | ConvertFrom-Json -AsHashtable`
- Deployment with the environment

$config = gc ./config.json | ConvertFrom-Json -AsHashtable
Publish-AWSPowerShellLambda -ScriptPath .\SNSProcessor.ps1 -Name SNSProcessor -Region us-west-2 -EnvironmentVariable $config 
