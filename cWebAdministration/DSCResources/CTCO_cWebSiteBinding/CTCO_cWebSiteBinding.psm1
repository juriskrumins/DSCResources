function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.UInt32]
		$Port,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress,

		[parameter(Mandatory = $true)]
		[ValidateSet("http","https")]
		[System.String]
		$Protocol,

		[System.String]
		$CertificateSubjectName="",

		[System.String]
		$CertificateStoreName="",

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure="Present",

		[System.String]
		$HostHeader=""
	)

    $returnValue = @{}
    try
    {
        Write-Verbose -Message "Protocol is $Protocol"
        if($Protocol -eq "https")
        {
            if($CertificateSubjectName -ne "" -and $CertificateStoreName -ne "")
            {
                $CertificateHash = Get-CertificateThumbprintFromSubjectName -CertificateSubjectName $CertificateSubjectName -CertificateStoreName $CertificateStoreName -ErrorAction Stop
            }
            else
            {
                Write-Verbose -Message "CertificateSubjectName and CertificateStoreName options are not specified."
            }
        }
        if($Protocol -eq "http")
        {
            $CertificateHash = ""
            $CertificateStoreName = ""
            $CertificateSubjectName = ""
        }
        Write-Verbose -Message "CertificateHash: $CertificateHash"
        Write-Verbose -Message "CertificateStoreName: $CertificateStoreName"
        $WebSiteBindings=(Get-Website -Name $Name -ErrorAction Stop).Bindings.Collection
        foreach ($WebSiteBinding in $WebSiteBindings)
        {
            Write-Verbose -Message "Processing $($WebSiteBinding.bindingInformation) binding"
            if( $WebSiteBinding.protocol -eq $Protocol -and `
                $WebSiteBinding.bindingInformation -eq "$($IPAddress):$($Port):$($HostHeader)" -and `
                $WebSiteBinding.CertificateHash -eq $CertificateHash -and `
                $WebSiteBinding.CertificateStoreName -eq $CertificateStoreName)
            {
                Write-Verbose -Message "$($IPAddress):$($Port):$($HostHeader) binding found"
	            $returnValue = @{
		            Name = $Name
		            Port = $Port
		            IPAddress = $IPAddress
		            Protocol = $Protocol
		            CertificateSubjectName = $CertificateSubjectName
		            CertificateStoreName = $CertificateStoreName
		            Ensure = $Ensure
		            HostHeader = $HostHeader
	            }
                break
            }
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)."
    }

	return $returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.UInt32]
		$Port,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress,

		[parameter(Mandatory = $true)]
		[ValidateSet("http","https")]
		[System.String]
		$Protocol,

		[System.String]
		$CertificateSubjectName="",

		[System.String]
		$CertificateStoreName="",

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure="Present",

		[System.String]
		$HostHeader=""
	)

    try
    {
        $CurrentWebBinding = Get-TargetResource -Name $Name -Port $Port -IPAddress $IPAddress -Protocol $Protocol -HostHeader $HostHeader -Verbose -CertificateSubjectName $CertificateSubjectName -CertificateStoreName $CertificateStoreName -Ensure $Ensure -ErrorAction Stop
        switch ($Ensure)
        {
            "Present" 
            {
                if($CurrentWebBinding.Count -eq 0 )
                {
                    $params=@{
                        Name = $Name
                        Protocol = $Protocol
                        Port = $Port
                        IPAddress = $IPAddress
                        ErrorAction = "Stop"
                    }
                    if($HostHeader -ne "")
                    {
                        $params.Add("HostHeader",$HostHeader)
                    }
                    if($Protocol -eq "https")
                    {
                        if($CertificateSubjectName -ne "" -and $CertificateStoreName -ne "" -and $HostHeader -ne "")
                        {
                            $CertificateHash = Get-CertificateThumbprintFromSubjectName -CertificateSubjectName $CertificateSubjectName -CertificateStoreName $CertificateStoreName -ErrorAction Stop
                            if($CertificateHash -ne $null)
                            {
                                Write-Verbose -Message "Adding https binding ..."
                                New-WebBinding @params
                                $NewWebbinding = Get-WebBinding @params
                                $NewWebbinding.AddSslCertificate($CertificateHash, $CertificateStoreName)
                                Write-Verbose -Message "Done."
                            }
                            else
                            {
                                Write-Verbose -Message "CertificateHash are not set properly"
                            }
                        }
                        else
                        {
                            Write-Verbose -Message "CertificateSubjectName, CertificateStoreName and/or HostHeader  options are not specified."
                        }
                    }
                    if($Protocol -eq "http")
                    {
                        Write-Verbose -Message "Adding http binding ..."
                        New-WebBinding @params
                        Write-Verbose -Message "Done."
                    }
                }
            }
            "Absent"
            {
                if($CurrentWebBinding.Count -ne 0 )
                {
                    $params=@{
                        Name = "$Name"
                        Protocol = "$Protocol"
                        ErrorAction = "Stop"
                    }
                    if($HostHeader -ne "")
                    {
                        $params.Add("BindingInformation","$($IPAddress):$($Port):$HostHeader")
                    }
                    else
                    {
                        $params.Add("BindingInformation","$($IPAddress):$($Port):")
                    }
                    Write-Verbose -Message "Removing binding ..."
                    Remove-WebBinding @params
                    Write-Verbose -Message "Done."
                }
            }
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)"
    }

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.UInt32]
		$Port,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress,

		[parameter(Mandatory = $true)]
		[ValidateSet("http","https")]
		[System.String]
		$Protocol,

		[System.String]
		$CertificateSubjectName="",

		[System.String]
		$CertificateStoreName="",

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure="Present",

		[System.String]
		$HostHeader=""
	)

	$result = $false
    try {
        $CurrentWebBinding = Get-TargetResource -Name $Name -Port $Port -IPAddress $IPAddress -Protocol $Protocol -HostHeader $HostHeader -Verbose -CertificateSubjectName $CertificateSubjectName -CertificateStoreName $CertificateStoreName -Ensure $Ensure -ErrorAction Stop
        if(($CurrentWebBinding.Count -ne 0 -and $Ensure -eq "Present") -or ($CurrentWebBinding.Count -eq 0 -and $Ensure -eq "Absent"))
        {
            $result = $true
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)."
    }
	
    return $result
}



# Get certificate Thumbprint from certificat SubjectName
function Get-CertificateThumbprintFromSubjectName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    Param
    (
        $CertificateSubjectName,
        $CertificateStoreName
    )
    $returnValue=""
    try
    {
        if($CertificateSubjectName -ne $null)
        {
            $returnValue=(Get-ChildItem -Path "Cert:\LocalMachine\$CertificateStoreName" | Where-Object {$_.Subject -eq "$CertificateSubjectName"} | Sort-Object -Property NotAfter |Select-Object -Last 1).Thumbprint
        }
        else
        {
            $returnValue=$null
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($_)"
    }
    return $returnValue
}

Export-ModuleMember -Function *-TargetResource

