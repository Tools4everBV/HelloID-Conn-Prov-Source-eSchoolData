#2021-02-12

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

#Get Students
Write-Verbose -Verbose "Retrieving Students"
$page = 1;
$persons = $null;
do
{
    $parameters = @{
        pagesize = 1000;
        pageNo = $page;
        includeHomeroom = "true";
    }
    $uri = "$($config.baseurl)/v1/students"
    Write-Verbose -Verbose "Page $page";
    $response = Invoke-RestMethod $uri -Method GET -Headers $authorization -Body $parameters
    
    if ($persons -eq $null)
    {        
        $persons = $response.students;
    }
    else
    {
        $persons += $response.students;
    }

    $page = $response.pagingInfo.pageNo + 1;   

} while ($response.pagingInfo.pageNo -ne $response.pagingInfo.pageCount -or $response.pagingInfo.pageCount -eq 0)


#TODO Add contracts to persons

Write-Output ($persons | ConvertTo-Json -Depth 10);