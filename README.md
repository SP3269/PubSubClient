# PubSubClient
AWS Lambda function that subscribes to SNS topic and forwards messages to a Cloud Pub/Sub topic on Google Cloud platform (GCP)

## Prerequisites

### AWS

### GCP

### Local development environment

## Deployment

The Lambda function needs to be configured with the following parameters in the environment:
* `topic` - the Pub/Sub topic id, matching pattern `/^projects\/[^/]+\/topics\/[^/]+$/`;
* `sa` - the GCP service account configured to publish to the Pub/Sub topic; and
* `secretid` - the ARN of 

An easy way to manage the runtime parameters is creating a configuration file, `config.json`:

```json
{
    "sa": "messenger@apiaccess-294500.iam.gserviceaccount.com",
    "topic": "projects/apiaccess-294500/topics/messagebus",
    "secretid": "arn:aws:secretsmanager:us-west-2:823519568520:secret:P12Key-DyyfF0"
}
```

Then, deploy the Lambda:

```powershell
$config = Get-Content ./config.json | ConvertFrom-Json -AsHashtable
Publish-AWSPowerShellLambda -ScriptPath .\SNSProcessor.ps1 -Name SNSProcessor -Region us-west-2 -EnvironmentVariable $config
```

Lambda runtime will inject the configuration to the environment, and the PowerShell code will refer to the environment variables.

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


