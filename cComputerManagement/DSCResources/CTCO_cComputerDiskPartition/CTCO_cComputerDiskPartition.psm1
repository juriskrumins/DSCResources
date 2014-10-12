function Get-TargetResource
{
    [OutputType([Hashtable])]
	param
	(	
        [parameter(Mandatory=$true)]
        [int] $DiskNumber,
        [parameter(Mandatory=$true)]
        [string] $DriveLetter,
        [parameter()]
        [Uint64]$Size=0
  	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference = "Stop"
        $partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
        if ($partition -ne $null)
        {
            Write-Verbose -Message "Partition with drive leter $DriveLetter found"
            $returnValue = @{
                DiskNumber = $partition.DiskNumber
                DriveLetter = $partition.DriveLetter
                Size = $partition.Size
            }
        }
        else
        {
            Write-Verbose -Message "Partition not found"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
    }
	$returnValue
}


function Set-TargetResource
{
	param
	(	
        [parameter(Mandatory=$true)]
        [int] $DiskNumber,
        [parameter(Mandatory=$true)]
        [string] $DriveLetter,
        [parameter()]
        [Uint64]$Size=0
  	)

    try
    {
        $ErrorActionPreference = "Stop"
        $disk = Get-Disk -Number $DiskNumber | Where-Object {-not $_.IsClustered}
        if($disk -ne $null)
        {
            Write-Verbose -Message "Found disk $disk"
            Write-Verbose -Message "Setting up partition on drive $DriveNumber with drive letter $DriveLetter ..."
            $parameters=@{DriveLetter="$DriveLetter"}
            if($Size -eq 0)
            {
                $parameters+=@{UseMaximumSize=$null}
            }
            else
            {
                $parameters+=@{Size="$Size"}
            }
            $disk | New-Partition @parameters
            Write-Verbose -Message "Partition on drive $DriveNumber with drive letter $DriveLetter created."
        }
        else
        {
            Write-Verbose -Message "Disk with number $DiskNumber not found"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
    }

}


function Test-TargetResource
{
    [OutputType([Boolean])]
	param
	(	
        [parameter(Mandatory=$true)]
        [int] $DiskNumber,
        [parameter(Mandatory=$true)]
        [string] $DriveLetter,
        [parameter()]
        [Uint64]$Size=0
  	)
    $retValue = $false
    $partition = Get-TargetResource -DiskNumber $DiskNumber -DriveLetter $DriveLetter -Size $Size
    if(($partition.keys -contains "DiskNumber") -and ($partition.Keys -contains "DriveLetter") -and ($partition.Keys -contains "Size") )
    {
        if (($partition.DiskNumber -eq $DiskNumber) -and ($partition.DriveLetter -eq $DriveLetter))
        {
            Write-Verbose -Message "Partition have been already created on proper disk."
            $retValue = $true
        }
        elseif (($partition.DiskNumber -ne $DiskNumber) -and ($partition.DriveLetter -eq $DriveLetter))
        {
            Write-Verbose -Message "Partition with drive letter $DriveLetter have been already created on different disk. Gonna do nothing about it."
            $retValue = $true
        }
        else
        {
            Write-Verbose -Message "Current partition drive letter not equal to  $DriveLetter. This is strange."
        }
    }
    else
    {
        Write-Verbose -Message "Can't find partition with drive letter $DriveLetter."
    }
    return $retValue
}


Export-ModuleMember -Function *-TargetResource