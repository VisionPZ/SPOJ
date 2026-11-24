{.push optimization: speed.}
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let triangleCount = vertexCount - 2
  var triMin = newSeq[int](triangleCount)
  var triMid = newSeq[int](triangleCount)
  var triMax = newSeq[int](triangleCount)
  for i in 0..<triangleCount:
    var firstVertex = nextInt(inputData, scanPos)
    var secondVertex = nextInt(inputData, scanPos)
    var thirdVertex = nextInt(inputData, scanPos)
    if firstVertex > secondVertex:
      let tmpValue = firstVertex
      firstVertex = secondVertex
      secondVertex = tmpValue
    if secondVertex > thirdVertex:
      let tmpValue = secondVertex
      secondVertex = thirdVertex
      thirdVertex = tmpValue
    if firstVertex > secondVertex:
      let tmpValue = firstVertex
      firstVertex = secondVertex
      secondVertex = tmpValue
    triMin[i] = firstVertex
    triMid[i] = secondVertex
    triMax[i] = thirdVertex

  let stride = vertexCount + 1
  var arcCounts = newSeq[int](vertexCount * stride)
  for i in 0..<triangleCount:
    let lowVertex = triMin[i]
    let midVertex = triMid[i]
    let highVertex = triMax[i]
    for j in lowVertex + 1 .. midVertex:
      let rowBase = j * stride
      arcCounts[rowBase + lowVertex] += 1
      arcCounts[rowBase + j] -= 1
    for j in midVertex + 1 .. highVertex:
      let rowBase = j * stride
      arcCounts[rowBase + midVertex] += 1
      arcCounts[rowBase + j] -= 1
    for j in highVertex + 1 ..< vertexCount:
      let rowBase = j * stride
      arcCounts[rowBase + highVertex] += 1
      arcCounts[rowBase + j] -= 1
    for j in 0 .. lowVertex:
      let rowBase = j * stride
      arcCounts[rowBase + highVertex] += 1
      arcCounts[rowBase + vertexCount] -= 1
      if j > 0:
        arcCounts[rowBase] += 1
        arcCounts[rowBase + j] -= 1

  for j in 0..<vertexCount:
    let rowBase = j * stride
    var running = 0
    for k in 0..<vertexCount:
      running += arcCounts[rowBase + k]
      arcCounts[rowBase + k] = running

  var bestConfined = high(int)
  for a in 0..<vertexCount:
    let rowA = a * stride
    for b in a + 1 ..< vertexCount:
      let fixedCost = arcCounts[rowA + b]
      if fixedCost >= bestConfined:
        break
      let rowB = b * stride
      for c in b + 1 ..< vertexCount:
        let partialCost = fixedCost + arcCounts[rowB + c]
        if partialCost >= bestConfined:
          break
        let confined = partialCost + arcCounts[c * stride + a]
        if confined < bestConfined:
          bestConfined = confined

  appendOutput($(triangleCount - bestConfined))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
