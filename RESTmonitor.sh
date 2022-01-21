#!/bin/bash

#SUAV Monitor - Test a few of the available web services and notify if any issues
# - Monitors Pitney Bowes Universal Address Verification Service
# - Uses the open token generated for user:SUAVmonitor using getAccessRemoteHostToken method of TokenManagerService
# - For mail support, had to update /etc/postfix/main.cf with
#	inet_protocols = ipv4	(to suppress warnings)
#	relayhost = xxxx	(to get our relay in there)



server="xxxx"
serviceRoot="https://$server:443/rest"
token="xxxx"
supportEmails="mark@email.com"


#test cases
validateAddress="/ValidateAddress/results.json?Data.AddressLine1=111%20st%20clair%20ave&Data.PostalCode=55105"
getCandidateAddresses="/GetCandidateAddresses/results.json?Data.AddressLine1=P.O.+Box+1&Data.City=New+York&Data.StateProvince=NY"
getPostalCodes="/GetPostalCodes/results.json?Data.City=Saint+Paul&Data.StateProvince=MN"
getCityStateProvince="/GetCityStateProvince/results.json?Data.PostalCode=55105"

#service status
valAdd="Fail"
canAdd="Fail"
posCod="Fail"
citSta="Fail"

echo "######################################"
echo "#####       SUAV Monitor         #####"
echo "######################################"

#run service tests
dt=$(date '+%Y/%m/%d %H:%M:%S');
STARTTIME=$(date +%s%3N) 

echo -e "\n$dt - Beginning Method Tests for $server..."
echo -e "\nMETHOD TEST: Validate Address"
if [[ $(curl -k -X GET -H "Authorization: Bearer $token" "$serviceRoot$validateAddress" | grep ProcessedBy | grep USA | wc -l) -gt 0 ]]; then
	valAdd="Pass"
fi
echo -e "\nMETHOD TEST: Get Candidate Addresses"
if [[ $(curl -k -X GET -H "Authorization: Bearer $token" "$serviceRoot$getCandidateAddresses"  | grep ProcessedBy | grep USA | wc -l) -gt 0 ]]; then
	canAdd="Pass"
fi
echo -e "\nMETHOD TEST: Get Postal Codes"
if [[ $(curl -k -X GET -H "Authorization: Bearer $token" "$serviceRoot$getPostalCodes"  | grep ProcessedBy | grep USA | wc -l) -gt 0 ]]; then
	posCod="Pass"
fi
echo -e "\nMETHOD TEST: Get City/State/Province"
if [[ $(curl -k -X GET -H "Authorization: Bearer $token" "$serviceRoot$getCityStateProvince"  | grep ProcessedBy | grep USA | wc -l) -gt 0 ]]; then
	citSta="Pass"
fi

echo -e "\nRESULTS"
echo "Valdate Address:		$valAdd"
echo "Get Candidate Addresses:	$canAdd"
echo "Get Postal Codes:		$posCod"
echo "Get City/State/Province:	$citSta"

dt=$(date '+%Y/%m/%d %H:%M:%S');
ENDTIME=$(date +%s%3N) 
echo -e "\n$dt - Method Tests Completed in $(($ENDTIME - $STARTTIME))ms."

#send email to admins upon failure
if [[ "$valAdd$canAdd$posCod$citSta" = *"Fail"* ]]; then
	echo "Failures found sending alert to support staff"
	echo -e "SUAVmonitor detected some service failures at $dt on $server:\nValidate Address:		$valAdd\nGet Candidate Addresses:	$canAdd\nGet Postal Codes:		$posCod\nGet City/State/Province:	$citSta" | mail -s "SUAVmonitor Failure: $server" $supportEmails 

fi

