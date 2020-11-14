# SNS-to-PubSub
An AWS Lambda function that subscribes to SNS topic and forwards messages to a Cloud Pub/Sub topic on Google Cloud platform (GCP), written in PowerShell.

## Environments configuration

### GCP

* In a GCP project, [create a Pub/Sub topic](https://cloud.google.com/pubsub/docs/admin) to receive messages forwarded from AWS. Note the full topic name - you can use `gcloud pubsub topics list` to verify. That name will be used as the `topic` in the Lambda environment configuration;
* [Create a Google service account](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) and note the service account email - it will be used as the `sa` parameter in the Lambda environment configuration;
* Generate the service account key. A P12 key is required. A JSON key [can be converted to P12 key](https://gist.github.com/SP3269/a766709e7aeadc92a953dd253bb53b6a); and
* In the GCP project IAM, assign `Pub/Sub Publisher` role to the service account.

### AWS

* Create a Secrets Manager secret containing the P12 key of the Google service account. If using AWS Console - Store a new secret, select Other type of secrets (e.g. API key); choose a key name (which will be used as `secretkey` in the Lambda configurarion) and store base64-encoded P12 key as the value. Note the secret's ARN - it will be used as the `secretid` in the Lambda configuration;
* Pick an SNS topic for the Lambda to subscribe to. The Lambda will be deployed in the same AWS account with the SNS topic;
* Now that all of the Lambda environment configuration parameters are defined, deploy the Lambda function per Deployment section below;
* [Subscribe the Lambda to the SNS topic](https://aws.amazon.com/premiumsupport/knowledge-center/lambda-subscribe-sns-topic-same-account/); and
* Configure IAM to allow the Lambda access to the Secrets Manager secret. A lazy way is attaching the AWS-managed [SecretManagerreadWrite] policy to the execution role created for the Lambda in IAM.

### Local development environment

Install [PowerShell](https://github.com/powershell/powershell) and [AWS Tools for PowerShell](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up.html). Use `Initialize-AWSDefaultConfiguration` to initialise the AWS configuration. One can verify the default configuration with `Get-AWSCredential -ListProfileDetail` and update it using `Set-AWSCredential` cmdlet with `-StoreAs default` parameter.

Install the prerequisite PowerShell modules - Lambda service functions, and AWS tools and JWT, to be packaged with the Lambda:

```powershell
Install-Module AWS.Tools.Common,AWS.Tools.SecretsManager,AWSLambdaPSCore,JWT -Verbose
```
The `main.ps` script included with this repo contains largely the same code as the Lambda function, can be used to test components of the environments.

The code was developed on UNIX variants with PowerShell 7.

## Deployment

The Lambda function needs to be configured with the following parameters in the environment:
* `topic` - the Pub/Sub topic name, matching pattern `/^projects\/[^/]+\/topics\/[^/]+$/`;
* `sa` - the GCP service account configured to publish to the Pub/Sub topic;
* `secretid` - the ARN of the secret in AWS Secrets Manager where the service account key is stored; and
* `secretkey` - name of the key of the secret which value contains the base64-encoded P12 GCP service account key.

Change to the `SNSProcessor` directory and edit the configuration file, `config.json`:

```json
{
    "sa": "messenger@apiaccess-294500.iam.gserviceaccount.com",
    "topic": "projects/apiaccess-294500/topics/messagebus",
    "secretid": "arn:aws:secretsmanager:us-west-2:823519568520:secret:P12Key-DyyfF0",
    "secretkey": "P12Key"
}
```

Then, deploy the Lambda:

```powershell
$config = Get-Content ./config.json | ConvertFrom-Json -AsHashtable
Publish-AWSPowerShellLambda -ScriptPath .\SNSProcessor.ps1 -Name SNSProcessor -Region us-west-2 -EnvironmentVariable $config
```

Lambda runtime will inject the configuration to the environment, and the PowerShell code will refer to the environment variables.

Test by sending a message to the SNS topic - the CLoudWatch logs will contain the processing details, including the message IDs of the messages in Pub/Sub.
