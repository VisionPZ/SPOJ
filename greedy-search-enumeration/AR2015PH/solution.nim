const flushBlockBytes = 1 shl 17
const lowestCenti = 250
const highestCenti = 400
const maxSlabWidth = 149
const maxPercent = 100

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

while true:
  let studentCount = nextInt(inputData, scanPos)
  let totalUnits = nextInt(inputData, scanPos)
  if studentCount == 0 and totalUnits == 0:
    break
  var scoreCounts = newSeq[int](highestCenti + 1)
  for studentIndex in 0 .. studentCount - 1:
    let wholePart = nextInt(inputData, scanPos)
    let fractionPart = nextInt(inputData, scanPos)
    let scoreValue = wholePart * 100 + fractionPart
    if scoreValue >= 0 and scoreValue <= highestCenti:
      scoreCounts[scoreValue] = scoreCounts[scoreValue] + 1

  var allocationCount: int64 = 0
  for slabWidth in 0 .. maxSlabWidth:
    let slabStep = slabWidth + 1
    var residueCounts = newSeq[int](slabStep)
    var activeStudents = 0
    var indexSum: int64 = 0
    residueCounts[highestCenti mod slabStep] = scoreCounts[highestCenti]
    activeStudents = scoreCounts[highestCenti]
    for lowestStart in countdown(highestCenti, lowestCenti):
      let slabCount = (highestCenti - lowestStart) div slabStep + 1
      if slabCount >= 2 and activeStudents > 0:
        let maxStepSize = min(maxPercent, (maxPercent - 1) div (slabCount - 1))
        for stepSize in 1 .. maxStepSize:
          let remainingUnits = int64(totalUnits) - int64(stepSize) * indexSum
          if remainingUnits <= 0:
            break
          if remainingUnits mod int64(activeStudents) != 0:
            continue
          let basePercent = remainingUnits div int64(activeStudents)
          if basePercent >= 1 and basePercent + int64((slabCount - 1) * stepSize) <= int64(maxPercent):
            allocationCount += 1
      if lowestStart > lowestCenti:
        let nextStart = lowestStart - 1
        indexSum = indexSum + int64(residueCounts[nextStart mod slabStep])
        activeStudents = activeStudents + scoreCounts[nextStart]
        residueCounts[nextStart mod slabStep] = residueCounts[nextStart mod slabStep] + scoreCounts[nextStart]

  appendOutput($allocationCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
