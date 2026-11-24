{.checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCoord = 10000

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

var dsuParent: seq[int] = @[]
var curFirst: seq[int] = @[]
var rootMark: seq[int] = @[]
var rootNewLabel: seq[int] = @[]
var yMark = newSeq[int](maxCoord + 1)
var yVersion = 0
var yList: seq[int] = @[]
var crossings: seq[int] = @[]
var curLo: seq[int] = @[]
var curHi: seq[int] = @[]
var vertX: seq[int] = @[]
var vertY: seq[int] = @[]
var edgeX: seq[int] = @[]
var edgeLo: seq[int] = @[]
var edgeHi: seq[int] = @[]
var prevLo: seq[int] = @[]
var prevHi: seq[int] = @[]
var prevComp: seq[int] = @[]

proc findRoot(value: int): int =
  var root = value
  while dsuParent[root] != root:
    root = dsuParent[root]
  var node = value
  while dsuParent[node] != node:
    let parentNode = dsuParent[node]
    dsuParent[node] = root
    node = parentNode
  return root

proc unionRoots(leftRoot, rightRoot: int): int =
  let leftFind = findRoot(leftRoot)
  let rightFind = findRoot(rightRoot)
  if leftFind == rightFind:
    return leftFind
  if leftFind < rightFind:
    dsuParent[rightFind] = leftFind
    return leftFind
  dsuParent[leftFind] = rightFind
  return rightFind

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let winX1 = nextInt(inputData, scanPos)
  let winY1 = nextInt(inputData, scanPos)
  let winX2 = nextInt(inputData, scanPos)
  let winY2 = nextInt(inputData, scanPos)
  let vertexCount = nextInt(inputData, scanPos)
  vertX.setLen(vertexCount)
  vertY.setLen(vertexCount)
  for i in 0..<vertexCount:
    vertX[i] = nextInt(inputData, scanPos)
    vertY[i] = nextInt(inputData, scanPos)
  let winLeft = if winX1 < winX2: winX1 else: winX2
  let winRight = if winX1 < winX2: winX2 else: winX1
  let winBottom = if winY1 < winY2: winY1 else: winY2
  let winTop = if winY1 < winY2: winY2 else: winY1
  if winLeft >= winRight or winBottom >= winTop:
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  yVersion += 1
  yList.setLen(0)
  for i in 0..<vertexCount:
    let vertexY = vertY[i]
    if vertexY >= winBottom and vertexY <= winTop:
      if yMark[vertexY] != yVersion:
        yMark[vertexY] = yVersion
        yList.add vertexY
  if yMark[winBottom] != yVersion:
    yMark[winBottom] = yVersion
    yList.add winBottom
  if yMark[winTop] != yVersion:
    yMark[winTop] = yVersion
    yList.add winTop
  for i in 1..<yList.len:
    let keyY = yList[i]
    var j = i - 1
    while j >= 0 and yList[j] > keyY:
      yList[j + 1] = yList[j]
      j -= 1
    yList[j + 1] = keyY
  edgeX.setLen(0)
  edgeLo.setLen(0)
  edgeHi.setLen(0)
  for i in 0..<vertexCount:
    let j = (i + 1) mod vertexCount
    if vertX[i] == vertX[j] and vertY[i] != vertY[j]:
      edgeX.add vertX[i]
      edgeLo.add (if vertY[i] < vertY[j]: vertY[i] else: vertY[j])
      edgeHi.add (if vertY[i] < vertY[j]: vertY[j] else: vertY[i])
  for i in 1..<edgeX.len:
    let keyX = edgeX[i]
    let keyLo = edgeLo[i]
    let keyHi = edgeHi[i]
    var j = i - 1
    while j >= 0 and edgeX[j] > keyX:
      edgeX[j + 1] = edgeX[j]
      edgeLo[j + 1] = edgeLo[j]
      edgeHi[j + 1] = edgeHi[j]
      j -= 1
    edgeX[j + 1] = keyX
    edgeLo[j + 1] = keyLo
    edgeHi[j + 1] = keyHi
  prevLo.setLen(0)
  prevHi.setLen(0)
  prevComp.setLen(0)
  var componentCount = 0
  var prevCompCount = 0
  for k in 0..<(yList.len - 1):
    let bandLow = yList[k]
    let bandHigh = yList[k + 1]
    crossings.setLen(0)
    var groupX = -1
    var groupCount = 0
    for l in 0..<edgeX.len:
      if edgeLo[l] <= bandLow and edgeHi[l] >= bandHigh:
        if edgeX[l] != groupX:
          if groupX >= 0 and groupCount mod 2 == 1:
            crossings.add groupX
          groupX = edgeX[l]
          groupCount = 0
        groupCount += 1
    if groupX >= 0 and groupCount mod 2 == 1:
      crossings.add groupX
    curLo.setLen(0)
    curHi.setLen(0)
    var crossPos = 0
    while crossPos + 1 < crossings.len:
      let leftCross = crossings[crossPos]
      let rightCross = crossings[crossPos + 1]
      let clippedLo = if leftCross > winLeft: leftCross else: winLeft
      let clippedHi = if rightCross < winRight: rightCross else: winRight
      if clippedLo < clippedHi:
        curLo.add clippedLo
        curHi.add clippedHi
      crossPos += 2
    let curCount = curLo.len
    dsuParent.setLen(prevCompCount)
    for i in 0..<prevCompCount:
      dsuParent[i] = i
    curFirst.setLen(curCount)
    for i in 0..<curCount:
      curFirst[i] = -1
    rootMark.setLen(prevCompCount)
    for i in 0..<prevCompCount:
      rootMark[i] = 0
    var i = 0
    var j = 0
    while i < prevLo.len and j < curCount:
      if max(prevLo[i], curLo[j]) < min(prevHi[i], curHi[j]):
        let prevLabel = prevComp[i]
        if rootMark[prevLabel] == 0:
          rootMark[prevLabel] = 1
        if curFirst[j] == -1:
          curFirst[j] = findRoot(prevLabel)
        else:
          curFirst[j] = unionRoots(curFirst[j], findRoot(prevLabel))
      if prevHi[i] < curHi[j]:
        i += 1
      else:
        j += 1
    var referencedCount = 0
    for i in 0..<prevCompCount:
      if rootMark[i] == 1:
        referencedCount += 1
    for i in 0..<prevCompCount:
      rootMark[i] = 0
    var usedRoots = 0
    var newStarts = 0
    for i in 0..<curCount:
      if curFirst[i] == -1:
        newStarts += 1
      else:
        let rootFound = findRoot(curFirst[i])
        if rootMark[rootFound] == 0:
          rootMark[rootFound] = 1
          usedRoots += 1
    componentCount = componentCount + newStarts - (referencedCount - usedRoots)
    rootNewLabel.setLen(prevCompCount)
    var nextLabel = 0
    for i in 0..<prevCompCount:
      if rootMark[i] == 1:
        rootNewLabel[i] = nextLabel
        nextLabel += 1
    prevLo.setLen(0)
    prevHi.setLen(0)
    prevComp.setLen(0)
    for i in 0..<curCount:
      var label = 0
      if curFirst[i] == -1:
        label = nextLabel
        nextLabel += 1
      else:
        label = rootNewLabel[findRoot(curFirst[i])]
      prevLo.add curLo[i]
      prevHi.add curHi[i]
      prevComp.add label
    prevCompCount = nextLabel
  appendOutput($(componentCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
