const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  value

proc gcdOf(left: int64, right: int64): int64 =
  var a = left
  var b = right
  while b != 0:
    let rest = a mod b
    a = b
    b = rest
  a

type ValueSet = object
  slots: seq[int64]
  used: int

proc slotFor(value: int64, mask: int): int =
  let mixed = uint64(value) * 11400714819323198485'u64
  int((mixed xor (mixed shr 29)) and uint64(mask))

proc growSet(store: var ValueSet) =
  var fresh = newSeq[int64](store.slots.len * 2)
  let mask = fresh.len - 1
  for value in store.slots:
    if value != 0:
      var idx = slotFor(value, mask)
      while fresh[idx] != 0:
        idx = (idx + 1) and mask
      fresh[idx] = value
  store.slots = fresh

proc inSet(store: var ValueSet, value: int64): bool =
  let mask = store.slots.len - 1
  var idx = slotFor(value, mask)
  while store.slots[idx] != 0:
    if store.slots[idx] == value:
      return true
    idx = (idx + 1) and mask
  false

proc addSet(store: var ValueSet, value: int64) =
  if (store.used + 1) * 2 >= store.slots.len:
    store.growSet()
  let mask = store.slots.len - 1
  var idx = slotFor(value, mask)
  while store.slots[idx] != 0 and store.slots[idx] != value:
    idx = (idx + 1) and mask
  if store.slots[idx] == 0:
    store.slots[idx] = value
    store.used += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let holidayCount = int(nextInt(inputData, scanPos))
  let removeCount = int(nextInt(inputData, scanPos))
  var periods = newSeq[int64](holidayCount)
  for i in 0 ..< holidayCount:
    periods[i] = nextInt(inputData, scanPos)
  let keepCount = holidayCount - removeCount
  var seen: ValueSet
  seen.slots = newSeq[int64](1024)
  var candidates = newSeq[int64]()
  for value in periods:
    if not seen.inSet(value):
      seen.addSet(value)
      candidates.add value
    let before = candidates.len
    for j in 0 ..< before:
      let common = gcdOf(candidates[j], value)
      if not seen.inSet(common):
        seen.addSet(common)
        candidates.add common
  var bestRhythm = 0'i64
  for rhythm in candidates:
    if rhythm <= bestRhythm:
      continue
    var multiples = 0
    for period in periods:
      if period mod rhythm == 0:
        multiples += 1
        if multiples >= keepCount:
          break
    if multiples >= keepCount:
      bestRhythm = rhythm
  var removed = newSeq[int]()
  var kept = 0
  for i in 0 ..< holidayCount:
    if periods[i] mod bestRhythm == 0 and kept < keepCount:
      kept += 1
    else:
      removed.add i + 1
  for j in 0 ..< removed.len:
    if j > 0:
      appendOutput " "
    appendOutput $(removed[j])
  appendOutput "\n"

stdout.write outputBuffer
outputBuffer.setLen 0
