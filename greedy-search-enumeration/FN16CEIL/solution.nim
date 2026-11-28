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

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false

proc serializeShape(leftChild: seq[int], rightChild: seq[int], nodeIndex: int): string =
  if nodeIndex == -1:
    return "."
  result = "("
  result.add serializeShape(leftChild, rightChild, leftChild[nodeIndex])
  result.add serializeShape(leftChild, rightChild, rightChild[nodeIndex])
  result.add ")"

proc shapeSignature(values: seq[int]): string =
  var ordered = newSeq[int](values.len)
  for index in 0 .. values.len - 1:
    ordered[index] = values[index]
  for index in 1 .. ordered.len - 1:
    let key = ordered[index]
    var previousIndex = index - 1
    while previousIndex >= 0 and ordered[previousIndex] > key:
      ordered[previousIndex + 1] = ordered[previousIndex]
      previousIndex -= 1
    ordered[previousIndex + 1] = key
  var ranks = newSeq[int](values.len)
  for index in 0 .. values.len - 1:
    var low = 0
    var high = ordered.len - 1
    while low <= high:
      let middle = (low + high) div 2
      if ordered[middle] == values[index]:
        ranks[index] = middle
        break
      elif ordered[middle] < values[index]:
        low = middle + 1
      else:
        high = middle - 1
  var leftChild = newSeq[int](values.len)
  var rightChild = newSeq[int](values.len)
  for index in 0 .. values.len - 1:
    leftChild[index] = -1
    rightChild[index] = -1
  if values.len > 0:
    for index in 1 .. values.len - 1:
      let insertedRank = ranks[index]
      var currentNode = 0
      while true:
        if insertedRank < ranks[currentNode]:
          if leftChild[currentNode] == -1:
            leftChild[currentNode] = index
            break
          currentNode = leftChild[currentNode]
        else:
          if rightChild[currentNode] == -1:
            rightChild[currentNode] = index
            break
          currentNode = rightChild[currentNode]
  return serializeShape(leftChild, rightChild, 0)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextToken(inputData, scanPos):
  let protoCount = nextInt(inputData, scanPos)
  let layerCount = nextInt(inputData, scanPos)
  var signatures = newSeq[string](0)
  for protoIndex in 0 .. protoCount - 1:
    var values = newSeq[int](layerCount)
    for layerIndex in 0 .. layerCount - 1:
      values[layerIndex] = nextInt(inputData, scanPos)
    let signature = shapeSignature(values)
    var seen = false
    for previousSignature in signatures:
      if previousSignature == signature:
        seen = true
        break
    if not seen:
      signatures.add signature
  appendOutput($signatures.len)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
