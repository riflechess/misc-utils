import time
import sys

print "##################################################"
print "### was2json - WebSphere SystemOut.log to JSON ###"
print "##################################################\n"

if len(sys.argv)!=3:
    print "Usage:"
    print "was2json.py <logpath/name> <Elastic Search index name>"
    print "was2json.py SystemOut.log wasidx"
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
#{"index":{"_index":"wasidx","_type":"<Cell> <Node> <JVM>"}}
def indexStr(indexEntry):
    jsonStr = '{"index":{'
    jsonStr += '"_index":"'
    jsonStr += indexName
    jsonStr += '","_type":"'
    jsonStr += indexEntry['Cell']
    jsonStr += " "
    jsonStr += indexEntry['Node']
    jsonStr += " "
    jsonStr += indexEntry['JVM']
    jsonStr += '"}}'
    return jsonStr

#Construct json log entry
def conv2json(logEntry):
    jsonStr = '{'
    jsonStr += '"Date":"'
    jsonStr += logEntry['Date']
    jsonStr += '","Thread":"'
    jsonStr += logEntry['Thread']
    jsonStr += '","Subsystem":"'
    jsonStr += logEntry['Subsystem']
    jsonStr += '","Severity":"'
    jsonStr += logEntry['Severity']
    jsonStr += '","Description":"'
    jsonStr += logEntry['Description']
    jsonStr += '"}'
    return jsonStr


logEntry = {}
logEntry['Date'] = ""                   #8/8/17 16:37:30:961
logEntry['Thread'] = ""                 #00001854
logEntry['Subsystem'] = ""              #webapp
logEntry['Severity'] = ""               #E
logEntry['Description'] = ""            #com.ibm.ws.webcontainer.webapp.WebApp logServletError SRVE0293E: [Servlet Error]-[JAX-RS Servlet]: java.lang.RuntimeException

indexEntry = {}
indexEntry['Cell'] = ""                 #cell-prod-xx-v01Cell01
indexEntry['Node'] = ""                 #node-prod-xx-v01Node01
indexEntry['JVM'] = ""                  #JVM01

entCount = 0



print "Processing source log..."
for lineNum, line in enumerate(sourceLog,1):
    #Parse Index data from log file header
    if lineNum == 2:
        indexEntry['Cell'] = str(line.split('\\')[0]).split()[-1]
        indexEntry['Node'] = line.split('\\')[1]
        indexEntry['JVM']  = str(line.split('\\')[2]).split()[0]


    #Parse actual logfile info
    if line[0:1]=='[' and line[1:2].isdigit():
        #print "Log Entry Found, assigning variables..."
        logEntry['Date'] = str(line.split(']')[0]).split('[')[-1]
        logEntry['Thread'] = line.split()[3]
        logEntry['Subsystem'] = line.split()[4]
        logEntry['Severity'] = line.split()[5]
        # find where desc starts from prev token otherwise we'll get an out of range on a blank one + escape double-quote char
        logEntry['Description'] = (line[line.index(line.split()[5]) + len(line.split()[5]) + 1:-1]).replace('"','\\"')

        fo.write(indexStr(indexEntry) + "\n")
        fo.write(conv2json(logEntry) + "\n")
        entCount = entCount + 1

print "JSON file created",outFile
print "Finished -",lineNum,"lines", entCount,"messages in",(time.time() - startTime),"seconds"

fo.close()
fi.close()
