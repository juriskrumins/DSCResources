function Get-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory=$false)]
        [string]$OUPath
    )

    $result=@{}
    try
    {
        Write-Verbose -Message "Checking if computer object $ComputerName exists in AD domain ..."
        $ADComputer = Get-AdComputer -Identity $ComputerName -ErrorAction Stop
        Write-Verbose -Message "ComputerName $ComputerName found in AD domain"
        $Ensure = "Present"
        $result.Add('ComputerName',$ADComputer.Name)
        $result.Add('OUPath',$($ADComputer.DistinguishedName -replace "CN=$ComputerName,",""))
    }
    # Computer not found
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        Write-Verbose -Message "Computer's $ComputerName account not found."
        $Ensure = "Absent"
    }
    catch
    {
        Write-Error -Message "Unhandled exception looking up $ComputerName account in domain. $($_)"
    }

    return $result
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory=$false)]
        [string]$OUPath
    )
    try
    {
        $CurrentADobject=Get-TargetResource -ComputerName $ComputerName
        if($CurrentADobject.Count -eq 0)
        {
            Write-Verbose -Message "Going to create new AD Computer object $ComputerName"
            $params=@{}
            $params.Add('Name',$ComputerName)
            if($OUPath -ne '')
            {
                $params.Add('Path',$OUPath)
            }
            New-ADComputer @params -ErrorAction Stop
            Write-Verbose -Message "New AD Computer object $ComputerName has been created"
        }
        else
        {
            Write-Verbose -Message "Looks like AD Computer object $ComputerName already exists but some object attribute are not in desired state."
            Write-Verbose -Message "We'll do nothing. Please remove AD Computer object $ComputerName under $($CurrentADobject['OUPath']) manually."
        }
    }
    catch
    {
        Write-Error -Message "Error creating AD Computer object $ComputerName in domain. $_"
        throw $_
    }
}

function Test-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory=$false)]
        [string]$OUPath
    )

    $result=$true
    try
    {
        $CurrentADobject=Get-TargetResource -ComputerName $ComputerName
        if($ComputerName -eq $CurrentADobject['ComputerName'])
        {
            Write-Verbose -Message "AD object's name and desired object name are equal."
            if(($OUPath -ne '') -and ($OUPath -ne $CurrentADobject['OUPath']))
            {
                Write-Verbose -Message "OUPath have been specified but it's not equal to the path for the object found."
                $result=$false
            }
        }
        else
        {
            Write-Verbose -Message "AD object's name and desired object name are not equal."
            $result=$false
        }
    }
    catch
    {
        Write-Error -Message "Error testing AD Computer $ComputerName in domain. $_"
        throw $_
    }
    return $result
}

Export-ModuleMember -Function *-TargetResource