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

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc findRoot(parent: var seq[int], i: int): int =
  var j = i
  while parent[j] != j:
    j = parent[j]
  var k = i
  while parent[k] != k:
    let l = parent[k]
    parent[k] = j
    k = l
  return j

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let primeCount = nextInt(inputData, i)
  let relationCount = nextInt(inputData, i)
  var parent = newSeq[int](primeCount + 1)
  var componentSize = newSeq[int](primeCount + 1)
  for j in 0..primeCount:
    parent[j] = j
    componentSize[j] = 1
  var squareCount = 0
  for j in 0..<relationCount:
    let leftPrime = nextInt(inputData, i)
    let rightPrime = nextInt(inputData, i)
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
