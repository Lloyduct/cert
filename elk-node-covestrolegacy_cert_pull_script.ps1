$tmp=(get-wmiobject -Query 'Select * from win32_service where Name like "Metricbeat"') | Select @{Name="Path"; Expression={$_.PathName.split('"')[3]}}

if($tmp.Path) {
	$ca=(Select-String -Path $tmp.Path -Pattern 'ssl.certificate_authorities:').ToString()|%{$_.split('"')[1]}
    $cert=(Select-String -Path $tmp.Path -Pattern 'ssl.certificate:').ToString()|%{$_.split('"')[1]}
    $certKey=(Select-String -Path $tmp.Path -Pattern 'ssl.key:').ToString()|%{$_.split('"')[1]}
    
} else {
    throw "Metricbeat service not found, unable to determine certificates path, please ensure all the beat agents are installed."
}

Rename-Item -Path $ca -NewName (($ca|Split-Path -leaf) + ".backup")
Rename-Item -Path $cert -NewName (($cert|Split-Path -leaf) + ".backup")
Rename-Item -Path $certKey -NewName (($certKey|Split-Path -leaf) + ".backup")

Invoke-WebRequest -Uri "http://10.222.97.30:8000/ca.crt" -OutFile $ca
Invoke-WebRequest -Uri "http://10.222.97.30:8000/elk.crt" -OutFile $cert
Invoke-WebRequest -Uri "http://10.222.97.30:8000/elk.key" -OutFile $certKey

If (Get-Service Metricbeat -ErrorAction SilentlyContinue) {
    Restart-Service -Name Metricbeat
}
If (Get-Service Filebeat -ErrorAction SilentlyContinue) {
    Restart-Service -Name Filebeat
}
If (Get-Service Auditbeat -ErrorAction SilentlyContinue) {
    Restart-Service -Name Auditbeat
}
If (Get-Service Winlogbeat -ErrorAction SilentlyContinue) {
    Restart-Service -Name Winlogbeat
}

PAUSE 
