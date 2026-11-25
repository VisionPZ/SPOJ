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

proc findRoot(parents: var seq[int], parities: var seq[int], node: int): int =
  if parents[node] == node:
    return node
  let oldParent = parents[node]
  let root = findRoot(parents, parities, oldParent)
  parities[node] = parities[node] xor parities[oldParent]
  parents[node] = root
  return root

proc powerOfTwoString(exponent: int): string =
  result = "1"
  for step in 0 .. exponent - 1:
    var carry = 0
    var digitIndex = result.len - 1
    while digitIndex >= 0:
      let doubled = 2 * (int(result[digitIndex]) - 48) + carry
      result[digitIndex] = char(doubled mod 10 + 48)
      carry = doubled div 10
      digitIndex -= 1
    if carry > 0:
      result = "1" & result

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let personCount = nextInt(inputData, scanPos)
  let questionCount = nextInt(inputData, scanPos)
  var parents = newSeq[int](questionCount)
  var parities = newSeq[int](questionCount)
  for questionIndex in 0 .. questionCount - 1:
    parents[questionIndex] = questionIndex
    parities[questionIndex] = 0
  var consistent = true
  for personIndex in 0 .. personCount - 1:
    let firstQuestion = nextInt(inputData, scanPos) - 1
    let firstAnswer = nextInt(inputData, scanPos)
    let secondQuestion = nextInt(inputData, scanPos) - 1
    let secondAnswer = nextInt(inputData, scanPos)
    if not consistent:
      continue
    let requiredXor = 1 xor firstAnswer xor secondAnswer
    let firstRoot = findRoot(parents, parities, firstQuestion)
    let firstParity = parities[firstQuestion]
    let secondRoot = findRoot(parents, parities, secondQuestion)
    let secondParity = parities[secondQuestion]
    let rootXor = requiredXor xor firstParity xor secondParity
    if firstRoot == secondRoot:
      if rootXor != 0:
        consistent = false
    else:
      parents[secondRoot] = firstRoot
      parities[secondRoot] = rootXor
  if not consistent:
    appendOutput("No Inference")
  else:
    var componentCount = 0
    for questionIndex in 0 .. questionCount - 1:
      if parents[questionIndex] == questionIndex:
        componentCount += 1
    if componentCount == questionCount:
      appendOutput("No Inference")
    else:
      appendOutput(powerOfTwoString(componentCount))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
