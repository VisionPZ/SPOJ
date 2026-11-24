const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const initialBufferBytes = 1 shl 20

var inputData = ""
inputData.setLen(initialBufferBytes)
var totalRead = 0
while true:
  if totalRead == inputData.len:
    inputData.setLen(inputData.len * 2)
  let bytesRead = stdin.readBuffer(addr inputData[totalRead], inputData.len - totalRead)
  if bytesRead == 0: break
  totalRead += bytesRead
inputData.setLen(totalRead)

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc findRoot(parent: var seq[int], nodeIndex: int): int =
  var rootIndex = nodeIndex
  while parent[rootIndex] != rootIndex:
    rootIndex = parent[rootIndex]
  var walkIndex = nodeIndex
  while parent[walkIndex] != walkIndex:
    let nextIndex = parent[walkIndex]
    parent[walkIndex] = rootIndex
    walkIndex = nextIndex
  return rootIndex

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let primeCount = nextInt(inputData, scanPos)
  let relationCount = nextInt(inputData, scanPos)
  var parent = newSeq[int](primeCount + 1)
  var componentSize = newSeq[int](primeCount + 1)
  for primeIndex in 0..primeCount:
    parent[primeIndex] = primeIndex
    componentSize[primeIndex] = 1
  var squareCount = 0
  for relationIndex in 0..<relationCount:
    let leftPrime = nextInt(inputData, scanPos)
    let rightPrime = nextInt(inputData, scanPos)
    let leftRoot = findRoot(parent, leftPrime)
    let rightRoot = findRoot(parent, rightPrime)
    if leftRoot == rightRoot:
      squareCount += 1
    elif componentSize[leftRoot] < componentSize[rightRoot]:
      parent[leftRoot] = rightRoot
      componentSize[rightRoot] += componentSize[leftRoot]
    else:
      parent[rightRoot] = leftRoot
      componentSize[leftRoot] += componentSize[rightRoot]
  appendOutput($(squareCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
