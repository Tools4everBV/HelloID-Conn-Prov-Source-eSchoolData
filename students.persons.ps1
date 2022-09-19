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
$persons = @();
do
{
    $parameters = @{
        pagesize = 1000;
        pageNo = $page;
        includeHomeroom = "true";
    }
    $uri = "$($config.domain)/v1/students"
    Write-Verbose -Verbose "Page $page";
    $response = Invoke-RestMethod $uri -Method GET -Headers $authorization -Body $parameters
    
    $persons += $response.students;

    $page = $response.pagingInfo.pageNo + 1;   

} while ($response.pagingInfo.pageNo -ne $response.pagingInfo.pageCount -or $response.pagingInfo.pageCount -eq 0)

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
    $uri = "$($config.domain)/v1/schools"
    Write-Verbose -Verbose "Page $page";
    $response = Invoke-RestMethod $uri -Method GET -Headers $authorization -Body $parameters
    
    $schools += $response.schools;

    $page = $response.pagingInfo.pageNo + 1;   

} while ($response.pagingInfo.pageNo -ne $response.pagingInfo.pageCount -or $response.pagingInfo.pageCount -eq 0)

foreach ($person in $persons)
{
    $student = $person;
    $student | Add-Member -Name "ExternalId" -Value $person.userId -MemberType NoteProperty;
    $student | Add-Member -Name "DisplayName" -Value "$($person.firstName) $($person.lastName) ($($person.userId))" -MemberType NoteProperty;
    $student | Add-Member -Name "School" -Value ($schools | Where-Object { $_.id -eq $person.schoolId }) -MemberType NoteProperty;

    if ($null -eq $student.dateEnteredDistrict || $student.dateEnteredDistrict -eq "")
    {
        $student.dateEnteredDistrict = "0001-01-01T00:00:00"
    }

    if ($null -eq $student.projectGradDate || $student.projectGradDate -eq "")
    {
        $student.projectGradDate = "9999-12-31T23:59:999"
    }

    $contract = @(@{  
        'StartDate' = $student.dateEnteredDistrict;
        'EndDate' = $student.projectGradDate;
    });

    $student | Add-Member -Name "Contracts" -Value $contract -MemberType NoteProperty;
    Write-Output ($student | ConvertTo-Json -Depth 10);
}
