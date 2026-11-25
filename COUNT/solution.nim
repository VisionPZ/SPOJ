const flushBlockBytes = 1 shl 17
const modulusValue = 1988

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

var computerCounts = newSeq[int]()
var truckCounts = newSeq[int]()
var largestComputers = 0
var largestTrucks = 0
while true:
  let computers = nextInt(inputData, scanPos)
  let trucks = nextInt(inputData, scanPos)
  if computers == 0 and trucks == 0:
    break
  computerCounts.add computers
  truckCounts.add trucks
  if computers > largestComputers:
    largestComputers = computers
  if trucks > largestTrucks:
    largestTrucks = trucks

let columnCount = largestTrucks + 1
var partitionTable = newSeq[uint16]((largestComputers + 1) * columnCount)
partitionTable[0] = uint16(1)
for trucksUsed in 1 .. largestTrucks:
  var totalComputers = trucksUsed
  while totalComputers <= largestComputers:
    let withoutOne = int(partitionTable[(totalComputers - trucksUsed) * columnCount + trucksUsed])
    let withOne = int(partitionTable[(totalComputers - 1) * columnCount + (trucksUsed - 1)])
    partitionTable[totalComputers * columnCount + trucksUsed] = uint16((withoutOne + withOne) mod modulusValue)
    totalComputers += 1

for queryIndex in 0 .. computerCounts.len - 1:
  let computers = computerCounts[queryIndex]
  let trucks = truckCounts[queryIndex]
  appendOutput($(partitionTable[computers * columnCount + trucks]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
