{.push checks: off.}
{.passC: "-O2".}
import std/algorithm
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const rinkExtent = 10000
const infinity = 65535

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""
var sweepStarts = newSeq[seq[int]](rinkExtent + 1)
var sweepEnds = newSeq[seq[int]](rinkExtent + 1)
var touchedLines: seq[int] = @[]

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type
  Solver = object
    px: seq[int]
    py: seq[int]
    nextVertex: seq[int]
    prevVertex: seq[int]
    landing: array[2, seq[int]]
    startX, startY, finishX, finishY: int
    vertexCount: int
    depth: int
    seen: seq[int]
    answer: int

proc isLeft(solver: Solver, xOne, yOne, xTwo, yTwo, pointX, pointY: int): bool =
  int64(yOne - pointY) * int64(xTwo - xOne) < int64(yOne - yTwo) * int64(pointX - xOne)

proc isRightCorner(solver: Solver, vertex, pointX, pointY: int): bool =
  let after = solver.nextVertex[vertex]
  let before = solver.prevVertex[vertex]
  let first = solver.px[vertex] == pointX and solver.py[vertex] == pointY and
    not solver.isLeft(solver.px[before], solver.py[before], solver.px[vertex], solver.py[vertex],
                      solver.px[after], solver.py[after])
  let second = solver.px[after] == pointX and solver.py[after] == pointY and
    not solver.isLeft(solver.px[vertex], solver.py[vertex], solver.px[after], solver.py[after],
                      solver.px[solver.nextVertex[after]], solver.py[solver.nextVertex[after]])
  return first or second

proc addQueue(solver: var Solver, dirIndex, vertex: int, qOne: var seq[int], qTwo: var seq[int]) =
  if vertex == 0:
    return
  if solver.seen[vertex] <= solver.depth + dirIndex:
    return
  solver.seen[vertex] = solver.depth + dirIndex
  if dirIndex == 1:
    qOne.add vertex
  else:
    qTwo.add vertex

proc routeX(solver: var Solver, dirRight: bool, state, landing: int,
            qOne: var seq[int], qTwo: var seq[int]) =
  if solver.py[state] == solver.finishY:
    var edgeX = solver.px[state]
    let otherX = solver.px[solver.nextVertex[state]]
    if (edgeX > otherX) == dirRight:
      edgeX = otherX
    if dirRight:
      if solver.finishX > edgeX and (landing == 0 or solver.finishX <= solver.px[landing]):
        solver.answer = solver.depth + 1
        return
    elif solver.finishX < edgeX and (landing == 0 or solver.finishX >= solver.px[landing]):
      solver.answer = solver.depth + 1
      return
  if landing == 0:
    return
  solver.addQueue(1, landing, qOne, qTwo)
  if solver.py[landing] == solver.py[state]:
    solver.addQueue(1, solver.prevVertex[landing], qOne, qTwo)
  elif solver.py[solver.nextVertex[landing]] == solver.py[state]:
    solver.addQueue(1, solver.nextVertex[landing], qOne, qTwo)
  if (solver.px[state] < solver.px[solver.nextVertex[state]]) == dirRight:
    solver.addQueue(2, solver.nextVertex[state], qOne, qTwo)
  else:
    solver.addQueue(2, solver.prevVertex[state], qOne, qTwo)

proc routeY(solver: var Solver, dirDown: bool, state, landing: int,
            qOne: var seq[int], qTwo: var seq[int]) =
  if solver.px[state] == solver.finishX:
    var edgeY = solver.py[state]
    let otherY = solver.py[solver.nextVertex[state]]
    if (edgeY > otherY) == dirDown:
      edgeY = otherY
    if dirDown:
      if solver.finishY > edgeY and (landing == 0 or solver.finishY <= solver.py[landing]):
        solver.answer = solver.depth + 1
        return
    elif solver.finishY < edgeY and (landing == 0 or solver.finishY >= solver.py[landing]):
      solver.answer = solver.depth + 1
      return
  if landing == 0:
    return
  solver.addQueue(1, landing, qOne, qTwo)
  if solver.px[landing] == solver.px[state]:
    solver.addQueue(1, solver.prevVertex[landing], qOne, qTwo)
  elif solver.px[solver.nextVertex[landing]] == solver.px[state]:
    solver.addQueue(1, solver.nextVertex[landing], qOne, qTwo)
  if (solver.py[state] > solver.py[solver.nextVertex[state]]) == dirDown:
    solver.addQueue(2, solver.prevVertex[state], qOne, qTwo)
  else:
    solver.addQueue(2, solver.nextVertex[state], qOne, qTwo)

