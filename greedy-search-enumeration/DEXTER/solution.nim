import strutils

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and ((data[pos] < '0' or data[pos] > '9') and data[pos] != '-'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type
  ChancePair = object
    penaltyValue: int
    chanceValue: float64

proc sortPairs(pairs: var seq[ChancePair]) =
  for sortIndex in 1 ..< pairs.len:
    let currentPair = pairs[sortIndex]
    var compareIndex = sortIndex - 1
    while compareIndex >= 0 and pairs[compareIndex].penaltyValue > currentPair.penaltyValue:
      pairs[compareIndex + 1] = pairs[compareIndex]
      compareIndex = compareIndex - 1
    pairs[compareIndex + 1] = currentPair

proc cumulativeChances(pairs: seq[ChancePair]): seq[float64] =
  result = newSeq[float64](pairs.len)
  var runningChance = 0.0
  for pairIndex in 0 ..< pairs.len:
    runningChance = runningChance + pairs[pairIndex].chanceValue
    result[pairIndex] = runningChance

proc crossBetter(dexterPairs: seq[ChancePair], coderPairs: seq[ChancePair], coderCumulative: seq[float64]): float64 =
  var coderIndex = 0
  var accumulatedChance = 0.0
  for dexterPair in dexterPairs:
    while coderIndex < coderPairs.len and coderPairs[coderIndex].penaltyValue < dexterPair.penaltyValue:
      accumulatedChance = accumulatedChance + coderPairs[coderIndex].chanceValue
      coderIndex = coderIndex + 1
    result = result + dexterPair.chanceValue * accumulatedChance

proc buildOutcomes(penaltyRow: seq[int], passChance: seq[float64]): tuple[groups: seq[seq[ChancePair]], scoreProb: seq[float64]] =
  let problemCount = penaltyRow.len
  var submittedIndex = newSeq[int](0)
  var submittedPenalty = newSeq[int](0)
  var submissionChance = newSeq[float64](0)
  var failureChance = newSeq[float64](0)
  for problemIndex in 0 ..< problemCount:
    if penaltyRow[problemIndex] >= 0:
      submittedIndex.add problemIndex
      submittedPenalty.add penaltyRow[problemIndex]
      submissionChance.add passChance[problemIndex]
      failureChance.add 1.0 - passChance[problemIndex]
  let submittedCount = submittedIndex.len
  result.groups = newSeq[seq[ChancePair]](problemCount + 1)
  result.scoreProb = newSeq[float64](problemCount + 1)
  for scoreIndex in 0 .. problemCount:
    result.groups[scoreIndex] = newSeq[ChancePair](0)
  let subsetLimit = 1 shl submittedCount
  for subsetMask in 0 ..< subsetLimit:
    var subsetChance = 1.0
    var solvedCount = 0
    var penaltySum = 0
    for submitIndex in 0 ..< submittedCount:
      if (subsetMask and (1 shl submitIndex)) != 0:
        subsetChance = subsetChance * submissionChance[submitIndex]
        solvedCount = solvedCount + 1
        penaltySum = penaltySum + submittedPenalty[submitIndex]
      else:
        subsetChance = subsetChance * failureChance[submitIndex]
    result.groups[solvedCount].add ChancePair(penaltyValue: penaltySum, chanceValue: subsetChance)
    result.scoreProb[solvedCount] = result.scoreProb[solvedCount] + subsetChance
  for scoreIndex in 0 .. problemCount:
    sortPairs(result.groups[scoreIndex])

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let coderCount = nextInt(inputData, scanPos)
  let problemCount = nextInt(inputData, scanPos)
  var penaltyMatrix = newSeq[seq[int]](coderCount)
  for coderIndex in 0 ..< coderCount:
    penaltyMatrix[coderIndex] = newSeq[int](problemCount)
    for problemIndex in 0 ..< problemCount:
      penaltyMatrix[coderIndex][problemIndex] = nextInt(inputData, scanPos)
  var passChance = newSeq[float64](problemCount)
  for problemIndex in 0 ..< problemCount:
    passChance[problemIndex] = float64(nextInt(inputData, scanPos)) / 100.0
  let dexterOutcome = buildOutcomes(penaltyMatrix[0], passChance)
  var expectedRank = 1.0
  for coderIndex in 1 ..< coderCount:
    let coderOutcome = buildOutcomes(penaltyMatrix[coderIndex], passChance)
    var cumulativeByScore = newSeq[seq[float64]](problemCount + 1)
    var suffixGreater = newSeq[float64](problemCount + 1)
    for scoreIndex in 0 .. problemCount:
      cumulativeByScore[scoreIndex] = cumulativeChances(coderOutcome.groups[scoreIndex])
    var scoreCursor = problemCount
    var runningHigher = 0.0
    while scoreCursor >= 0:
      suffixGreater[scoreCursor] = runningHigher
      runningHigher = runningHigher + coderOutcome.scoreProb[scoreCursor]
      scoreCursor = scoreCursor - 1
    var coderBetter = 0.0
    for dexterScore in 0 .. problemCount:
      let dexterScoreProbability = dexterOutcome.scoreProb[dexterScore]
      if dexterScoreProbability == 0.0:
        continue
      coderBetter = coderBetter + dexterScoreProbability * suffixGreater[dexterScore]
      coderBetter = coderBetter + crossBetter(dexterOutcome.groups[dexterScore], coderOutcome.groups[dexterScore], cumulativeByScore[dexterScore])
    expectedRank = expectedRank + coderBetter
  appendOutput(formatFloat(expectedRank, ffDecimal, 4))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
