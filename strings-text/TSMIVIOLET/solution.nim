const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1
var dayName = ""
while scanPos < inputData.len and inputData[scanPos] > ' ':
  dayName.add inputData[scanPos]
  scanPos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if dayName == "Saturday":
  appendOutput("Sandwich")
elif dayName == "Sunday":
  appendOutput("Soup")
elif dayName == "Monday":
  appendOutput("Macaroon")
elif dayName == "Tuesday":
  appendOutput("Toffee")
elif dayName == "Wednesday":
  appendOutput("Waffles")
elif dayName == "Thursday":
  appendOutput("Taco")
elif dayName == "Friday":
  appendOutput("French Fries")

appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
