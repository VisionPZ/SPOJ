const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc chainGains(values: seq[int]): tuple[one: int, two: int] =
  var total = 0
  var maxPrefix = 0
  var maxSuffix = 0
  var running = 0
  for value in values:
    running += value
    total += value
    if running > maxPrefix:
      maxPrefix = running
  running = 0
  for index in countdown(values.len - 1, 0):
    running += values[index]
    if running > maxSuffix:
      maxSuffix = running
  var smallest = 0
  var current = 0
  for value in values:
    if current + value < value:
      current += value
    else:
      current = value
    if current < smallest:
      smallest = current
  var bestOne = 0
  if maxPrefix > bestOne:
    bestOne = maxPrefix
  if maxSuffix > bestOne:
    bestOne = maxSuffix
  return (bestOne, total - smallest)

var width = nextInt(inputData, scanPos)
var allowance = nextInt(inputData, scanPos)
var ballCount = nextInt(inputData, scanPos)
var caseNumber = 1
while not (width == 0 and allowance == 0 and ballCount == 0):
  var chains = newSeq[seq[int]](ballCount + 1)
  for ballIndex in 1 .. ballCount:
    let money = nextInt(inputData, scanPos)
    let residue = (ballIndex - 1) mod width
    chains[residue].add money
  let turnLimit = min(allowance, ballCount)
  var bestMoney = newSeq[int](turnLimit + 1)
  for chain in chains:
    if chain.len == 0:
      continue
    let gains = chainGains(chain)
    var nextMoney = newSeq[int](turnLimit + 1)
    for turnCount in 0 .. turnLimit:
      nextMoney[turnCount] = bestMoney[turnCount]
      if turnCount >= 1:
        let candidate = bestMoney[turnCount - 1] + gains.one
        if candidate > nextMoney[turnCount]:
          nextMoney[turnCount] = candidate
      if turnCount >= 2:
        let candidate = bestMoney[turnCount - 2] + gains.two
        if candidate > nextMoney[turnCount]:
          nextMoney[turnCount] = candidate
    bestMoney = nextMoney
  let topMoney = bestMoney[turnLimit]
  var usedTurns = 0
  while bestMoney[usedTurns] < topMoney:
    usedTurns += 1
  appendOutput("Case#" & $caseNumber & ": Jack wins $" & $topMoney &
               " out of " & $usedTurns & " throws.\n")
  caseNumber += 1
  width = nextInt(inputData, scanPos)
  allowance = nextInt(inputData, scanPos)
  ballCount = nextInt(inputData, scanPos)

stdout.write outputBuffer
outputBuffer.setLen 0
