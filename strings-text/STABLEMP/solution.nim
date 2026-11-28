{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pairCount = nextInt(inputData, scanPos)
  let rowWidth = pairCount
  var manChoice = newSeq[int](pairCount * rowWidth)
  var womanRank = newSeq[int](pairCount * rowWidth)

  for womanIndex in 0..<pairCount:
    let womanId = nextInt(inputData, scanPos) - 1
    for rankIndex in 0..<rowWidth:
      let manId = nextInt(inputData, scanPos) - 1
      womanRank[womanId * rowWidth + manId] = rankIndex + 1

  for manIndex in 0..<pairCount:
    let manId = nextInt(inputData, scanPos) - 1
    for rankIndex in 0..<rowWidth:
      manChoice[manId * rowWidth + rankIndex] = nextInt(inputData, scanPos) - 1

  var nextProposal = newSeq[int](pairCount)
  var wifeOfMan = newSeq[int](pairCount)
  var husbandOfWoman = newSeq[int](pairCount)
  var freeMen = newSeq[int](pairCount * pairCount + pairCount)
  var queueHead = 0
  var queueTail = 0
  for manId in 0..<pairCount:
    wifeOfMan[manId] = -1
    husbandOfWoman[manId] = -1
    freeMen[queueTail] = manId
    queueTail += 1

  while queueHead < queueTail:
    let manId = freeMen[queueHead]
    queueHead += 1
    while wifeOfMan[manId] == -1:
      let proposalIndex = nextProposal[manId]
      let womanId = manChoice[manId * rowWidth + proposalIndex]
      nextProposal[manId] = proposalIndex + 1
      let heldHusband = husbandOfWoman[womanId]
      if heldHusband == -1:
        husbandOfWoman[womanId] = manId
        wifeOfMan[manId] = womanId
      elif womanRank[womanId * rowWidth + manId] < womanRank[womanId * rowWidth + heldHusband]:
        husbandOfWoman[womanId] = manId
        wifeOfMan[manId] = womanId
        wifeOfMan[heldHusband] = -1
        freeMen[queueTail] = heldHusband
        queueTail += 1

  for manId in 0..<pairCount:
    appendOutput($(manId + 1) & " " & $(wifeOfMan[manId] + 1) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

{.pop.}
