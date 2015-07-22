$Name=New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description "Web site name"
$Port=New-xDscResourceProperty -Name Port -Type Uint32 -Attribute Key -Description "Web site binding port"
$IPAddress=New-xDscResourceProperty -Name IPAddress -Type String -Attribute Key -Description "Web site binding address"
$Protocol=New-xDscResourceProperty -Name Protocol -Type String -Attribute Key -Description "Web site binding protocol" -ValueMap @("http","https") -Values @("http","https")
$HostHeader=New-xDscResourceProperty -Name HostHeader -Type String -Attribute Write -Description "Web site binding host header"
$CertificateSubjectName=New-xDscResourceProperty -Name CertificateSubjectName -Type String -Attribute Write -Description "Web site binding certificate subject name"
$CertificateStoreName=New-xDscResourceProperty -Name CertificateStoreName -Type String -Attribute Write -Description "Web site binding certificate store name"
$Ensure=New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -Description "Web site binding exists or not" -ValueMap @("Absent","Present") -Values @("Absent","Present")

New-xDscResource -Name CTCO_cWebSiteBinding -FriendlyName cWebSiteBinding -ModuleName cWebAdministration -Path "C:\Users\Administrator\Desktop\eco2gadv2_wmf50_win2012R2\Modules" -Property @($Name,$Port,$IPAddress,$Protocol,$CertificateSubjectName,$CertificateStoreName,$Ensure,$HostHeader)