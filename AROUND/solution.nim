const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const keyStride = 5001

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var hashSlots = newSeq[int64](1 shl 16)
var hashGenerations = newSeq[int](1 shl 16)
var hashMask = (1 shl 16) - 1
var hashUsed = 0
var currentGeneration = 1

proc hashPosition(key: int64): int =
  var mixed = cast[uint64](key) * 11400714819323198485'u64
  mixed = mixed xor (mixed shr 31)
  return int(mixed and uint64(hashMask))

proc rawInsert(key: int64) =
  var slot = hashPosition(key)
  while true:
    if hashGenerations[slot] != currentGeneration:
      hashGenerations[slot] = currentGeneration
      hashSlots[slot] = key
      hashUsed += 1
      return
    if hashSlots[slot] == key: return
    slot = (slot + 1) and hashMask

proc growHash() =
  let oldSlots = hashSlots
  let oldGenerations = hashGenerations
  let oldSize = oldSlots.len
  let oldGeneration = currentGeneration
  let newSize = oldSize shl 1
  hashSlots = newSeq[int64](newSize)
  hashGenerations = newSeq[int](newSize)
  hashMask = newSize - 1
  hashUsed = 0
  currentGeneration += 1
  for slot in 0 ..< oldSize:
    if oldGenerations[slot] == oldGeneration:
      rawInsert(oldSlots[slot])

proc seenOrAdd(key: int64): bool =
  if (hashUsed + 1) * 10 > (hashMask + 1) * 7: growHash()
  var slot = hashPosition(key)
  while true:
    if hashGenerations[slot] != currentGeneration:
      hashGenerations[slot] = currentGeneration
      hashSlots[slot] = key
      hashUsed += 1
      return false
    if hashSlots[slot] == key: return true
    slot = (slot + 1) and hashMask

var longitudeOfFarm: seq[int]
var adjacencyHead: seq[int]
var adjacencyTarget: seq[int]
var adjacencyStep: seq[int]
var adjacencyNext: seq[int]
var currentNodes: seq[int]
var currentTotals: seq[int]
var nextNodes: seq[int]
var nextTotals: seq[int]

proc signedStep(startLongitude, endLongitude: int): int =
  let forward = (endLongitude - startLongitude + 360) mod 360
  if forward > 180: forward - 360 else: forward

proc addFlight(fromFarm, toFarm: int, edgeIndex: var int) =
  adjacencyTarget[edgeIndex] = toFarm
  adjacencyStep[edgeIndex] = signedStep(longitudeOfFarm[fromFarm], longitudeOfFarm[toFarm])
  adjacencyNext[edgeIndex] = adjacencyHead[fromFarm]
  adjacencyHead[fromFarm] = edgeIndex
  edgeIndex += 1

proc shortestTour(): int =
  currentGeneration += 1
  hashUsed = 0
  discard seenOrAdd(int64(1))
  currentNodes.setLen 1
  currentNodes[0] = 1
  currentTotals.setLen 1
  currentTotals[0] = 0
  var travelledFlights = 0
  while currentNodes.len > 0:
    nextNodes.setLen 0
    nextTotals.setLen 0
    for position in 0 ..< currentNodes.len:
      let currentFarm = currentNodes[position]
      let accumulatedDegrees = currentTotals[position]
      var edgeIndex = adjacencyHead[currentFarm]
      while edgeIndex != -1:
        let neighbourFarm = adjacencyTarget[edgeIndex]
        let updatedDegrees = accumulatedDegrees + adjacencyStep[edgeIndex]
        if neighbourFarm == 1 and updatedDegrees != 0:
          return travelledFlights + 1
        let stateKey = int64(updatedDegrees) * keyStride + int64(neighbourFarm)
        if not seenOrAdd(stateKey):
          nextNodes.add neighbourFarm
          nextTotals.add updatedDegrees
        edgeIndex = adjacencyNext[edgeIndex]
    swap currentNodes, nextNodes
    swap currentTotals, nextTotals
    travelledFlights += 1
  return -1

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let farmCount = nextInt(inputData, scanPos)
  let flightCount = nextInt(inputData, scanPos)
  longitudeOfFarm.setLen farmCount + 1
  for farm in 1 .. farmCount:
    longitudeOfFarm[farm] = nextInt(inputData, scanPos)
  adjacencyHead.setLen farmCount + 1
  for farm in 1 .. farmCount:
    adjacencyHead[farm] = -1
  adjacencyTarget.setLen flightCount * 2
  adjacencyStep.setLen flightCount * 2
  adjacencyNext.setLen flightCount * 2
  var edgeIndex = 0
  for flight in 0 ..< flightCount:
    let departureFarm = nextInt(inputData, scanPos)
    let arrivalFarm = nextInt(inputData, scanPos)
    addFlight(departureFarm, arrivalFarm, edgeIndex)
    addFlight(arrivalFarm, departureFarm, edgeIndex)
  appendOutput($(shortestTour()))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