proc solveCase(startX, startY, finishX, finishY: int, pointXs, pointYs, begins: seq[int]): int =
  var solver = Solver(
    px: @[startX], py: @[startY], nextVertex: @[0], prevVertex: @[0],
    landing: [@[0], @[0]],
    startX: startX, startY: startY, finishX: finishX, finishY: finishY,
    vertexCount: 0, depth: 0, answer: -1, seen: @[]
  )
  var count = 0
  for k in 0..<begins.len:
    let first = begins[k]
    let last = if k + 1 < begins.len: begins[k + 1] else: pointXs.len
    let wallTotal = last - first
    if pointXs[first] != pointXs[first + 1]:
      solver.px.add pointXs[last - 1]
      solver.py.add pointYs[last - 1]
      solver.px.add pointXs[first]
      solver.py.add pointYs[first]
      solver.px.add pointXs[first + 1]
      solver.py.add pointYs[first + 1]
      for j in 4..wallTotal:
        solver.px.add pointXs[first + j - 2]
        solver.py.add pointYs[first + j - 2]
      count += wallTotal
    else:
      solver.px.add pointXs[first]
      solver.py.add pointYs[first]
      solver.px.add pointXs[first + 1]
      solver.py.add pointYs[first + 1]
      for j in 3..wallTotal:
        solver.px.add pointXs[first + j - 1]
        solver.py.add pointYs[first + j - 1]
      count += wallTotal
    for j in count - wallTotal + 1..<count:
      solver.nextVertex.add j + 1
    solver.nextVertex.add count - wallTotal + 1

  solver.vertexCount = count
  solver.nextVertex.setLen(count + 1)
  solver.prevVertex.setLen(count + 1)
  for i in 0..count:
    solver.prevVertex[solver.nextVertex[i]] = i
  solver.landing[0].setLen(count + 1)
  solver.landing[1].setLen(count + 1)
  for i in 0..count:
    solver.landing[0][i] = 0
    solver.landing[1][i] = 0
  solver.seen = newSeq[int](count + 1)
  for i in 0..count:
    solver.seen[i] = infinity

  var qOne: seq[int] = @[]
  var qTwo: seq[int] = @[]

  type Tree = object
    bit: seq[int]
    leaf: seq[int]
  proc treeAdd(tree: var Tree, coord, value: int) =
    tree.leaf[coord] = value
    var idx = coord + 1
    while idx <= rinkExtent + 1:
      tree.bit[idx] += 1
      idx += idx and (-idx)
  proc treeDel(tree: var Tree, coord: int) =
    tree.leaf[coord] = 0
    var idx = coord + 1
    while idx <= rinkExtent + 1:
      tree.bit[idx] -= 1
      idx += idx and (-idx)
  proc treeSum(tree: Tree, coord: int): int =
    var idx = coord + 1
    var total = 0
    while idx > 0:
      total += tree.bit[idx]
      idx -= idx and (-idx)
    return total
  proc treeFind(tree: Tree, pos: int, dirRight: bool): int =
    if dirRight:
      let before = treeSum(tree, pos)
      let total = treeSum(tree, rinkExtent)
      if before == total:
        return 0
      var order = before + 1
      var idx = 0
      var step = 1
      while step shl 1 <= rinkExtent + 1:
        step = step shl 1
      while step > 0:
        let candidate = idx + step
        if candidate <= rinkExtent + 1 and tree.bit[candidate] < order:
          idx = candidate
          order -= tree.bit[candidate]
        step = step div 2
      return tree.leaf[idx]
    else:
      let before = treeSum(tree, pos - 1)
      if before == 0:
        return 0
      var order = before
      var idx = 0
      var step = 1
      while step shl 1 <= rinkExtent + 1:
        step = step shl 1
      while step > 0:
        let candidate = idx + step
        if candidate <= rinkExtent + 1 and tree.bit[candidate] < order:
          idx = candidate
          order -= tree.bit[candidate]
        step = step div 2
      return tree.leaf[idx]

  for sweepVertical in [true, false]:
    var tree = Tree(bit: newSeq[int](rinkExtent + 2), leaf: newSeq[int](rinkExtent + 1))
    for line in touchedLines:
      sweepStarts[line].setLen 0
      sweepEnds[line].setLen 0
    touchedLines.setLen 0
    for q in 1..solver.vertexCount:
      if (q mod 2 == 1) != sweepVertical:
        continue
      let after = solver.nextVertex[q]
      let firstCoord = if sweepVertical: solver.py[q] else: solver.px[q]
      let secondCoord = if sweepVertical: solver.py[after] else: solver.px[after]
      let low = min(firstCoord, secondCoord)
      let high = max(firstCoord, secondCoord)
      if sweepStarts[low].len == 0:
        touchedLines.add low
      if sweepEnds[high].len == 0:
        touchedLines.add high
      sweepStarts[low].add q
      sweepEnds[high].add q

    let specialLine = if sweepVertical: startY else: startX
    var eventLines: seq[int] = @[specialLine]
    for line in touchedLines:
      eventLines.add line
    eventLines.sort(proc (a, b: int): int = cmp(a, b))
    var previousLine = -1

    for line in eventLines:
      if line == previousLine:
        continue
      previousLine = line
      for q in sweepStarts[line]:
        let coord = if sweepVertical: solver.px[q] else: solver.py[q]
        treeAdd(tree, coord, q)
      if sweepVertical and line == startY:
        var j = treeFind(tree, startX + 1, false)
        if j != 0 and solver.isRightCorner(j, startX, startY):
          j = treeFind(tree, solver.px[j], false)
        if j != 0 and solver.py[j] < solver.py[solver.nextVertex[j]]:
          j = treeFind(tree, solver.px[j], false)
        solver.routeX(false, 0, j, qOne, qTwo)
        j = treeFind(tree, startX - 1, true)
        if j != 0 and solver.isRightCorner(j, startX, startY):
          j = treeFind(tree, solver.px[j], true)
        if j != 0 and solver.py[j] > solver.py[solver.nextVertex[j]]:
          j = treeFind(tree, solver.px[j], true)
        solver.routeX(true, 0, j, qOne, qTwo)
      if (not sweepVertical) and line == startX:
        var j = treeFind(tree, startY + 1, false)
        if j != 0 and solver.isRightCorner(j, startX, startY):
          j = treeFind(tree, solver.py[j], false)
        if j != 0 and solver.px[j] > solver.px[solver.nextVertex[j]]:
          j = treeFind(tree, solver.py[j], false)
        solver.routeY(false, 0, j, qOne, qTwo)
        j = treeFind(tree, startY - 1, true)
        if j != 0 and solver.isRightCorner(j, startX, startY):
          j = treeFind(tree, solver.py[j], true)
        if j != 0 and solver.px[j] < solver.px[solver.nextVertex[j]]:
          j = treeFind(tree, solver.py[j], true)
        solver.routeY(true, 0, j, qOne, qTwo)

      for kk in 0..1:
        let bucket = if kk == 0: sweepStarts[line] else: sweepEnds[line]
        for q in bucket:
          if sweepVertical:
            if solver.py[q] == line:
              solver.landing[1][solver.prevVertex[q]] = treeFind(tree, solver.px[q], solver.py[q] > solver.py[solver.nextVertex[q]])
            else:
              solver.landing[0][solver.nextVertex[q]] = treeFind(tree, solver.px[q], solver.py[q] > solver.py[solver.nextVertex[q]])
          else:
            if solver.px[q] == line:
              solver.landing[1][solver.prevVertex[q]] = treeFind(tree, solver.py[q], solver.px[q] < solver.px[solver.nextVertex[q]])
            else:
              solver.landing[0][solver.nextVertex[q]] = treeFind(tree, solver.py[q], solver.px[q] < solver.px[solver.nextVertex[q]])
      for q in sweepEnds[line]:
        let coord = if sweepVertical: solver.px[q] else: solver.py[q]
        if tree.leaf[coord] == q:
          treeDel(tree, coord)
      if solver.answer >= 0:
        return solver.answer

  for i in 1..solver.vertexCount:
    if solver.isLeft(solver.px[solver.prevVertex[i]], solver.py[solver.prevVertex[i]], solver.px[i], solver.py[i],
                     solver.px[solver.nextVertex[i]], solver.py[solver.nextVertex[i]]):
      solver.landing[1][solver.prevVertex[i]] = i
      solver.landing[0][i] = solver.prevVertex[i]

  while true:
    solver.depth += 1
    var qZero = qOne
    qOne = qTwo
    qTwo = @[]
    for state in qZero:
      if state mod 2 == 1:
        solver.routeY(solver.py[state] > solver.py[solver.nextVertex[state]], state, solver.landing[0][state], qOne, qTwo)
        solver.routeY(solver.py[state] < solver.py[solver.nextVertex[state]], state, solver.landing[1][state], qOne, qTwo)
      else:
        solver.routeX(solver.px[state] > solver.px[solver.nextVertex[state]], state, solver.landing[0][state], qOne, qTwo)
        solver.routeX(solver.px[state] < solver.px[solver.nextVertex[state]], state, solver.landing[1][state], qOne, qTwo)
      if solver.answer >= 0:
        return solver.answer
    if qOne.len == 0 and qTwo.len == 0:
      return -1

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0..<caseCount:
  let startX = nextInt(inputData, scanPos)
  let startY = nextInt(inputData, scanPos)
  let finishX = nextInt(inputData, scanPos)
  let finishY = nextInt(inputData, scanPos)
  let obstacleCount = nextInt(inputData, scanPos)
  var pointXs: seq[int] = @[]
  var pointYs: seq[int] = @[]
  var begins: seq[int] = @[]
  for k in 0..<obstacleCount:
    begins.add pointXs.len
    let wallCount = nextInt(inputData, scanPos)
    for l in 0..<wallCount:
      pointXs.add nextInt(inputData, scanPos)
      pointYs.add nextInt(inputData, scanPos)
  let answer = solveCase(startX, startY, finishX, finishY, pointXs, pointYs, begins)
  if answer < 0:
    appendOutput("NO")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
