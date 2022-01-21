def aTranslate(str):
    #trim @ char and translate to 16 bit binary
    str = bin(int(str.strip('@')))
    bstring = str[2:]
    leadZero = 16 - len(bstring)
    return '0' * leadZero + bstring;


print "Begin Assembler..."

symbol = {}
symbol['R0']="0"
symbol['R1']="1"
symbol['R2']="2"
symbol['R3']="3"
symbol['R4']="4"
symbol['R5']="5"
symbol['R6']="6"
symbol['R7']="7"
symbol['R8']="8"
symbol['R9']="9"
symbol['R10']="10"
symbol['R11']="11"
symbol['R12']="12"
symbol['R13']="13"
symbol['R14']="14"
symbol['R15']="15"
symbol['SCREEN']="16384"
symbol['KBD']="24576"
symbol['SP']="0"
symbol['LCL']="1"
symbol['ARG']="2"
symbol['THIS']="3"
symbol['THAT']="4"

symIterator = 0

def cTranslate(str):
    comp = {}
    #a=0
    comp['0']="0101010"
    comp['1']="0111111"
    comp['-1']="0111010"
    comp['D']="0001100"
    comp['A']="0110000"
    comp['!D']="0001101"
    comp['!A']="0110001"
    comp['-D']="0001111"
    comp['-A']="0110011"
    comp['D+1']="0011111"
    comp['A+1']="0110111"
    comp['D-1']="0001110"
    comp['A-1']="0110010"
    comp['D+A']="0000010"
    comp['D-A']="0010011"
    comp['A-D']="0000111"
    comp['D&A']="0000000"
    comp['D|A']="0010101"
    #a=1
    comp['M']="1110000"
    comp['!M']="1110001"
    comp['-M']="1110011"
    comp['M+1']="1110111"
    comp['M-1']="1110010"
    comp['D+M']="1000010"
    comp['D-M']="1010011"
    comp['M-D']="1000111"
    comp['D&M']="1000000"
    comp['D|M']="1010101"

    dest = {}
    dest['0']="000"
    dest['M']="001"
    dest['D']="010"
    dest['MD']="011"
    dest['A']="100"
    dest['AM']="101"
    dest['AD']="110"
    dest['AMD']="111"

    jump = {}
    jump['JGT'] = "001"
    jump['JEQ'] = "010"
    jump['JGE'] = "011"
    jump['JLT'] = "100"
    jump['JNE'] = "101"
    jump['JLE'] = "110"
    jump['JMP'] = "111"

    print "translating",str

    #if "//" in str:
     #   mark = str.index("//")
      #  str = str[:mark]


    instruction = "000"
    #start with jump
    for key, value in jump.items():

        if key in str:
            instruction = value
            print key
            print value
            print instruction

    #find destination
    if "=" in str:
        mark = str.index("=")
        print mark
        print str[:mark]

        for key, value in dest.items():
            #read value to left of = or ;
            if str[:mark]==key:
                print "hit on",key
                print "instruction",instruction
                print "value",value
                instruction = value + instruction
    else:
        instruction = "000" + instruction

    #find computation
    if "=" in str:
        mark = str.index("=") + 1
        end = str.index("\r")
        #end = len(str)
        for key, value in comp.items():
            if str[mark:end] == key:
                instruction = value + instruction
    elif ";" in str:
        mark = str.index(";")
        print "z mark",mark
        print "z str",str[:mark]
        for key, value in comp.items():
            if str[:mark]==key:
                instruction = value + instruction


    #add preceeding 111 for c instruct
    instruction = "111" + instruction
    print "translated inst",instruction
    return instruction;


fo = open("/Users/riflechess/dev/nand2tetris/projects/06/pong/Pong.asm", "r")
fo2 = open("/Users/riflechess/dev/nand2tetris/projects/06/pong/Pong.hack", "w")

asm = fo.readlines()

#identify symbols, add to symbol table
print "***Identify symbols, add to symbol table***"
for line in asm:
    line = line.lstrip()
    if line[0:2] != "//" and len(line) != 0:
        #symIterator = symIterator + 1
        #print line
        if line[:1]=='(':
            print "symbol found, line", symIterator
            start = line.index("(") + 1
            end = line.index(")")
            symName = line[start:end]
            print "symbol name is ",symName,", adding to symbol table"
            symbol[symName]=symIterator
        else:
            #iterate only if not a ()
            symIterator = symIterator + 1


#print symbol

#identify variables, add to symbol table if they do not exist

print "***Identify variables, add to symbol table if needed***"
symIterator = 16                    #start addressing new memory at 16

for line in asm:
    line = line.lstrip()            #kill left whitespace
    if line[:1]=="@" and line[0:2] != "//" and len(line) != 0:              #a-record detected
        print "zzzz",line
        start=line.index("@")+1
        end=line.index("\r")
        symName = line[start:end]
        if symName[:1].isalpha():
            addVar = True
            print symName,"was found, checking symbol table"
            #check if exists in symbol, add and iterate symIterator if not.
            for key, value in symbol.items():
                #print "key",key,"symName",symName
                if key == symName:
                    addVar = False
                    print symName,"was found in symbol table - skipping"
            if addVar:
                print symName,"was not found in symbol table - adding"
                symbol[symName]=symIterator
                symIterator = symIterator + 1
print "symbol table build complete"

print symbol

print "***Start command translation***"
outIterator = 0     #going to use this to iterate our out[] list
out=[]

for line in asm:
    line = line.lstrip()
    if line[0:2] != "//" and len(line) != 0 and line[:1] != "(":        #ignore blank lines, comments, loop references
        if line[:1]=="@":
            print "processing a-record"
            start = line.index("@") + 1
            end = line.index("\r")
            symName = line[start:end]
            print "zzz",symName
            if symName[:1].isalpha():
                print "alpha - needs translation"
                for key, value in symbol.items():
                    if key == symName:
                        line = "@" + str(value)
            print "a-value",line
            print "translated value is",aTranslate(line)
            out.append(aTranslate(line))                #append translated a-record to list...

        else:
            print "processing c-record"
            out.append(cTranslate(line))
    else:
        print "skipping comment, reference, or whitespace"




#print out
print symbol
#print binary to out file

for line in out:
    fo2.write(line + "\r\n")


fo.close()
fo2.close()
