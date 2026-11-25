const flushBlockBytes = 1 shl 17
const infinityValue = high(int64) div 4

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

let numberCount = nextInt(inputData, scanPos)
let modulus = nextInt(inputData, scanPos)
var perRemainderHeaps = newSeq[int64](modulus * (modulus + 1))
var heapSizes = newSeq[int](modulus)
var totalSum: int64 = 0

for numberIndex in 0 .. numberCount - 1:
  let value = int64(nextInt(inputData, scanPos))
  totalSum = totalSum + value
  let remainder = int(value mod int64(modulus))
  let base = remainder * (modulus + 1)
  let size = heapSizes[remainder]
  if size < modulus:
    perRemainderHeaps[base + size] = value
    var childIndex = size
    while childIndex > 0:
      let parentIndex = (childIndex - 1) div 2
      if perRemainderHeaps[base + parentIndex] >= perRemainderHeaps[base + childIndex]:
        break
      swap perRemainderHeaps[base + parentIndex], perRemainderHeaps[base + childIndex]
      childIndex = parentIndex
    heapSizes[remainder] = size + 1
  elif value < perRemainderHeaps[base]:
    perRemainderHeaps[base] = value
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      let rightChild = leftChild + 1
      var largestIndex = parentIndex
      if leftChild < modulus and perRemainderHeaps[base + leftChild] > perRemainderHeaps[base + largestIndex]:
        largestIndex = leftChild
      if rightChild < modulus and perRemainderHeaps[base + rightChild] > perRemainderHeaps[base + largestIndex]:
        largestIndex = rightChild
      if largestIndex == parentIndex:
        break
      swap perRemainderHeaps[base + parentIndex], perRemainderHeaps[base + largestIndex]
      parentIndex = largestIndex

var bestDistances = newSeq[int64](modulus)
var nextDistances = newSeq[int64](modulus)
for residue in 0 .. modulus - 1:
  bestDistances[residue] = infinityValue
bestDistances[0] = 0

for remainder in 0 .. modulus - 1:
  let base = remainder * (modulus + 1)
  for heapIndex in 0 .. heapSizes[remainder] - 1:
    let value = perRemainderHeaps[base + heapIndex]
    for residue in 0 .. modulus - 1:
      nextDistances[residue] = bestDistances[residue]
    for residue in 0 .. modulus - 1:
      if bestDistances[residue] < infinityValue:
        let target = (residue + remainder) mod modulus
        let candidate = bestDistances[residue] + value
        if candidate < nextDistances[target]:
          nextDistances[target] = candidate
    swap bestDistances, nextDistances

let totalRemainder = int(totalSum mod int64(modulus))
var firstValue = true
for residue in 0 .. modulus - 1:
  let removalRemainder = (totalRemainder - residue + modulus) mod modulus
  var answer: int64 = -1
  if bestDistances[removalRemainder] < infinityValue:
    let candidateAnswer = totalSum - bestDistances[removalRemainder]
    if candidateAnswer > 0:
      answer = candidateAnswer
  if not firstValue:
    appendOutput(" ")
  appendOutput($answer)
  firstValue = false
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
