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
        [ValidateSet("NTFS")]
        [string] $FileSystem,
        [parameter()]
        [string] $FileSystemLabel
  	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference = "Stop"
        $partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
        $volume = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
        if ($volume -ne $null)
        {
            Write-Verbose -Message "Partition with drive leter $DriveLetter found"
            $returnValue = @{
                DiskNumber = $partition.DiskNumber
                DriveLetter = $partition.DriveLetter
                FileSystem = $volume.FileSystem
                FileSystemLabel = $volume.FileSystemLabel
            }
        }
        else
        {
            Write-Verbose -Message "Volume not found"
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
        [ValidateSet("NTFS")]
        [string] $FileSystem,
        [parameter()]
        [string] $FileSystemLabel
  	)

    try
    {
        $ErrorActionPreference = "Stop"
        $partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
        $volume = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
        if(($partition.DiskNumber -eq $DiskNumber) -and ($partition.DriveLetter -eq $DriveLetter) -and ($volume.FileSystem -eq $FileSystem))
        {
            if($volume.FileSystemLabel -eq $FileSystemLabel)
            {
                Write-Verbose -Message "Volume configuration is correct. Do nothing."
            }
            else
            {
                Write-Verbose -Message "Setting label on volume ..."
                $volume | Set-Volume  -NewFileSystemLabel $FileSystemLabel -Confirm:$false
                Write-Verbose -Message "Label have been set on volume"
            }
        }
        elseif(($volume.FileSystem -eq "") -and ($partition.DiskNumber -eq $DiskNumber) -and ($partition.DriveLetter -eq $DriveLetter))
        {
            Write-Verbose -Message "Volume with drive letter $DriveLetter will be formatted."
            $partition | Format-Volume -FileSystem $FileSystem -NewFileSystemLabel $FileSystemLabel -Confirm:$false
            Write-Verbose -Message "Volume with drive letter $DriveLetter succesfuly formatted."
        }
        else
        {
            Write-Verbose -Message "Volume with drive letter $DriveLetter exists. We'll skip it."
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
        [ValidateSet("NTFS")]
        [string] $FileSystem,
        [parameter()]
        [string] $FileSystemLabel
  	)
    $retValue = $false
    $volume = Get-TargetResource -DiskNumber $DiskNumber -DriveLetter $DriveLetter -FileSystem $FileSystem -FileSystemLabel $FileSystemLabel
    if(($volume.keys -contains "DiskNumber") -and ($volume.Keys -contains "DriveLetter") -and ($volume.Keys -contains "FileSystem")-and ($volume.Keys -contains "FileSystemLabel"))
    {
        if($volume.FileSystem -eq "")
        {
            if(($volume.DiskNumber -eq $DiskNumber) -and ($volume.DriveLetter -eq $DriveLetter))
            {
                Write-Verbose -Message "Volume with drive letter $DriveLetter should be formated."
            }
            else
            {
                Write-Verbose -Message "Volume is not formatted, but is on the different disk. We'll skip it."
                $retValue=$true                
            }
        }
        else
        {
            Write-Verbose -Message "Volume with drive letter $DriveLetter have been already formated. We'll skip it."
            $retValue=$true
        }
    }
    else
    {
        Write-Verbose -Message "Can't find volume with drive letter $DriveLetter."
    }
    return $retValue
}


Export-ModuleMember -Function *-TargetResource