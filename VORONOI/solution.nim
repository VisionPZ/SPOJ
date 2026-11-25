import math
import algorithm

const flushBlockBytes = 1 shl 17
const maxLetters = 26

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
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var currentWidth = 0
var currentHeight = 0
var cellCount = 0
var wordCount = 0
var maxDistance = 0
var distanceTable: seq[uint8]
var lessMasks: seq[uint64]
var lessEqualMasks: seq[uint64]
var fullMasks: seq[uint64]
var cellLetters: seq[seq[int]]
var letterOrder: seq[int]
var candidateMasks: seq[seq[uint64]]
var chosenSites: seq[int]

proc allDistances() =
  distanceTable = newSeq[uint8](cellCount * cellCount)
  for row in 0 .. currentHeight - 1:
    for column in 0 .. currentWidth - 1:
      let firstCell = row * currentWidth + column
      for otherRow in 0 .. currentHeight - 1:
        for otherColumn in 0 .. currentWidth - 1:
          let secondCell = otherRow * currentWidth + otherColumn
          let manhattan = abs(row - otherRow) + abs(column - otherColumn)
          distanceTable[firstCell * cellCount + secondCell] = uint8(manhattan)

proc buildMasks() =
  lessMasks = newSeq[uint64](cellCount * (maxDistance + 1) * wordCount)
  lessEqualMasks = newSeq[uint64](cellCount * (maxDistance + 1) * wordCount)
  fullMasks = newSeq[uint64](wordCount)
  for wordIndex in 0 .. wordCount - 1:
    fullMasks[wordIndex] = 0xFFFFFFFFFFFFFFFF'u64
  let remainder = cellCount mod 64
  if remainder != 0:
    fullMasks[wordCount - 1] = (uint64(1) shl remainder) - 1'u64
  for firstCell in 0 .. cellCount - 1:
    var buckets = newSeq[seq[int]](maxDistance + 1)
    for distanceValue in 0 .. maxDistance:
      buckets[distanceValue] = newSeq[int](0)
    for secondCell in 0 .. cellCount - 1:
      let distanceValue = int(distanceTable[firstCell * cellCount + secondCell])
      buckets[distanceValue].add secondCell
    var accumulated = newSeq[uint64](wordCount)
    for distanceValue in 0 .. maxDistance:
      let baseIndex = (firstCell * (maxDistance + 1) + distanceValue) * wordCount
      for wordIndex in 0 .. wordCount - 1:
        lessMasks[baseIndex + wordIndex] = accumulated[wordIndex]
      for secondCell in buckets[distanceValue]:
        accumulated[secondCell div 64] = accumulated[secondCell div 64] or
          (uint64(1) shl (secondCell mod 64))
      for wordIndex in 0 .. wordCount - 1:
        lessEqualMasks[baseIndex + wordIndex] = accumulated[wordIndex]

