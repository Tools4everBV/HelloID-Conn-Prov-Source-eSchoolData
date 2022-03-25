#Configuration
$config = ConvertFrom-Json $configuration;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

#Build access token request
$requestUri = "$($config.domain)/v1/auth/token";
    
$headers = @{
	'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $config.clientId,$config.secret)))
};
$body = "grant_type=client_credentials";

#Request access token
$response = Invoke-RestMethod -Method POST -Uri $requestUri -Headers $headers -Body $body -Verbose:$false;
$accessToken = $response.access_token;

#Add the authorization header to the request
$authorization = @{
    Authorization = "Bearer $accesstoken";
    'Content-Type' = "application/json";
    Accept = "application/json";
};

#Get Schools
Write-Verbose -Verbose "Retrieving Schools"
$page = 1;
$schools = @();
do
{
    $parameters = @{
        pagesize = 1000;
        pageNo = $page;
    }
    $uri = "$($config.baseurl)/v1/schools"
    Write-Verbose -Verbose "Page $page";
    $response = Invoke-RestMethod $uri -Method GET -Headers $authorization -Body $parameters
    
    $schools += $response.schools;

    $page = $response.pagingInfo.pageNo + 1;   

} while ($response.pagingInfo.pageNo -ne $response.pagingInfo.pageCount -or $response.pagingInfo.pageCount -eq 0)

$schools = $schools | Select-Object @{N='ExternalId'; E={$_.id}}, @{N='DisplayName'; E={$_.name}},*
Write-Output ($schools | ConvertTo-Json);