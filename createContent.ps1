## Create Content
## Bulk generate simple content and metadata for import with FileNet ICC
##

$outPath = 'C:\dev\create_content\tmp\'
$docCount = 500
$i = 0

function createDoc($name){
    New-Item -Path "$name" -ItemType File
    Add-Content $name "Here is some content for the bulk file test for $name"    
}

function getFirstName(){
    $first = "ZABRINA","ZAHARA","ZANDRA","ZANETA","ZARA","ZARAH","ZARIA","ZARLA","ZEA","ZELDA","ZELMA","ZENA","ZENIA","ZIA","ZILVIA","ZITA","ZITELLA","ZOE","ZOLA","ZONDA","ZONDRA","ZONNYA","ZORA","ZORAH","ZORANA","ZORINA","ZORINE","ZSA ZSA","ZSAZSA","ZULEMA"
    return Get-Random -InputObject $first 
}
function getLastName(){
    $last = "SMITH","JOHNSON","WILLIAMS","JONES","BROWN","DAVIS","MILLER","WILSON","MOORE","TAYLOR","ANDERSON","THOMAS","JACKSON","WHITE","HARRIS","MARTIN","THOMPSON","GARCIA","MARTINEZ","ROBINSON","CLARK","RODRIGUEZ","LEWIS","LEE","WALKER","HALL","ALLEN","YOUNG","HERNANDEZ","KING","WRIGHT","LOPEZ","HILL","SCOTT","GREEN","ADAMS","BAKER","GONZALEZ","NELSON","CARTER","MITCHELL","PEREZ","ROBERTS","TURNER","PHILLIPS","CAMPBELL","PARKER"
    return Get-Random -InputObject $last
}

function createMeta($name){
    $firstName = getFirstName
    $lastName = getLastName

    New-Item -Path "$name" -ItemType File
    Add-Content $name "<Document>"
    Add-Content $name "<Indexvalue name=`"FirstName`">$(getFirstName)</Indexvalue>"
    Add-Content $name "<Indexvalue name=`"LastName`">$(getLastName)</Indexvalue>"
    Add-Content $name "<Indexvalue name=`"DocumentDate`"></Indexvalue>"
    Add-Content $name "</Document>"
}


While($i -lt $docCount){
    $name = $outPath + "bulk" + $i + ".txt"
    $metaName = $outPath + "bulk" + $i + ".xml"
    createDoc($name)
    createMeta($metaName)
    $i++
    }

