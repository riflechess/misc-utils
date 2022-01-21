#
#	Connecting Test for windows clients
#	Paste in a bunch of destination hosts/ports to test connections (rather than using telnet or curl).
#	It will test the connections, then give you a list of all the failures.
#	riflechess  6/2016
#			 	8/2016 - fail counter/stats, support "IP:Port, IP,Port" notation
#				9/2016 - catch error when host not found in DNS
#				4/2017 - catch error on trim function to support older versions of powershell
#				7/2017 - add retry at end

add-type -assembly System.Windows.Forms
$form=New-Object System.Windows.Forms.Form
$form.StartPosition='CenterScreen'
$form.Text = "Enter Destinations"
$btn=New-Object System.Windows.Forms.Button
$btn.Text='OK'
$btn.DialogResult='OK'
$btn.Dock='bottom'
$form.Controls.Add($btn)
$btnCancel=New-Object System.Windows.Forms.Button
$btnCAncel.Text='Cancel'
$btnCancel.DialogResult='Cancel'
$btnCancel.Dock='bottom'
$form.Controls.Add($btnCancel)
$tb=New-Object System.Windows.Forms.Textbox
$tb.Multiline=$true
$tb.Dock='Fill'
#just some random samples
$tb.Text = "localhost 445
127.0.0.1 999
localhost:333"						
$ctTotal = 0
$ctSuccess = 0
$SuccessRate = 0


$form.Controls.Add($tb)
$form.add_load({$tb.Select()})
if($form.ShowDialog() -eq 'OK'){
	Write-Host "###########################################";
	Write-Host "#            Connection Test              #";
	Write-Host "###########################################";
    Write-Host "Source Info:";
	get-wmiobject win32_networkadapterconfiguration | ? { $_.IPAddress -ne $null } | Sort-Object IPAddress -Unique
	Write-Host "`n";

    do
    {
	    $iter = $tb.lines.GetEnumerator()
	    do
	    {
		    $suppress = $iter.MoveNext()		#assign to dummy variable so PS doesn't output bool result to shell...yep
		    $line = $iter.Current
		    if( -not $line )
		    {
			    break
		    }
		    #normalize input, split
		    $line = $line.Replace(":", " ")
		    $line = $line.Replace(",", " ")
		    $CompName, $Port = $line -split '(\s)', 2;
		    Try{
			    $Port=$Port.trim()	
			    $CompName=$CompName.trim()		
			    }
			    Catch{
			    #do nothing - earlier versions of PS don't like trim
			    }
		     Try
            {
			    $ctTotal++;
			    Write-Host -NoNewline "***";
                Write-Host -NoNewline "Testing connection to "$CompName`:$Port"...";
			    (New-Object System.Net.Sockets.TcpClient).Connect("$CompName", "$Port")
                Write-Host -NoNewline "[OK]" -fore green;
			    Write-Host ""
			    $ctSuccess++;
            }
            Catch
            {
                Write-Host  -NoNewline "[FAIL]" -fore red;
			    Write-Host ""
			    Try
			    {
			    $Failures = "$Failures" + "`n" + [System.Net.Dns]::GetHostAddresses("$CompName")[0].IPAddressToString + "$Port" + "`t($CompName)"
			    }
			    Catch
			    {
			    $Failures = "$Failures" + "`n" + "$CompName" + "$Port" + "`t(host not found)"
			    }
			    Finally
			    {
			
			    }
            }
            Finally
            {

            }
		
	    } while( $line )
	
	
	$SuccessRate= $ctSuccess/$ctTotal
	$SuccessRate= "{0:P0}" -f $SuccessRate
	
	Write-Host "`nTesting Complete.  $ctSuccess of $ctTotal connections succeeded ($SuccessRate)"  
	Write-Host "`nFailures: $Failures"
    
    #clear failures incase retry toggled
    	$Failures = $null
    	$ctTotal = 0
	$ctSuccess = 0
	$SuccessRate = 0
    Write-Host "`n[r] to retry or [enter] to exit:"
    $retry = read-host

    } while( $retry -eq "r")


	
}else{
	#cancelled
}
