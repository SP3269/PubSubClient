# Dependencies section
Import-module JWT
Import-Module AWSPowerShell.NetCore

# Configuration section
$sa = "messenger@apiaccess-294500.iam.gserviceaccount.com" # Your service account
$topic = "projects/apiaccess-294500/topics/messagebus" # The Pub/Sub topic id
$secretid = "arn:aws:secretsmanager:us-west-2:823519568520:secret:P12Key-DyyfF0"
$secretname = "P12Key"

# $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("./apiaccess-294500-9cfa51b07fae.p12", "notasecret")
# Using AWS Secrets Manager for key storage instead
$secret = Get-SECSecretValue -SecretId $secretid -Verbose
$b64 = ($secret.SecretString | ConvertFrom-Json).$secretname
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2([Convert]::FromBase64String($b64), "notasecret")

# Authentication

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

# Calling Pub/Sub API https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.topics/publish

$apiuri = "https://pubsub.googleapis.com/v1/${topic}:publish"

$subject = "Test subject"
$data = "Test Data $(Get-Date)" # Data to publish into the topic

$req = @{
    messages = @(
        @{
            data = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($data))
            attributes = @{
                    subject = $subject
            }
        }
    )
} | ConvertTo-Json -Depth 3

$splat = @{
    Method = "POST"
    Uri = $apiuri
    Headers = @{authorization = "Bearer $accesstoken"}
    ContentType = "application/json"
    Body = $req
}

$publishres = Invoke-RestMethod @splat -Verbose
$publishres # Outputs the result of publishing to the Pub/Sub topic
