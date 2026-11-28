const flushBlockBytes = 1 shl 17
const trackCount = 3
const firstDigitValue = 48
const negativeInfinite = -1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0

proc nextInt(): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

let initialTrack = nextInt() - 1
let initialEnergy = nextInt()
let levelCount = nextInt()

var hurdles = newSeq[seq[int]](trackCount)
for trackIndex in 0 .. trackCount - 1:
  hurdles[trackIndex] = newSeq[int](levelCount)
  for levelIndex in 0 .. levelCount - 1:
    hurdles[trackIndex][levelIndex] = nextInt()

let gapCount = levelCount - 1
var leftDrink = newSeq[int](gapCount)
var rightDrink = newSeq[int](gapCount)
for gapIndex in 0 .. gapCount - 1:
  leftDrink[gapIndex] = nextInt()
for gapIndex in 0 .. gapCount - 1:
  rightDrink[gapIndex] = nextInt()

var bestEnergy = newSeq[int](trackCount)
for trackIndex in 0 .. trackCount - 1:
  bestEnergy[trackIndex] = negativeInfinite
bestEnergy[initialTrack] = initialEnergy

var parentTrack = newSeq[int]((levelCount + 1) * trackCount)
var parentMovedRight = newSeq[bool]((levelCount + 1) * trackCount)
for cellIndex in 0 .. parentTrack.len - 1:
  parentTrack[cellIndex] = -1

for gapIndex in 0 .. levelCount - 1:
  var nextEnergy = newSeq[int](trackCount)
  for trackIndex in 0 .. trackCount - 1:
    nextEnergy[trackIndex] = negativeInfinite
  for sourceTrack in 0 .. trackCount - 1:
    if bestEnergy[sourceTrack] <= 0:
      continue
    for targetTrack in 0 .. trackCount - 1:
      var energy = bestEnergy[sourceTrack]
      var movedRight = targetTrack > sourceTrack
      var stepCount = targetTrack - sourceTrack
      if stepCount < 0:
        stepCount = -stepCount
      var stepIndex = 0
      var valid = true
      while stepIndex < stepCount:
        if gapIndex > 0:
          let boundary = if movedRight: sourceTrack + stepIndex else: sourceTrack - 1 - stepIndex
          if boundary == 0:
            energy += leftDrink[gapIndex - 1]
          else:
            energy += rightDrink[gapIndex - 1]
        if energy <= 0:
          valid = false
          break
        stepIndex += 1
      if not valid:
        continue
      energy -= hurdles[targetTrack][gapIndex]
      if energy <= 0:
        continue
      if energy > nextEnergy[targetTrack]:
        nextEnergy[targetTrack] = energy
        let cellIndex = (gapIndex + 1) * trackCount + targetTrack
        parentTrack[cellIndex] = sourceTrack
        parentMovedRight[cellIndex] = movedRight
  bestEnergy = nextEnergy

var finalTrack = 0
for trackIndex in 1 .. trackCount - 1:
  if bestEnergy[trackIndex] > bestEnergy[finalTrack]:
    finalTrack = trackIndex

if bestEnergy[finalTrack] <= 0:
  appendOutput("GAME OVER!\n")
else:
  var moveGroups = newSeq[string](levelCount)
  var currentTrack = finalTrack
  var gapIndex = levelCount - 1
  while gapIndex >= 0:
    let cellIndex = (gapIndex + 1) * trackCount + currentTrack
    let sourceTrack = parentTrack[cellIndex]
    var group = ""
    if sourceTrack == currentTrack:
      group.add 'U'
    else:
      let stepChar = if parentMovedRight[cellIndex]: 'R' else: 'L'
      var stepIndex = 0
      while stepIndex < abs(currentTrack - sourceTrack):
        group.add stepChar
        stepIndex += 1
    moveGroups[gapIndex] = group
    currentTrack = sourceTrack
    gapIndex -= 1
  appendOutput("DONE IT!\n")
  appendOutput(moveGroups[0])
  for gapIndex in 1 .. levelCount - 1:
    appendOutput("-")
    appendOutput(moveGroups[gapIndex])
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
