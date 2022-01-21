Write-Output "#############################################"
Write-Output "###Datacap 917-IF003 Software Distribution###"
Write-Output "#############################################"
###
### Datacap 917-IF003 Software Distribution/Backup
###
### Function:
### - backs up custom datacap configuration files that we specify so we do not lose customizations due to patch overwriting them
### - moves 917-IF003 install to target servers and unzips
###
### Prereqs:
###     - Target Powershell version must be at 5+.  This is required for Expand-Archive
###     - Target system must have WinRM (Powershell remote management enabled) and ports 5985/5986 available.
###          Required for running remote methods via Invoke-Command
###     - upgradeSoftwareName .zip file must be zipped in something other than DEFLATE64 compression.  It looks like
###          the native PS/.NET Expand-Archive (or System.IO.Compression.ZipFile) do not support this compression.
###          7zip will tell you the compression being used.


#staging variables
$targetServerNames = "Server1", "Server2", "Server3", "Server4", "Server5", "Server6"

$upgradeSoftwarePath = "\\mn-dhs1.co.dhs\IT\SWR\EDMS\Server_Software\Datacap_9.1.7_Software\9.1.7-IF003\"
$upgradeSoftwareName = "9.1.7.0-Datacap-WIN-IF003.zip"
$targetStagingDir = "c$\dc_install\917-IF003\"

#file backup variables
$filesToBackup = "c$\Datacap\Taskmaster\wTMservice.exe.config", "c$\Datacap\Taskmaster\RRProcessor.exe.config", "c$\Datacap\DStudio\DStudio.exe.config", "c$\Datacap\datacap.xml"
$backupPostFix = ".pre917-IF003_bkp"



###
### makeStagingSub - Make a staging subdirectory for our install if it does not exist.
###
function makeStagingSub($serverName, $targetStagingDir){
	
	if(Test-Path "filesystem::\\$serverName\$targetStagingDir"){
		Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Staging directory filesystem::\\$serverName\$targetStagingDir exists. [OK]"
	}else{
		Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Staging directory filesystem::\\$serverName\$targetStagingDir not found, creating it."
		New-Item -Path "filesystem::\\$serverName\$targetStagingDir" -ItemType "directory" | Out-Null
	}
}

###
### stagingPrereqs - Verify servers online, staging directory available, copy/unzip software (ignore if it already exists)
###
function stagingPrereqs([string[]]$targetServerNames, $targetStagingDir, $upgradeSoftwareName, $upgradeSoftwarePath){
    foreach($server in $targetServerNames){

        #Check if server is online.
        if(Test-Connection -ComputerName $server -count 1 -quiet){
            Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - $server is online. [OK]"

			#Create staging sub dir if needed
			makeStagingSub $server $targetStagingDir

            #Verify staging path exists
            if(Test-Path "filesystem::\\$server\$targetStagingDir"){
                Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Staging directory filesystem::\\$server\$targetStagingDir found. [OK]"

                #Check if software already distributed (do not want to re-copy if not needed)
                if(Test-Path -PathType Leaf "filesystem::\\$server\$targetStagingDir\$upgradeSoftwareName"){
                     Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - $upgradeSoftwareName found.  Doing Nothing. [OK]"
                }else{
                    Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - $upgradeSoftwareName not found.  Copying.  [OK]"
                    Write-Output "$upgradeSoftwarePath$upgradeSoftwareName"
                    Write-Output "filesystem::\\$server\$targetStagingDir"
                    Copy-Item "filesystem::$upgradeSoftwarePath$upgradeSoftwareName" -Destination "filesystem::\\$server\$targetStagingDir\\"
                    Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Copying complete. [OK]"
                }

                #Remotely invoke unzipping of distribution
                Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Unzipping distribution on $server $($targetStagingDir.replace("`$", ":")) ..."
                $src = "$($targetStagingDir.replace("`$", ":"))$upgradeSoftwareName"
                $dst = "$($targetStagingDir.replace("`$", ":"))"
                Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Extracting $src to $dst"
                #Invoke-Command -ScriptBlock {Add-Type -Assembly 'System.IO.Compression.FileSystem'; [System.IO.Compression.ZipFile]::ExtractToDirectory( $using:src, $using:dst) } -ComputerName $server 
                Invoke-Command -ScriptBlock {Expand-Archive -LiteralPath $using:src -DestinationPath $using:dst -Force } -ComputerName $server
                Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Extact complete on $server. [OK]"
            }else{
                Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Staging directory filesystem::\\$server\$targetStagingDir was not found. [ERROR]"
            }
        }else{
            Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - $server is not available. [ERROR]"
        }
    }


}

function backupFiles ([string[]]$targetServerNames, [string[]]$filesToBackup, $backupPostFix){
    #backup and copy files
	$bkpCount = 0
	
    foreach($targetServer in $targetServerNames){
        foreach($file in $filesToBackup){
            if(Test-Path -PathType Leaf "filesystem::\\$targetServer\$file"){
                Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - $file found on $targetServer, backing up as $file$backupPostFix"

                #Do nothing if backup already exists - we do not want to overwrite good backup
                if(Test-Path -PathType Leaf "filesystem::\\$targetServer\$file$backupPostFix"){
                    Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Backup $file$backupPostFix already exists - Doing nothing. [ERROR]."
                }else{
                    Copy-Item "filesystem::\\$targetServer\$file" -Destination "filesystem::\\$targetServer\$file$backupPostFix"
                    Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - Backup $file$backupPostFix created. [OK]."
					$bkpCount++
                }
            }
        }
		Write-Output "$(Get-Date -format "yyyy/MM/dd HH:mm:ss") - $bkpCount files backed up on $targetServer."
    }

}



#Run file backup
backupFiles $targetServerNames $filesToBackup $backupPostFix

#Run Staging
stagingPrereqs $targetServerNames $targetStagingDir $upgradeSoftwareName $upgradeSoftwarePath


