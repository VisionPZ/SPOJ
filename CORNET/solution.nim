const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const lengthModulus = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc nextCommand(data: string, i: var int): char =
  while i < data.len and data[i] <= ' ':
    i += 1
  result = data[i]
  i += 1

var parentArr: seq[int]
var distArr: seq[int]

proc findRoot(nodeIdx: int): int =
  if parentArr[nodeIdx] != nodeIdx:
    let oldParent = parentArr[nodeIdx]
    let rootIdx = findRoot(oldParent)
    distArr[nodeIdx] += distArr[oldParent]
    parentArr[nodeIdx] = rootIdx
    return rootIdx
  return nodeIdx

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for caseIdx in 0..<caseCount:
  let enterpriseCount = nextInt(inputData, i)
  parentArr = newSeq[int](enterpriseCount + 1)
  distArr = newSeq[int](enterpriseCount + 1)
  for k in 0..enterpriseCount:
    parentArr[k] = k
    distArr[k] = 0
  while true:
    let commandChar = nextCommand(inputData, i)
    if commandChar == 'O':
      break
    if commandChar == 'E':
      let nodeIdx = nextInt(inputData, i)
      discard findRoot(nodeIdx)
      appendOutput($(distArr[nodeIdx]))
      outputBuffer.add '\n'
    elif commandChar == 'I':
      let centerIdx = nextInt(inputData, i)
      let linkedIdx = nextInt(inputData, i)
      parentArr[centerIdx] = linkedIdx
      var chainDiff = centerIdx - linkedIdx
      if chainDiff < 0:
        chainDiff = -chainDiff
      distArr[centerIdx] = chainDiff mod lengthModulus

stdout.write outputBuffer
outputBuffer.setLen 0
