import math
import tables

const flushBlockBytes = 1 shl 17
const maxRodCount = 6
const sumKeyOffset = 2000
const sumKeyBase = 5000

type WireVector = tuple[dx: int, dy: int]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc buildOptions(length: int): seq[WireVector] =
  var candidates: seq[WireVector] = @[]
  for dxValue in -length .. length:
    let remainingSquare = length * length - dxValue * dxValue
    if remainingSquare < 0:
      continue
    let dyValue = int(sqrt(float(remainingSquare)))
    if dyValue * dyValue == remainingSquare:
      candidates.add((dxValue, dyValue))
      if dyValue != 0:
        candidates.add((dxValue, -dyValue))
  for candidateIndex in 0 .. candidates.high:
    let held = candidates[candidateIndex]
    let swapped = (held.dy, held.dx)
    var known = false
    for existing in candidates:
      if existing.dx == swapped[0] and existing.dy == swapped[1]:
        known = true
        break
    if not known:
      candidates.add(swapped)
  return candidates

proc halfPlane(value: WireVector): int =
  if value.dy > 0 or (value.dy == 0 and value.dx > 0):
    return 0
  return 1

proc vectorLess(first: WireVector, second: WireVector): bool =
  let firstHalf = halfPlane(first)
  let secondHalf = halfPlane(second)
  if firstHalf != secondHalf:
    return firstHalf < secondHalf
  return first.dx * second.dy - first.dy * second.dx > 0

proc sortVectors(values: var seq[WireVector]) =
  for rightIndex in 1 .. values.high:
    let held = values[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and vectorLess(held, values[leftIndex]):
      values[leftIndex + 1] = values[leftIndex]
      leftIndex -= 1
    values[leftIndex + 1] = held

proc sumKey(sumX: int, sumY: int): int =
  return (sumX + sumKeyOffset) * sumKeyBase + sumY + sumKeyOffset

var rodOptions: seq[seq[WireVector]] = @[]
var groupIndices: seq[int] = @[]
var groupCombos = initTable[int, seq[array[maxRodCount, int]]]()
var comboScratch: array[maxRodCount, int]
var bestAreaTwice = -1

proc storeCombo(sumX: int, sumY: int) =
  let key = sumKey(sumX, sumY)
  if not groupCombos.hasKey(key):
    groupCombos[key] = @[]
  groupCombos[key].add comboScratch

proc generateFirstGroup(position: int, sumX: int, sumY: int) =
  if position == groupIndices.len:
    storeCombo(sumX, sumY)
    return
  let rodIndex = groupIndices[position]
  for optionIndex in 0 .. rodOptions[rodIndex].high:
    let held = rodOptions[rodIndex][optionIndex]
    comboScratch[position] = optionIndex
    generateFirstGroup(position + 1, sumX + held.dx, sumY + held.dy)

proc evaluateCombo(firstCombo: array[maxRodCount, int], secondCombo: array[maxRodCount, int],
                   firstIndices: seq[int], secondIndices: seq[int]) =
  var vectors: seq[WireVector] = @[]
  for position in 0 .. firstIndices.high:
    vectors.add rodOptions[firstIndices[position]][firstCombo[position]]
  for position in 0 .. secondIndices.high:
    vectors.add rodOptions[secondIndices[position]][secondCombo[position]]
  sortVectors(vectors)
  var areaTwice = 0
  for firstIndex in 0 .. vectors.high:
    for secondIndex in firstIndex + 1 .. vectors.high:
      areaTwice = areaTwice + vectors[firstIndex].dx * vectors[secondIndex].dy -
                  vectors[firstIndex].dy * vectors[secondIndex].dx
  if areaTwice > bestAreaTwice:
    bestAreaTwice = areaTwice

var secondIndices: seq[int] = @[]
var secondScratch: array[maxRodCount, int]

proc generateSecondGroup(position: int, sumX: int, sumY: int) =
  if position == secondIndices.len:
    let key = sumKey(-sumX, -sumY)
    if groupCombos.hasKey(key):
      for firstCombo in groupCombos[key]:
        evaluateCombo(firstCombo, secondScratch, groupIndices, secondIndices)
    return
  let rodIndex = secondIndices[position]
  for optionIndex in 0 .. rodOptions[rodIndex].high:
    let held = rodOptions[rodIndex][optionIndex]
    secondScratch[position] = optionIndex
    generateSecondGroup(position + 1, sumX + held.dx, sumY + held.dy)

proc solveDataset(rodLengths: seq[int]): int =
  rodOptions = @[]
  for length in rodLengths:
    rodOptions.add buildOptions(length)
  let splitIndex = rodLengths.len div 2
  groupIndices = @[]
  secondIndices = @[]
  for rodIndex in 0 .. splitIndex - 1:
    groupIndices.add rodIndex
  for rodIndex in splitIndex .. rodLengths.high:
    secondIndices.add rodIndex
  groupCombos.clear()
  generateFirstGroup(0, 0, 0)
  bestAreaTwice = -1
  generateSecondGroup(0, 0, 0)
  if bestAreaTwice <= 0:
    return -1
  return bestAreaTwice div 2

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

while true:
  let rodCount = nextInt(inputData, scanPos)
  if rodCount == 0 or scanPos > inputData.len:
    break
  var rodLengths = newSeq[int](rodCount)
  for rodIndex in 0 .. rodCount - 1:
    rodLengths[rodIndex] = nextInt(inputData, scanPos)
  appendOutput($(solveDataset(rodLengths)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
