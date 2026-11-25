import algorithm

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

type ProcessRecord = tuple[turnCount: int64; processId: int]

proc finishesEarlier(firstRecord, secondRecord: ProcessRecord): int =
  if firstRecord.turnCount < secondRecord.turnCount: return -1
  if firstRecord.turnCount > secondRecord.turnCount: return 1
  if firstRecord.processId < secondRecord.processId: return -1
  if firstRecord.processId > secondRecord.processId: return 1
  return 0

let processCount = nextInt(inputData, scanPos)
let quantumSize = int64(nextInt(inputData, scanPos))
var processList = newSeq[ProcessRecord](processCount)
for processIndex in 0 .. processCount - 1:
  let burstTime = int64(nextInt(inputData, scanPos))
  let turnCount = (burstTime + quantumSize - 1) div quantumSize
  processList[processIndex] = (turnCount, processIndex + 1)
sort(processList, finishesEarlier)
var outputLine = ""
for processIndex in 0 .. processCount - 1:
  if processIndex > 0:
    outputLine.add ' '
  outputLine.add $processList[processIndex].processId
appendOutput(outputLine)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
