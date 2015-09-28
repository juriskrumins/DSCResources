function Get-TargetResource
{
    [OutputType([Hashtable])]
	param
	(
        [parameter(Mandatory)]
        [string]$File,
        [parameter(Mandatory)]
        [string]$ServiceName
  	)

    $returnValue = @{}
    try
    {
        Write-Verbose -Message "Checking for existance of file and service"
        $ErrorActionPreference = "Stop"
        $FileName = (Get-Item -Path "$File" -ErrorAction SilentlyContinue ).FullName
        $Service = (Get-Service -Name "$ServiceName" -ErrorAction SilentlyContinue).Name
        $returnValue.File=$FileName
        $returnValue.ServiceName=$Service

    }
    catch 
    {
        Write-Verbose -Message "Error occured: $($_.Exception.Message)"
    }
	$returnValue
}


function Set-TargetResource
{
	param
	(
        [parameter(Mandatory)]
        [string]$File,
        [parameter(Mandatory)]
        [string]$ServiceName
  	)

    try 
    {
        $ErrorActionPreference="Stop"
        $restartService=$false
        $Resource=Get-TargetResource -File $File -ServiceName $ServiceName
        if($Resource.ServiceName -eq $null)
        {
            Write-Verbose -Message "Service with the name $ServiceName have not been found. We'll skip any further actions"
        }
        if($Resource.File -eq $null)
        {
            Write-Verbose -Message "File with the name $File have not been found. We'll skip any further actions"
        }
        if($Resource.File -ne $null -and  $Resource.ServiceName -ne $null)
        {
            Write-Verbose -Message "File $File and service $ServiceName have been found. Going to check hash values."
            if(Get-Item -Path "$($File).hash" -ErrorAction SilentlyContinue)
            {
                Write-Verbose -Message "Hash file $($File).hash found"
                $actualhash=Get-FileHash -Path "$File"
                $requiredhash=Get-Content -Path "$($File).hash"
                if($actualhash.hash -eq $requiredhash)
                {
                    Write-Verbose -Message "Actual and required file hashes are equal. No need to restart service $($ServiceName)."
                }
                else
                {
                    Write-Verbose -Message "Actual and required file hashes are not equal. Going to update $($File).hash file and restart service  $($ServiceName)."
                    (Get-FileHash -Path "$File").Hash | Out-File -FilePath "$File.hash" -Force
                    $restartService=$true
                }
            }
            else
            {
                Write-Verbose -Message "Hash file $($File).hash not found. We're going to generate $($File).hash file. Service $($ServiceName) will be restarted only one time."
                (Get-FileHash -Path "$File").Hash | Out-File -FilePath "$File.hash" -Force
                $restartService=$true
            }
        }

        if($restartService)
        {
            Write-Verbose -Message "Restarting service $($Servicename)."
            Restart-Service -Name $ServiceName
        }

    }
    catch
    {
        Write-Verbose -Message "Error occured: $($_.Exception.Message)"
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
	param
	(
        [parameter(Mandatory)]
        [string]$File,
        [parameter(Mandatory)]
        [string]$ServiceName
  	)

    $retValue = $false
    try 
    {
        $ErrorActionPreference="Stop"
        $Resource=Get-TargetResource -File $File -ServiceName $ServiceName
        if($Resource.ServiceName -eq $null)
        {
            Write-Verbose -Message "Service with the name $ServiceName have not been found. We'll ignore any further actions"
        }
        if($Resource.File -eq $null)
        {
            Write-Verbose -Message "File with the name $File have not been found. We'll ignore any further actions"
        }
        if($Resource.File -ne $null -and  $Resource.ServiceName -ne $null)
        {
            Write-Verbose -Message "File $File and service $ServiceName have been found. Going to check hash values."
            if(Get-Item -Path "$($File).hash" -ErrorAction SilentlyContinue)
            {
                Write-Verbose -Message "Hash file $($File).hash found"
                $actualhash=Get-FileHash -Path "$File"
                $requiredhash=Get-Content -Path "$($File).hash"
                if($actualhash.hash -eq $requiredhash)
                {
                    Write-Verbose -Message "Actual and required file hashes are equal. No need to restart service $ServiceName."
                    $retValue = $true
                }
                else
                {
                    Write-Verbose -Message "Actual and required file hashes are not equal. Need to update $($File).hash file and restart service  $($ServiceName)."
                }
            }
            else
            {
                Write-Verbose -Message "Hash file $($File).hash not found. We'll generate $($File).hash file and restart service $($ServiceName) one time."
            }
        }

    }
    catch
    {
        Write-Verbose -Message "Error occured: $($_.Exception.Message)"
    }
    return $retValue
}

Export-ModuleMember -Function *-TargetResource