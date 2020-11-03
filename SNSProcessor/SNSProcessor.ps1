# PowerShell script file to be executed as a AWS Lambda function.
#
# When executing in Lambda the following variables will be predefined.
#   $LambdaInput - A PSObject that contains the Lambda function input data.
#   $LambdaContext - An Amazon.Lambda.Core.ILambdaContext object that contains information about the currently running Lambda environment.
#
# The last item in the PowerShell pipeline will be returned as the result of the Lambda function.
#
# To include PowerShell modules with your Lambda function, like the AWS.Tools.S3 module, add a "#Requires" statement
# indicating the module and version. If using an AWS.Tools.* module the AWS.Tools.Common module is also required.

#Requires -Modules @{ModuleName='AWS.Tools.Common';ModuleVersion='4.1.2.0'}
#Requires -Modules @{ModuleName='AWS.Tools.SecretsManager';ModuleVersion='4.1.2.0'}
#Requires -Modules @{ModuleName='JWT';ModuleVersion='1.9.0'}

# Setting up the environment
$config = Get-Content ./config.json | ConvertFrom-Json
$sa = $config.sa
$topic = $config.topic
$secretid = $config.secretid

# Retreiving the service account P12 credentials from AWS Secrets Manager
# Assuming Base64-encoded value of `P12Key`
try {
    $secret = Get-SECSecretValue -SecretId $secretid -Verbose -ErrorAction Stop
    $b64 = ($secret.SecretString | ConvertFrom-Json).P12Key
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2([Convert]::FromBase64String($b64), "notasecret")
}
catch {
    throw "Couldn't process the secret"
}

# Uncomment to send the input event to CloudWatch Logs
Write-Host (ConvertTo-Json -InputObject $LambdaInput -Compress -Depth 5)

# Authentication to Google Cloud Platform

$scope = "https://www.googleapis.com/auth/pubsub" # Authorization scope 

$now = (Get-Date).ToUniversalTime()
$createDate = [Math]::Floor([decimal](Get-Date($now) -UFormat "%s"))
$expiryDate = [Math]::Floor([decimal](Get-Date($now.AddHours(1)) -UFormat "%s"))

$rawclaims = [Ordered]@{
    iss = $sa
    scope = $scope # Requested permissions
    aud = "https://www.googleapis.com/oauth2/v4/token"
    iat = $createDate
    exp = $expiryDate
} | ConvertTo-Json

# Encoding the JWT claim set

$jwt = New-Jwt -PayloadJson $rawclaims -Cert $cert -Verbose

# Making the access token request

$tokenendpoint = "https://www.googleapis.com/oauth2/v4/token"

$splat = @{
    Method = "POST"
    Uri = $tokenendpoint
    ContentType = "application/x-www-form-urlencoded"
    Body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$jwt"
}

$res = Invoke-RestMethod @splat -Verbose

$accesstoken = $res.access_token

# An SNS Subscription can receive multiple SNS records in a single execution.
foreach ($record in $LambdaInput.Records) {
    $subject = $record.Sns.Subject
    $message = $record.Sns.Message

    # Calling Pub/Sub API https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.topics/publish
    $apiuri = "https://pubsub.googleapis.com/v1/${topic}:publish"

    $req = @{
        messages = @(
            @{
                data = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($message))
            }
        )
    } | ConvertTo-Json

    $splat = @{
        Method = "POST"
        Uri = $apiuri
        Headers = @{authorization = "Bearer $accesstoken"}
        ContentType = "application/json"
        Body = $req
    }

    $publishres = Invoke-RestMethod @splat -Verbose
    Write-Host "Published $($publishres.messageIds) to $topic"

}
