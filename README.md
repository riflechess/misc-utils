# misc-util

Random scripts.  Nothing too impressive here.  Mainly just reference for when I forget the syntax of something.

### Connection Test
**Connection_test.ps1** Tests hundreds of ip/host:port combinations that you paste in.  If you have an environment with lots of firewalls, this can be helpful.

![example image](https://github.com/riflechess/rand-util/blob/master/img/contest.JPG "Connection Test")

### P8 to JSON
**p82json.py**  Converts FileNet P8 P8_server_error.log files (which are produced by the Content Platform Engine) in to JSON format so they can be ingested and used in Elasticsearch/Kibana for troubleshooting and trending.  For the description token, it grabs the first line but omits the entire stack trace.

```
C:\>p82json.py C:\p8_server_error.log filenetindexname
#############################################
### p82json - p8_server_error.log to JSON ###
#############################################

Loading source file C:\p8_server_error.log ...
Elastic Search index name is filenetindexname
Processing source log...
JSON file created C:\p8_server_error.log.json
Finished - 438166 lines 16903 messages in 0.90499997139 seconds
```
Oddly, I've been using a bash shell running on top of windows to do the actual load of these in to Elasticsearch.
```
curl -H 'Content-Type: application/x-ndjson' -XPOST 'localhost:9200/filenetindexname/_bulk?pretty' --data-binary @p8_server_error.log.json
```
### WAS to JSON
**was2json.py**  Converts WebSphere SystemOut.log files in to JSON format so they can be ingested and used in Elasticsearch/Kibana for troubleshooting and trending.  Similar to p82json.py, stack traces are ommited from description token.
```
C:\was2json.py C:\SystemOut_17.07.20_11.55.48.log wasindexname
##################################################
### was2json - WebSphere SystemOut.log to JSON ###
##################################################

Loading source file C:\SystemOut_17.07.20_11.55.48.log...
Elastic Search index name is wasindexname
Processing source log...
JSON file created C:\SystemOut_17.07.20_11.55.48.log.json
Finished - 44776 lines 4572 messages in 0.322000026703 seconds
```
Load the JSON in to Elasticsearch using the following command via bash.  I'm sure it is possible, but I didn't have luck with PowerShell's curl equivalent.  
```
curl -H 'Content-Type: application/x-ndjson' -XPOST 'localhost:9200/wasindexname/_bulk?pretty' --data-binary @SystemOut_17.07.20_11.55.48.log.json
```

### assembler.py

My solutions from the Coursera class, *Build a Modern Computer from First Principles: From Nand to Tetris*.  These include .hdl (Hardware descriptor language) solutions and an assembler for the *Hack* computer.

### copyCleanReports.ps1

Simple script to copy files to a share, unless they contain an exception.  If they contain an exception it will send an email alert to support team.

### RESTmonitor.sh

REST service monitor, specifically for [Pitney Bowes Spectrum Universal Address Verification](https://www.precisely.com/product/precisely-spectrum-quality/spectrum-global-addressing) service.  

### AD_ChargeBack.ps1

Module for generating and sending user and group based chargeback reports.

### createContent.ps1

Module for generating random metadata for use in testing [FileNet P8 Integrated Content Collector](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=p8-content-collector) (ICC).

### staging.ps1

Module for deploying IBM Datacap to windows servers.
