Param (
    [Parameter (Mandatory = $true)]
    [string]$appToken,
    [Parameter (Mandatory = $true)]
    [string]$appName,
    [int]$buildsLimit = 2,
    [switch]$queue,
	[switch]$showVerbose,
    [switch]$showReport
)

function Invoke-ApiRequest
{
    Param (
        [Parameter(Mandatory = $true)]
        [string]$request,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get','Post')]
        [string]$method,
        [object]$body
    )

    $uri = "https://api.appcenter.ms"
    $headers = @{"X-API-Token" = $appToken}

    Switch ($method) 
    {
        'Get' {Invoke-RestMethod "$uri$request" -Headers $headers -ContentType "application/json" -Method Get}
        
        'Post' {Invoke-RestMethod "$uri$request" -Headers $headers -ContentType "application/json" -Body $body -Method Post}
    }
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$branches = New-Object System.Collections.Queue
$builds = New-Object System.Collections.ArrayList
$refreshTimeout = 5

$ownerName = Invoke-ApiRequest -request "/v0.1/user" -method Get | select -ExpandProperty name

$request = Invoke-ApiRequest -request "/v0.1/apps/$ownerName/$appName/branches" -method Get

foreach ($item in $request) 
{
    if ($item.configured) 
    {
        $branches.Enqueue($item.branch)
    }
    else 
    {
        Write-Host "Branch [$($item.branch)] not configured."
    }
}

if ($queue) 
{
    While (($branches.Count -gt 0) -or ($builds.Count -gt 0)) 
    {
        if (($branches.Count -gt 0) -and ($builds.Count -lt $buildsLimit)) 
        {
            $currentBranch = $branches.Dequeue()
            
            $build = Invoke-ApiRequest -request "/v0.1/apps/$ownerName/$appName/branches/$($currentBranch.name)/builds" -body (@{"sourceVersion" = $currentBranch.commit.sha} | ConvertTo-Json) -method Post
           
            $builds.Add($build) > $null
            
            Write-Host "Build [$($build.sourceBranch)][$($build.id)] queued - $($build.sourceVersion)"
        }

        $tempBuilds = $builds.Clone()

        foreach ($build in $tempBuilds)
        {
            $response = Invoke-ApiRequest -request "/v0.1/apps/$ownerName/$appName/builds/$($build.id)" -method Get 
			
			if($showVerbose)
			{
				Write-Host "Build [$($response.sourceBranch)][$($response.id)] $($response.status)"
			}
			
            if ($response.result) 
            {
                $builds.Remove($build)
            }
        }

        Start-Sleep $refreshTimeout
    }
}

if ($showReport) 
{
    if ($queue) 
    {
        $request = Invoke-ApiRequest -request "/v0.1/apps/$ownerName/$appName/branches" -method Get
    }

    Format-Table -InputObject $request.lastBuild -Wrap -Property sourceBranch, 
            result, 
            @{name='duration'; expression={New-TimeSpan -Start $_.startTime -End $_.finishTime;}}, 
            @{name='logs'; expression={"https://appcenter.ms/users/$ownerName/apps/$appName/build/branches/$($_.sourceBranch)/builds/$($_.id)"}}
}