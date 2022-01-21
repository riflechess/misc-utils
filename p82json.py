import time
import sys

print "#############################################"
print "### p82json - p8_server_error.log to JSON ###"
print "#############################################\n"

if len(sys.argv)!=3:
    print "Usage:"
    print "p82json.py <logpath/name> <Elastic Search index name>"
    print "p82json.py p8_server_error.log filenetidx"
    exit()

startTime = time.time()

print "Loading source file",str(sys.argv[1]),"..."
fi = open(str(sys.argv[1]), 'r')
outFile = str(sys.argv[1])
outFile += '.json'
fo = open(outFile, 'w')
sourceLog = fi.readlines()

indexName = str(sys.argv[2])
print "Elastic Search index name is",indexName


#Elastic Search requires an action/data pair for each insert

#Construct Elastic Search index entry
#{"index":{"_index":"filenet","_type":"jvm_name servername version"}}
def indexStr(indexEntry):
    jsonStr = '{"index":{'
    jsonStr += '"_index":"'
    jsonStr += indexName
    jsonStr += '","_type":"'
    jsonStr += indexEntry['ServerInstance']
    jsonStr += " "
    jsonStr += indexEntry['Server']
    jsonStr += " "
    jsonStr += indexEntry['Version']
    jsonStr += '"}}'
    return jsonStr

#Construct json log entry
#{"Date":"2017-08-11T01:23:41.740","Thread":"C07817C7","Subsystem":"ASYN","Category":"FNRCE0000I","Severity":"INFO","Description":"dispatchFailed: Ignoring queue item: {80EBC923-0A33-4550-BD6D-630E153F36E0} for 30 seconds."}
def conv2json(logEntry):
    jsonStr = '{'
    jsonStr += '"Date":"'
    jsonStr += logEntry['Date']
    jsonStr += '","Thread":"'
    jsonStr += logEntry['Thread']
    jsonStr += '","Subsystem":"'
    jsonStr += logEntry['Subsystem']
    jsonStr += '","Category":"'
    jsonStr += logEntry['Category']
    jsonStr += '","Severity":"'
    jsonStr += logEntry['Severity']
    jsonStr += '","Description":"'
    jsonStr += logEntry['Description']
    jsonStr += '"}'
    return jsonStr


logEntry = {}
logEntry['Date'] = ""
logEntry['Thread'] = ""
logEntry['Subsystem'] = ""
logEntry['Category'] = ""
logEntry['Severity'] = ""
logEntry['Description'] = ""

indexEntry = {}
indexEntry['Version'] = ""
indexEntry['Build'] = ""
indexEntry['Server'] = ""
indexEntry['VirtualServer'] = ""
indexEntry['ServerInstance'] = ""

entCount = 0



print "Processing source log..."
for lineNum, line in enumerate(sourceLog,1):
    #Parse Index data from log file header
    if lineNum == 1:
        indexEntry['Version'] = line.split()[5]
        indexEntry['Build'] = line.split()[7]
        indexEntry['Server'] = line.split()[9]
    if lineNum == 3:
        indexEntry['VirtualServer'] = line.split()[1]
        indexEntry['ServerInstance'] = line.split()[3]

    #Parse actual logfile info
    if line[0:4].isdigit():
        #print "Log Entry Found, assigning variables..."
        logEntry['Date'] = line.split()[0]
        logEntry['Thread'] = line.split()[1]
        logEntry['Subsystem'] = line.split()[2]
        logEntry['Category'] = line.split()[3]
        logEntry['Severity'] = line.split()[5]  #omit '-'
        # find where desc starts from prev token otherwise we'll get an out of range on a blank one + escape double-quote char
        logEntry['Description'] = (line[line.index(line.split()[5]) + len(line.split()[5]) + 1:-1]).replace('"','\\"')


        fo.write(indexStr(indexEntry) + "\n")
        fo.write(conv2json(logEntry) + "\n")
        entCount = entCount + 1

print "JSON file created",outFile
print "Finished -",lineNum,"lines", entCount,"messages in",(time.time() - startTime),"seconds"

fo.close()
fi.close()
