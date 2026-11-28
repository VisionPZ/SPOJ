const flushBlockBytes = 1 shl 17
const latestStart = 1410
const minutesPerLesson = 30
const residueCount = 30

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

let requestCount = nextInt(inputData, scanPos)
var requestCounts = newSeq[int](latestStart + 1)
for requestIndex in 0 .. requestCount - 1:
  let startMinute = nextInt(inputData, scanPos)
  requestCounts[startMinute] += 1

var tutorCount = 0
for residue in 0 .. residueCount - 1:
  var freshTutors = 0
  var onceUsedTutors = 0
  var twiceUsedTutors = 0
  var lessonStart = residue
  while lessonStart <= latestStart:
    let demand = requestCounts[lessonStart]
    if demand == 0:
      freshTutors = 0
      onceUsedTutors = 0
      twiceUsedTutors = 0
    else:
      var remainingDemand = demand
      let useFresh = min(remainingDemand, freshTutors)
      remainingDemand -= useFresh
      let useOnce = min(remainingDemand, onceUsedTutors)
      remainingDemand -= useOnce
      let useTwice = min(remainingDemand, twiceUsedTutors)
      remainingDemand -= useTwice
      freshTutors = remainingDemand
      onceUsedTutors = useFresh
      twiceUsedTutors = useOnce
      tutorCount += remainingDemand
    lessonStart += minutesPerLesson

appendOutput($tutorCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
