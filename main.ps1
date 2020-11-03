# Dependencies section
Import-module JWT

# Configuration section
$sa = "messenger@apiaccess-294500.iam.gserviceaccount.com" # Your service account
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("./apiaccess-294500-9cfa51b07fae.p12", "notasecret")
$scope = "https://www.googleapis.com/auth/pubsub" #Authorization scope 
$topic = "projects/apiaccess-294500/topics/messagebus" # The Pub/Sub topic id
$data = "Test Data" # Data to publish into the topic

# Authentication

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

$req = @{
    messages = @(
        @{
            data = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($data))
        }
    )
} | ConvertTo-Json

$req = '{"messages":[{"data":"VGVzdCBEYXRh"}]}'

$splat = @{
    Method = "POST"
    Uri = $apiuri
    Headers = @{authorization = "Bearer $accesstoken"}
    ContentType = "application/json"
    Body = $req
}

$publishres = Invoke-RestMethod @splat -Verbose
