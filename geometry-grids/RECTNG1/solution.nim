{.passC: "-O3".}
{.push checks: off.}

import algorithm

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
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type Rectangle = object
  x1: int
  y1: int
  x2: int
  y2: int

proc compareRect(left, right: Rectangle): int =
  if left.x1 < right.x1: result = -1
  elif left.x1 > right.x1: result = 1
  else: result = 0

var parents: seq[int]
var ranks: seq[int]

proc findRoot(node: int): int =
  var root = node
  while parents[root] != root:
    root = parents[root]
  var cursor = node
  while parents[cursor] != cursor:
    let nextNode = parents[cursor]
    parents[cursor] = root
    cursor = nextNode
  return root

proc unite(left, right: int) =
  var rootLeft = findRoot(left)
  var rootRight = findRoot(right)
  if rootLeft == rootRight: return
  if ranks[rootLeft] < ranks[rootRight]: swap(rootLeft, rootRight)
  parents[rootRight] = rootLeft
  if ranks[rootLeft] == ranks[rootRight]: ranks[rootLeft] += 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let rectCount = nextInt(inputData, scanPos)
  var rects = newSeq[Rectangle](rectCount)
  for i in 0..<rectCount:
    rects[i].x1 = nextInt(inputData, scanPos)
    rects[i].y1 = nextInt(inputData, scanPos)
    rects[i].x2 = nextInt(inputData, scanPos)
    rects[i].y2 = nextInt(inputData, scanPos)
  parents.setLen(rectCount)
  ranks.setLen(rectCount)
  for i in 0..<rectCount:
    parents[i] = i
    ranks[i] = 0
  rects.sort(compareRect)
  for i in 0..<rectCount:
    if i + 1 >= rectCount: break
    for j in i + 1..<rectCount:
      if rects[j].x1 > rects[i].x2: break
      if rects[j].y1 <= rects[i].y2 and rects[i].y1 <= rects[j].y2:
        let verticalOverlap = min(rects[i].y2, rects[j].y2) - max(rects[i].y1, rects[j].y1)
        let horizontalOverlap = min(rects[i].x2, rects[j].x2) - max(rects[i].x1, rects[j].x1)
        if verticalOverlap > 0 or horizontalOverlap > 0:
          unite(i, j)
  var blockCount = 0
  for i in 0..<rectCount:
    if parents[i] == i: blockCount += 1
  appendOutput($blockCount)

stdout.write outputBuffer
outputBuffer.setLen 0
