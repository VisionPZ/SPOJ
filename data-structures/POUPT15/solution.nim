const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var nodeKeys = newSeq[int]()
  var leftChildren = newSeq[int]()
  var rightChildren = newSeq[int]()
  var rootNode = -1
  while scanPos < inputData.len:
    let keyValue = nextInt(inputData, scanPos)
    if keyValue == -1:
      break
    let newNode = nodeKeys.len
    nodeKeys.add keyValue
    leftChildren.add -1
    rightChildren.add -1
    if rootNode == -1:
      rootNode = newNode
    else:
      var currentNode = rootNode
      while true:
        if keyValue < nodeKeys[currentNode]:
          if leftChildren[currentNode] == -1:
            leftChildren[currentNode] = newNode
            break
          currentNode = leftChildren[currentNode]
        else:
          if rightChildren[currentNode] == -1:
            rightChildren[currentNode] = newNode
            break
          currentNode = rightChildren[currentNode]
  let nodeTotal = nodeKeys.len
  var nodeHeights = newSeq[int](nodeTotal)
  var balancedTree = true
  var nodeIndex = nodeTotal - 1
  while nodeIndex >= 0:
    var leftHeight = 0
    var rightHeight = 0
    if leftChildren[nodeIndex] != -1:
      leftHeight = nodeHeights[leftChildren[nodeIndex]]
    if rightChildren[nodeIndex] != -1:
      rightHeight = nodeHeights[rightChildren[nodeIndex]]
    nodeHeights[nodeIndex] = 1 + (if leftHeight > rightHeight: leftHeight else: rightHeight)
    if leftHeight - rightHeight > 1 or rightHeight - leftHeight > 1:
      balancedTree = false
    nodeIndex -= 1
  if balancedTree:
    appendOutput("sim")
  else:
    appendOutput("nao")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