proc searchSites(letterPosition: int): bool =
  if letterPosition == letterOrder.len:
    return true
  let currentLetter = letterOrder[letterPosition]
  var chosenWord = 0
  while chosenWord < wordCount:
    var candidateWord = candidateMasks[currentLetter][chosenWord]
    while candidateWord != 0'u64:
      var probeWord = candidateWord
      var trailingBits = 0
      while (probeWord and 1'u64) == 0'u64:
        probeWord = probeWord shr 1
        trailingBits += 1
      let siteCell = chosenWord * 64 + trailingBits
      candidateWord = candidateWord and (candidateWord - 1'u64)
      var greaterMask = newSeq[uint64](wordCount)
      var lesserMask = newSeq[uint64](wordCount)
      for wordIndex in 0 .. wordCount - 1:
        greaterMask[wordIndex] = fullMasks[wordIndex]
        lesserMask[wordIndex] = fullMasks[wordIndex]
      for pixelCell in cellLetters[currentLetter]:
        let distanceValue = int(distanceTable[pixelCell * cellCount + siteCell])
        let baseIndex = (pixelCell * (maxDistance + 1) + distanceValue) * wordCount
        for wordIndex in 0 .. wordCount - 1:
          greaterMask[wordIndex] = greaterMask[wordIndex] and
            (fullMasks[wordIndex] xor lessMasks[baseIndex + wordIndex])
          lesserMask[wordIndex] = lesserMask[wordIndex] and
            (fullMasks[wordIndex] xor lessEqualMasks[baseIndex + wordIndex])
      var savedMasks = newSeq[seq[uint64]](letterOrder.len - letterPosition - 1)
      var feasible = true
      var futureIndex = 0
      for futurePosition in letterPosition + 1 .. letterOrder.len - 1:
        let futureLetter = letterOrder[futurePosition]
        var boundaryMask = newSeq[uint64](wordCount)
        for wordIndex in 0 .. wordCount - 1:
          if futureLetter > currentLetter:
            boundaryMask[wordIndex] = greaterMask[wordIndex]
          else:
            boundaryMask[wordIndex] = lesserMask[wordIndex]
        for pixelCell in cellLetters[futureLetter]:
          let distanceValue = int(distanceTable[pixelCell * cellCount + siteCell])
          let baseIndex = (pixelCell * (maxDistance + 1) + distanceValue) * wordCount
          for wordIndex in 0 .. wordCount - 1:
            if currentLetter < futureLetter:
              boundaryMask[wordIndex] = boundaryMask[wordIndex] and
                lessMasks[baseIndex + wordIndex]
            else:
              boundaryMask[wordIndex] = boundaryMask[wordIndex] and
                lessEqualMasks[baseIndex + wordIndex]
        var hasCandidate = false
        savedMasks[futureIndex] = candidateMasks[futureLetter]
        futureIndex += 1
        for wordIndex in 0 .. wordCount - 1:
          candidateMasks[futureLetter][wordIndex] = candidateMasks[futureLetter][wordIndex] and
            boundaryMask[wordIndex]
          if candidateMasks[futureLetter][wordIndex] != 0'u64:
            hasCandidate = true
        if not hasCandidate:
          feasible = false
          break
      if feasible:
        chosenSites[currentLetter] = siteCell
        if searchSites(letterPosition + 1):
          return true
      for undoIndex in 0 .. futureIndex - 1:
        let undoLetter = letterOrder[letterPosition + 1 + undoIndex]
        candidateMasks[undoLetter] = savedMasks[undoIndex]
    chosenWord += 1
  return false

var caseNumber = 0
while true:
  currentWidth = nextInt(inputData, scanPos)
  currentHeight = nextInt(inputData, scanPos)
  if currentWidth == 0 and currentHeight == 0:
    break
  caseNumber += 1
  cellCount = currentWidth * currentHeight
  wordCount = (cellCount + 63) div 64
  maxDistance = currentWidth + currentHeight - 2
  var diagram = newSeq[string](0)
  for row in 0 .. currentHeight - 1:
    diagram.add nextToken(inputData, scanPos)
  cellLetters = newSeq[seq[int]](maxLetters)
  for letterIndex in 0 .. maxLetters - 1:
    cellLetters[letterIndex] = newSeq[int](0)
  for row in 0 .. currentHeight - 1:
    for column in 0 .. currentWidth - 1:
      let letterIndex = int(diagram[row][column]) - 96
      cellLetters[letterIndex].add row * currentWidth + column
  letterOrder = newSeq[int](0)
  for letterIndex in 0 .. maxLetters - 1:
    if cellLetters[letterIndex].len > 0:
      letterOrder.add letterIndex
  letterOrder.sort(proc (left: int, right: int): int =
    if cellLetters[left].len < cellLetters[right].len: return -1
    if cellLetters[left].len > cellLetters[right].len: return 1
    return left - right)
  candidateMasks = newSeq[seq[uint64]](maxLetters)
  for letterIndex in 0 .. maxLetters - 1:
    candidateMasks[letterIndex] = newSeq[uint64](wordCount)
  for letterIndex in letterOrder:
    for pixelCell in cellLetters[letterIndex]:
      candidateMasks[letterIndex][pixelCell div 64] = candidateMasks[letterIndex][pixelCell div 64] or
        (uint64(1) shl (pixelCell mod 64))
  chosenSites = newSeq[int](maxLetters)
  for letterIndex in 0 .. maxLetters - 1:
    chosenSites[letterIndex] = -1
  allDistances()
  buildMasks()
  discard searchSites(0)
  appendOutput("Case " & $caseNumber & ":\n")
  for letterIndex in 0 .. maxLetters - 1:
    if chosenSites[letterIndex] < 0:
      continue
    let siteCell = chosenSites[letterIndex]
    appendOutput(chr(letterIndex + 96) & " " & $(siteCell mod currentWidth) & " " &
      $(siteCell div currentWidth) & "\n")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
