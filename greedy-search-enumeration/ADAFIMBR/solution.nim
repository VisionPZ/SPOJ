const flushBlockBytes = 1 shl 17
const seenSlots = 1024

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var maxSeeds = 0
while hasNextNumber(inputData, scanPos):
  let token = nextInt(inputData, scanPos)
  if token > maxSeeds:
    maxSeeds = token
scanPos = 0

var fibNumbers = newSeq[int]()
fibNumbers.add 1
fibNumbers.add 2
while fibNumbers[fibNumbers.len - 1] <= maxSeeds:
  fibNumbers.add fibNumbers[fibNumbers.len - 1] + fibNumbers[fibNumbers.len - 2]

var grundy = newSeq[int](maxSeeds + 1)
var seenValue = newSeq[int](seenSlots)
var stamp = 0
for seeds in 1 .. maxSeeds:
  stamp += 1
  for fibonacci in fibNumbers:
    if fibonacci > seeds:
      break
    let option = grundy[seeds - fibonacci]
    if option < seenSlots:
      seenValue[option] = stamp
  var mex = 0
  while mex < seenSlots and seenValue[mex] == stamp:
    mex += 1
  grundy[seeds] = mex

while hasNextNumber(inputData, scanPos):
  let pileCount = nextInt(inputData, scanPos)
  var nimTotal = 0
  for pileIndex in 0 .. pileCount - 1:
    let seeds = nextInt(inputData, scanPos)
    nimTotal = nimTotal xor grundy[seeds]
  if nimTotal != 0:
    appendOutput("Ada\n")
  else:
    appendOutput("Vinit\n")
stdout.write outputBuffer
outputBuffer.setLen 0
