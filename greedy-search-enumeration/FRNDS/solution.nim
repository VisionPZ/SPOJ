const flushBlockBytes = 1 shl 17
const answerModulus = 100000007.int64
const maximumPeople = 40

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

proc modularPower(baseValue: int64, exponentValue: int): int64 =
  var powerResult: int64 = 1
  var current = baseValue mod answerModulus
  var exponent = exponentValue
  while exponent > 0:
    if (exponent and 1) == 1:
      powerResult = powerResult * current mod answerModulus
    current = current * current mod answerModulus
    exponent = exponent div 2
  return powerResult

var factorials = newSeq[int64](maximumPeople + 1)
var inverseFactorials = newSeq[int64](maximumPeople + 1)
factorials[0] = 1
for indexValue in 1 .. maximumPeople:
  factorials[indexValue] = factorials[indexValue - 1] * int64(indexValue) mod answerModulus
inverseFactorials[maximumPeople] = modularPower(factorials[maximumPeople], int(answerModulus) - 2)
for indexValue in countdown(maximumPeople, 1):
  inverseFactorials[indexValue - 1] = inverseFactorials[indexValue] * int64(indexValue) mod answerModulus

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let peopleCount = nextInt(inputData, scanPos)
  let friendshipCount = nextInt(inputData, scanPos)
  var parent = newSeq[int](peopleCount)
  for personIndex in 0 .. peopleCount - 1:
    parent[personIndex] = personIndex

  proc findRoot(person: int): int =
    var current = person
    while parent[current] != current:
      current = parent[current]
    return current

  for friendshipIndex in 0 .. friendshipCount - 1:
    let firstPerson = nextInt(inputData, scanPos) - 1
    let secondPerson = nextInt(inputData, scanPos) - 1
    let firstRoot = findRoot(firstPerson)
    let secondRoot = findRoot(secondPerson)
    if firstRoot != secondRoot:
      parent[firstRoot] = secondRoot

  var groupSizes = newSeq[int](peopleCount + 1)
  for personIndex in 0 .. peopleCount - 1:
    groupSizes[findRoot(personIndex)] += 1
  var sizes = newSeq[int]()
  for groupIndex in 0 .. peopleCount:
    if groupSizes[groupIndex] > 0:
      sizes.add groupSizes[groupIndex]

  var possibilities = newSeq[int64](peopleCount + 1)
  possibilities[0] = 1
  for groupSize in sizes:
    var updated = newSeq[int64](peopleCount + 1)
    for usedCount in 0 .. peopleCount:
      if possibilities[usedCount] == 0:
        continue
      for partCount in 1 .. groupSize:
        if usedCount + partCount > peopleCount:
          break
        var combinations = factorials[groupSize - 1]
        combinations = combinations * inverseFactorials[partCount - 1] mod answerModulus
        combinations = combinations * inverseFactorials[groupSize - partCount] mod answerModulus
        var contribution = possibilities[usedCount] * combinations mod answerModulus
        contribution = contribution * inverseFactorials[partCount] mod answerModulus
        if (groupSize - partCount) mod 2 == 1:
          contribution = (answerModulus - contribution) mod answerModulus
        updated[usedCount + partCount] = (updated[usedCount + partCount] + contribution) mod answerModulus
    possibilities = updated

  var separatorCount: int64 = 0
  for usedCount in 1 .. peopleCount:
    separatorCount = (separatorCount + possibilities[usedCount] * factorials[usedCount]) mod answerModulus
  var badArrangements = separatorCount
  for groupSize in sizes:
    badArrangements = badArrangements * factorials[groupSize] mod answerModulus
  let goodArrangements = (factorials[peopleCount] - badArrangements + answerModulus) mod answerModulus
  appendOutput("Case #" & $caseIndex & ": " & $goodArrangements & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
