const flushBlockBytes = 1 shl 17
const modValue = 98765431
const maxPermutationSize = 10
const bitsPerEntry = 4
const entryMask = 15

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

var factorials = newSeq[int](maxPermutationSize + 1)
factorials[0] = 1
for sizeIndex in 1 .. maxPermutationSize:
  factorials[sizeIndex] = factorials[sizeIndex - 1] * sizeIndex

proc packPermutation(values: seq[int], count: int): uint64 =
  result = 0'u64
  for position in 0 .. count - 1:
    result = result or uint64((values[position] + 1) shl (bitsPerEntry * position))

proc unpackPermutation(key: uint64, count: int, target: var seq[int]) =
  var packedValue = int64(key)
  for position in 0 .. count - 1:
    target[position] = int(packedValue and int64(entryMask)) - 1
    packedValue = packedValue shr bitsPerEntry

proc tryInsert(table: var seq[uint64], capacityMask: int, key: uint64): bool =
  var hashed = key * 11400714819323198485'u64
  hashed = hashed xor (hashed shr 30)
  hashed = hashed * 13829222197050239205'u64
  hashed = hashed xor (hashed shr 27)
  var slot = int(hashed and uint64(capacityMask))
  while table[slot] != 0'u64:
    if table[slot] == key:
      return false
    slot = (slot + 1) and capacityMask
  table[slot] = key
  return true

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let permutationSize = nextInt(inputData, scanPos)
  let valueLimit = nextInt(inputData, scanPos)
  var firstGenerator = newSeq[int](permutationSize)
  var secondGenerator = newSeq[int](permutationSize)
  for position in 0 .. permutationSize - 1:
    firstGenerator[position] = nextInt(inputData, scanPos) - 1
  for position in 0 .. permutationSize - 1:
    secondGenerator[position] = nextInt(inputData, scanPos) - 1
  var powers = newSeq[int64](permutationSize + 1)
  powers[0] = 1
  for exponent in 1 .. permutationSize:
    powers[exponent] = powers[exponent - 1] * int64(valueLimit)
  var tableCapacity = 1
  while tableCapacity < 4 * factorials[permutationSize]:
    tableCapacity *= 2
  let capacityMask = tableCapacity - 1
  var visited = newSeq[uint64](tableCapacity)
  var queue = newSeq[uint64]()
  var identity = newSeq[int](permutationSize)
  for position in 0 .. permutationSize - 1:
    identity[position] = position
  let identityKey = packPermutation(identity, permutationSize)
  discard tryInsert(visited, capacityMask, identityKey)
  queue.add identityKey
  var queueHead = 0
  var fixedSum: int64 = 0
  var groupSize: int64 = 0
  var currentPerm = newSeq[int](permutationSize)
  var composedPerm = newSeq[int](permutationSize)
  var inCycle = newSeq[bool](permutationSize)
  while queueHead < queue.len:
    let currentKey = queue[queueHead]
    queueHead += 1
    unpackPermutation(currentKey, permutationSize, currentPerm)
    groupSize += 1
    var cycleCount = 0
    for position in 0 .. permutationSize - 1:
      inCycle[position] = false
    for start in 0 .. permutationSize - 1:
      if not inCycle[start]:
        cycleCount += 1
        var cursor = start
        while not inCycle[cursor]:
          inCycle[cursor] = true
          cursor = currentPerm[cursor]
    fixedSum += powers[cycleCount]
    for position in 0 .. permutationSize - 1:
      composedPerm[position] = currentPerm[firstGenerator[position]]
    let firstKey = packPermutation(composedPerm, permutationSize)
    if tryInsert(visited, capacityMask, firstKey):
      queue.add firstKey
    for position in 0 .. permutationSize - 1:
      composedPerm[position] = currentPerm[secondGenerator[position]]
    let secondKey = packPermutation(composedPerm, permutationSize)
    if tryInsert(visited, capacityMask, secondKey):
      queue.add secondKey
  appendOutput($(fixedSum div groupSize mod int64(modValue)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
