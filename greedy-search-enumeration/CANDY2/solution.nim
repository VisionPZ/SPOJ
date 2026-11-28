const flushBlockBytes = 1 shl 17

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

let bagCount = nextInt(inputData, scanPos)
var chocolateCounts = newSeq[int64](bagCount)
var strawberryCounts = newSeq[int64](bagCount)
var bananaCounts = newSeq[int64](bagCount)
for bagIndex in 0 .. bagCount - 1:
  chocolateCounts[bagIndex] = int64(nextInt(inputData, scanPos))
  strawberryCounts[bagIndex] = int64(nextInt(inputData, scanPos))
  bananaCounts[bagIndex] = int64(nextInt(inputData, scanPos))

proc insertCandidate(candidates: var seq[int], bagIndex: int, counts: seq[int64]) =
  var slot = 0
  while slot < candidates.len:
    let otherBag = candidates[slot]
    if otherBag == -1:
      break
    if counts[bagIndex] > counts[otherBag]:
      break
    if counts[bagIndex] == counts[otherBag] and bagIndex < otherBag:
      break
    slot += 1
  if slot == candidates.len:
    return
  var moveIndex = candidates.len - 1
  while moveIndex > slot:
    candidates[moveIndex] = candidates[moveIndex - 1]
    moveIndex -= 1
  candidates[slot] = bagIndex

var chocolateTop = newSeq[int](3)
var strawberryTop = newSeq[int](3)
var bananaTop = newSeq[int](3)
for candidateIndex in 0 .. 2:
  chocolateTop[candidateIndex] = -1
  strawberryTop[candidateIndex] = -1
  bananaTop[candidateIndex] = -1
for bagIndex in 0 .. bagCount - 1:
  insertCandidate(chocolateTop, bagIndex, chocolateCounts)
  insertCandidate(strawberryTop, bagIndex, strawberryCounts)
  insertCandidate(bananaTop, bagIndex, bananaCounts)

proc sortCandidates(candidates: var seq[int]) =
  for rightIndex in 1 .. candidates.len - 1:
    let carriedBag = candidates[rightIndex]
    if carriedBag == -1:
      continue
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and (candidates[leftIndex] == -1 or candidates[leftIndex] > carriedBag):
      candidates[leftIndex + 1] = candidates[leftIndex]
      leftIndex -= 1
    candidates[leftIndex + 1] = carriedBag

sortCandidates(chocolateTop)
sortCandidates(strawberryTop)
sortCandidates(bananaTop)

var bestSum: int64 = -1
var bestChocolateBag = -1
var bestStrawberryBag = -1
var bestBananaBag = -1
for chocolateSlot in 0 .. 2:
  let chocolateBag = chocolateTop[chocolateSlot]
  if chocolateBag < 0:
    continue
  for strawberrySlot in 0 .. 2:
    let strawberryBag = strawberryTop[strawberrySlot]
    if strawberryBag < 0 or strawberryBag == chocolateBag:
      continue
    for bananaSlot in 0 .. 2:
      let bananaBag = bananaTop[bananaSlot]
      if bananaBag < 0 or bananaBag == chocolateBag or bananaBag == strawberryBag:
        continue
      let keptCandies = chocolateCounts[chocolateBag] + strawberryCounts[strawberryBag] + bananaCounts[bananaBag]
      if keptCandies > bestSum:
        bestSum = keptCandies
        bestChocolateBag = chocolateBag
        bestStrawberryBag = strawberryBag
        bestBananaBag = bananaBag

appendOutput($bestChocolateBag)
outputBuffer.add '\n'
appendOutput($bestStrawberryBag)
outputBuffer.add '\n'
appendOutput($bestBananaBag)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
