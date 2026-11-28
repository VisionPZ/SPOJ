const flushBlockBytes = 1 shl 17

proc hasMoreData(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendResistance(value: float) =
  let scaledValue = int(value * 100.0 + 0.5000001)
  let wholePart = scaledValue div 100
  let fractionPart = scaledValue mod 100
  appendOutput($wholePart)
  appendOutput(".")
  if fractionPart < 10:
    appendOutput("0")
  appendOutput($fractionPart)
  outputBuffer.add '\n'

while hasMoreData(inputData, scanPos):
  let nodeCount = nextInt(inputData, scanPos)
  let resistorCount = nextInt(inputData, scanPos)
  let systemSize = nodeCount - 1
  var system = newSeq[seq[float64]](systemSize)
  for rowIndex in 0 .. systemSize - 1:
    system[rowIndex] = newSeq[float64](systemSize + 1)
  for resistorIndex in 0 .. resistorCount - 1:
    let firstNode = nextInt(inputData, scanPos) - 1
    let secondNode = nextInt(inputData, scanPos) - 1
    let resistanceValue = nextInt(inputData, scanPos)
    if firstNode == secondNode:
      continue
    let conductance = 1.0 / float(resistanceValue)
    let firstIsGround = firstNode == nodeCount - 1
    let secondIsGround = secondNode == nodeCount - 1
    if not firstIsGround:
      system[firstNode][firstNode] += conductance
    if not secondIsGround:
      system[secondNode][secondNode] += conductance
    if not firstIsGround and not secondIsGround:
      system[firstNode][secondNode] -= conductance
      system[secondNode][firstNode] -= conductance
  system[0][systemSize] += 1.0
  for rowIndex in 0 .. systemSize - 1:
    var rowIsEmpty = true
    for columnIndex in 0 .. systemSize - 1:
      if system[rowIndex][columnIndex] != 0.0:
        rowIsEmpty = false
    if rowIsEmpty:
      system[rowIndex][rowIndex] = 1.0
  for columnIndex in 0 .. systemSize - 1:
    var pivotRow = columnIndex
    var pivotSize = abs(system[columnIndex][columnIndex])
    for rowIndex in columnIndex + 1 .. systemSize - 1:
      let candidateSize = abs(system[rowIndex][columnIndex])
      if candidateSize > pivotSize:
        pivotSize = candidateSize
        pivotRow = rowIndex
    if pivotRow != columnIndex:
      let temporaryRow = system[columnIndex]
      system[columnIndex] = system[pivotRow]
      system[pivotRow] = temporaryRow
    if system[columnIndex][columnIndex] == 0.0:
      continue
    let pivotValue = system[columnIndex][columnIndex]
    for rowIndex in columnIndex + 1 .. systemSize - 1:
      let eliminationFactor = system[rowIndex][columnIndex] / pivotValue
      if eliminationFactor == 0.0:
        continue
      system[rowIndex][columnIndex] = 0.0
      for innerColumn in columnIndex + 1 .. systemSize:
        system[rowIndex][innerColumn] -= eliminationFactor * system[columnIndex][innerColumn]
  var potentials = newSeq[float64](systemSize)
  for rowIndex in countdown(systemSize - 1, 0):
    if system[rowIndex][rowIndex] == 0.0:
      potentials[rowIndex] = 0.0
      continue
    var rowTotal = system[rowIndex][systemSize]
    for columnIndex in rowIndex + 1 .. systemSize - 1:
      rowTotal -= system[rowIndex][columnIndex] * potentials[columnIndex]
    potentials[rowIndex] = rowTotal / system[rowIndex][rowIndex]
  appendResistance(potentials[0])

stdout.write outputBuffer
outputBuffer.setLen 0
