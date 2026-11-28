const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let persepolisHomeGoals = nextInt(inputData, scanPos)
let esteghlalAwayGoals = nextInt(inputData, scanPos)
let esteghlalHomeGoals = nextInt(inputData, scanPos)
let persepolisAwayGoals = nextInt(inputData, scanPos)
let persepolisAggregate = persepolisHomeGoals + persepolisAwayGoals
let esteghlalAggregate = esteghlalHomeGoals + esteghlalAwayGoals
if persepolisAggregate > esteghlalAggregate:
  appendOutput("Persepolis")
elif esteghlalAggregate > persepolisAggregate:
  appendOutput("Esteghlal")
elif persepolisAwayGoals > esteghlalAwayGoals:
  appendOutput("Persepolis")
elif esteghlalAwayGoals > persepolisAwayGoals:
  appendOutput("Esteghlal")
else:
  appendOutput("Penalty")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
