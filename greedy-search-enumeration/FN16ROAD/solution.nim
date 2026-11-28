import strutils

const flushBlockBytes = 1 shl 17
const solverEpsilon = 1e-9
const infiniteRatio = 1e100

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

proc hasMoreData(data: string, pos: var int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9') and data[probe] != '-':
    probe += 1
  if probe < data.len:
    pos = probe
    return true
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc rebuildObjective(tableau: var seq[seq[float64]], basis: seq[int], cost: seq[float64]) =
  let constraintCount = basis.len
  let variableCount = cost.len
  let objectiveRow = constraintCount
  for columnIndex in 0 .. variableCount:
    tableau[objectiveRow][columnIndex] = 0.0
  for rowIndex in 0 .. constraintCount - 1:
    let factor = cost[basis[rowIndex]]
    if abs(factor) > solverEpsilon:
      for columnIndex in 0 .. variableCount:
        tableau[objectiveRow][columnIndex] += factor * tableau[rowIndex][columnIndex]
  for columnIndex in 0 .. variableCount - 1:
    tableau[objectiveRow][columnIndex] -= cost[columnIndex]

proc formatBound(value: float64): string =
  var text = formatFloat(value, ffDecimal, 6)
  while text.len > 2 and text[text.len - 1] == '0' and text[text.len - 2] != '.':
    text.setLen(text.len - 1)
  return text

proc pivotTableau(tableau: var seq[seq[float64]], basis: var seq[int], rowIndex, columnIndex: int) =
  let variableCount = tableau[0].len - 1
  let pivotValue = tableau[rowIndex][columnIndex]
  for columnIndex in 0 .. variableCount:
    tableau[rowIndex][columnIndex] /= pivotValue
  for otherRow in 0 .. tableau.len - 1:
    if otherRow == rowIndex:
      continue
    let factor = tableau[otherRow][columnIndex]
    if abs(factor) > solverEpsilon:
      for columnIndex in 0 .. variableCount:
        tableau[otherRow][columnIndex] -= factor * tableau[rowIndex][columnIndex]
  basis[rowIndex] = columnIndex

proc clearArtificials(tableau: var seq[seq[float64]], basis: var seq[int], artificialStart: int) =
  for rowIndex in 0 .. basis.len - 1:
    if basis[rowIndex] >= artificialStart:
      var replacementColumn = -1
      for columnIndex in 0 .. artificialStart - 1:
        if abs(tableau[rowIndex][columnIndex]) > solverEpsilon:
          replacementColumn = columnIndex
          break
      if replacementColumn >= 0:
        pivotTableau(tableau, basis, rowIndex, replacementColumn)

proc optimize(tableau: var seq[seq[float64]], basis: var seq[int], cost: seq[float64],
              artificialStart: int): float64 =
  let constraintCount = basis.len
  let variableCount = cost.len
  rebuildObjective(tableau, basis, cost)
  var iterationCount = 0
  while iterationCount < 10000:
    var enteringColumn = -1
    for columnIndex in 0 .. variableCount - 1:
      if artificialStart >= 0 and columnIndex >= artificialStart:
        continue
      if tableau[constraintCount][columnIndex] < -solverEpsilon and
         (enteringColumn == -1 or columnIndex < enteringColumn):
        enteringColumn = columnIndex
    if enteringColumn == -1:
      break
    var leavingRow = -1
    var bestRatio = infiniteRatio
    for rowIndex in 0 .. constraintCount - 1:
      if tableau[rowIndex][enteringColumn] > solverEpsilon:
        let ratio = tableau[rowIndex][variableCount] / tableau[rowIndex][enteringColumn]
        if ratio < bestRatio - solverEpsilon or
           (abs(ratio - bestRatio) <= solverEpsilon and
            (leavingRow == -1 or basis[rowIndex] < basis[leavingRow])):
          bestRatio = ratio
          leavingRow = rowIndex
    if leavingRow == -1:
      break
    pivotTableau(tableau, basis, leavingRow, enteringColumn)
    iterationCount += 1
  return tableau[constraintCount][variableCount]

while hasMoreData(inputData, scanPos):
  let cityCount = nextInt(inputData, scanPos)
  var directDistance = newSeq[seq[int]](cityCount)
  var edgeIdentity = newSeq[seq[int]](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    directDistance[cityIndex] = newSeq[int](cityCount)
    edgeIdentity[cityIndex] = newSeq[int](cityCount)
    for otherIndex in 0 .. cityCount - 1:
      directDistance[cityIndex][otherIndex] = nextInt(inputData, scanPos)
      edgeIdentity[cityIndex][otherIndex] = -1
  var edgeFrom: seq[int] = @[]
  var edgeTo: seq[int] = @[]
  var edgeLength: seq[int] = @[]
  for cityIndex in 0 .. cityCount - 1:
    for otherIndex in 0 .. cityCount - 1:
      let roadLength = directDistance[cityIndex][otherIndex]
      if roadLength > 0:
        edgeIdentity[cityIndex][otherIndex] = edgeFrom.len
        edgeFrom.add cityIndex
        edgeTo.add otherIndex
        edgeLength.add roadLength
  let edgeCount = edgeFrom.len
  var shortestDistance = newSeq[seq[int64]](cityCount)
  var nextHop = newSeq[seq[int]](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    shortestDistance[cityIndex] = newSeq[int64](cityCount)
    nextHop[cityIndex] = newSeq[int](cityCount)
    for otherIndex in 0 .. cityCount - 1:
      if cityIndex == otherIndex:
        shortestDistance[cityIndex][otherIndex] = 0
        nextHop[cityIndex][otherIndex] = otherIndex
      elif directDistance[cityIndex][otherIndex] > 0:
        shortestDistance[cityIndex][otherIndex] = int64(directDistance[cityIndex][otherIndex])
        nextHop[cityIndex][otherIndex] = otherIndex
      else:
        shortestDistance[cityIndex][otherIndex] = int64(1000000000)
        nextHop[cityIndex][otherIndex] = -1
  for viaCity in 0 .. cityCount - 1:
    for sourceCity in 0 .. cityCount - 1:
      for targetCity in 0 .. cityCount - 1:
        let candidate = shortestDistance[sourceCity][viaCity] + shortestDistance[viaCity][targetCity]
        if candidate < shortestDistance[sourceCity][targetCity]:
          shortestDistance[sourceCity][targetCity] = candidate
          nextHop[sourceCity][targetCity] = nextHop[sourceCity][viaCity]

  proc routeEdges(sourceCity: int, targetCity: int): seq[int] =
    var route: seq[int] = @[]
    var currentCity = sourceCity
    while currentCity != targetCity:
      let nextCity = nextHop[currentCity][targetCity]
      if nextCity == -1:
        break
      route.add edgeIdentity[currentCity][nextCity]
      currentCity = nextCity
    return route

  let observedCount = nextInt(inputData, scanPos)
  var artificialStart = 2 * edgeCount
  let variableCount = artificialStart + observedCount
  var tableau: seq[seq[float64]] = @[]
  var basis: seq[int] = @[]
  for edgeIndex in 0 .. edgeCount - 1:
    var row = newSeq[float64](variableCount + 1)
    row[edgeIndex] = 1.0
    row[edgeCount + edgeIndex] = 1.0
    row[variableCount] = float64(edgeLength[edgeIndex])
    tableau.add row
    basis.add edgeCount + edgeIndex
  for observedIndex in 0 .. observedCount - 1:
    let sourceCity = nextInt(inputData, scanPos)
    let targetCity = nextInt(inputData, scanPos)
    let observedMinutes = nextInt(inputData, scanPos)
    let route = routeEdges(sourceCity, targetCity)
    var row = newSeq[float64](variableCount + 1)
    var minimumMinutes: int64 = 0
    for edgeIndex in route:
      row[edgeIndex] = 1.0
      minimumMinutes += int64(edgeLength[edgeIndex])
    row[artificialStart + observedIndex] = 1.0
    row[variableCount] = float64(observedMinutes) - float64(minimumMinutes)
    tableau.add row
    basis.add artificialStart + observedIndex
  tableau.add newSeq[float64](variableCount + 1)
  var phaseCost = newSeq[float64](variableCount)
  for variableIndex in artificialStart .. variableCount - 1:
    phaseCost[variableIndex] = -1.0
  discard optimize(tableau, basis, phaseCost, -1)
  clearArtificials(tableau, basis, artificialStart)

  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let sourceCity = nextInt(inputData, scanPos)
    let targetCity = nextInt(inputData, scanPos)
    let route = routeEdges(sourceCity, targetCity)
    var routeBase: float64 = 0.0
    var objective = newSeq[float64](variableCount)
    for edgeIndex in route:
      objective[edgeIndex] = 1.0
      routeBase += float64(edgeLength[edgeIndex])
    let highExcess = optimize(tableau, basis, objective, artificialStart)
    for edgeIndex in route:
      objective[edgeIndex] = -1.0
    let negatedLowExcess = optimize(tableau, basis, objective, artificialStart)
    let highValue = routeBase + highExcess
    var lowValue = routeBase - negatedLowExcess
    if abs(lowValue) < solverEpsilon:
      lowValue = 0.0
    appendOutput($sourceCity & " " & $targetCity & " " & formatBound(lowValue) &
                 " " & formatBound(highValue) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
