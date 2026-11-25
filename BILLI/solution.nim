const flushBlockBytes = 1 shl 17
const unreachableDepth = 1000000000

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or
                            data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var token = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and
        data[pos] != '\r' and data[pos] != '\t':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var trieHead = newSeq[int](1)
var trieMinDepth = newSeq[int](1)
var trieEndsWord = newSeq[bool](1)
var edgeNext = newSeq[int](0)
var edgeChar = newSeq[int](0)
var edgeChild = newSeq[int](0)

proc resetTrie() =
  trieHead.setLen 1
  trieMinDepth.setLen 1
  trieEndsWord.setLen 1
  edgeNext.setLen 0
  edgeChar.setLen 0
  edgeChild.setLen 0
  trieHead[0] = -1
  trieMinDepth[0] = unreachableDepth
  trieEndsWord[0] = false

proc findChild(node: int, character: int): int =
  var edgeIndex = trieHead[node]
  while edgeIndex != -1:
    if edgeChar[edgeIndex] == character:
      return edgeChild[edgeIndex]
    edgeIndex = edgeNext[edgeIndex]
  return -1

proc insertWord(word: string) =
  var node = 0
  let wordLength = word.len
  if wordLength < trieMinDepth[0]:
    trieMinDepth[0] = wordLength
  for charIndex in 0 .. wordLength - 1:
    let character = int(word[charIndex]) - 97
    var child = findChild(node, character)
    if child == -1:
      child = trieHead.len
      trieHead.add -1
      trieMinDepth.add unreachableDepth
      trieEndsWord.add false
      let edgeIndex = edgeNext.len
      edgeNext.add trieHead[node]
      edgeChar.add character
      edgeChild.add child
      trieHead[node] = edgeIndex
    if wordLength < trieMinDepth[child]:
      trieMinDepth[child] = wordLength
    node = child
  trieEndsWord[node] = true

proc conversionCost(word: string, removeCost: int64, addCost: int64): int64 =
  let wordLength = word.len
  var node = 0
  var depth = 0
  var best = int64(unreachableDepth) * removeCost
  while true:
    if trieEndsWord[node]:
      let candidate = int64(wordLength - depth) * removeCost
      if candidate < best:
        best = candidate
    let subtreeDepth = trieMinDepth[node]
    if subtreeDepth > depth and subtreeDepth < unreachableDepth:
      let candidate = int64(wordLength - depth) * removeCost +
                      int64(subtreeDepth - depth) * addCost
      if candidate < best:
        best = candidate
    if depth == wordLength:
      break
    let child = findChild(node, int(word[depth]) - 97)
    if child == -1:
      break
    node = child
    depth += 1
  return best

proc siftDown(heap: var seq[int64], heapSize: int, start: int) =
  var parent = start
  while true:
    let leftChild = parent * 2
    if leftChild > heapSize:
      break
    let rightChild = leftChild + 1
    var largerChild = leftChild
    if rightChild <= heapSize and heap[rightChild] > heap[leftChild]:
      largerChild = rightChild
    if heap[parent] >= heap[largerChild]:
      break
    swap(heap[parent], heap[largerChild])
    parent = largerChild

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let removeCost = int64(nextInt(inputData, scanPos))
  let addCost = int64(nextInt(inputData, scanPos))
  let needCount = nextInt(inputData, scanPos)
  let magicCount = nextInt(inputData, scanPos)
  let stolenCount = nextInt(inputData, scanPos)
  resetTrie()
  for magicIndex in 0 .. magicCount - 1:
    insertWord(nextToken(inputData, scanPos))
  var heap = newSeq[int64](needCount + 1)
  var heapSize = 0
  for stolenIndex in 0 .. stolenCount - 1:
    let cost = conversionCost(nextToken(inputData, scanPos), removeCost, addCost)
    if heapSize < needCount:
      heapSize += 1
      heap[heapSize] = cost
      var child = heapSize
      while child > 1:
        let parent = child div 2
        if heap[parent] >= heap[child]:
          break
        swap(heap[parent], heap[child])
        child = parent
    elif cost < heap[1]:
      heap[1] = cost
      siftDown(heap, heapSize, 1)
  var totalCost: int64 = 0
  for heapIndex in 1 .. heapSize:
    totalCost = totalCost + heap[heapIndex]
  appendOutput($totalCost)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
