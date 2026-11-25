const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextField(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var field = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    field.add data[pos]
    pos += 1
  return field

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc buildAtLeast(aNumber: string, availableDigits: seq[int], digitLength: int): string =
  var snapshots = newSeq[seq[int]](digitLength)
  var counts = availableDigits
  var equalLength = 0
  var stopped = false
  for position in 0 .. digitLength - 1:
    snapshots[position] = counts
    if stopped:
      continue
    let wantedDigit = int(aNumber[position]) - 48
    if counts[wantedDigit] > 0 and not (position == 0 and wantedDigit == 0):
      counts[wantedDigit] -= 1
      equalLength += 1
    else:
      stopped = true
  if equalLength == digitLength:
    return aNumber
  var position = equalLength
  if position >= digitLength:
    position = digitLength - 1
  while position >= 0:
    let beforeCounts = snapshots[position]
    let wantedDigit = int(aNumber[position]) - 48
    var candidateDigit = wantedDigit + 1
    var chosenDigit = -1
    while candidateDigit <= 9:
      if beforeCounts[candidateDigit] > 0 and not (position == 0 and candidateDigit == 0):
        chosenDigit = candidateDigit
        break
      candidateDigit += 1
    if chosenDigit >= 0:
      var builtNumber = ""
      for prefixIndex in 0 ..< position:
        builtNumber.add aNumber[prefixIndex]
      builtNumber.add chr(48 + chosenDigit)
      var remaining = beforeCounts
      remaining[chosenDigit] -= 1
      for digitValue in 0 .. 9:
        var repeatCount = remaining[digitValue]
        while repeatCount > 0:
          builtNumber.add chr(48 + digitValue)
          repeatCount -= 1
      return builtNumber
    position -= 1
  return "0"

proc buildBelow(aNumber: string, availableDigits: seq[int], digitLength: int): string =
  var snapshots = newSeq[seq[int]](digitLength)
  var counts = availableDigits
  var equalLength = 0
  var stopped = false
  for position in 0 .. digitLength - 1:
    snapshots[position] = counts
    if stopped:
      continue
    let wantedDigit = int(aNumber[position]) - 48
    if counts[wantedDigit] > 0 and not (position == 0 and wantedDigit == 0):
      counts[wantedDigit] -= 1
      equalLength += 1
    else:
      stopped = true
  var position = equalLength
  if position >= digitLength:
    position = digitLength - 1
  while position >= 0:
    let beforeCounts = snapshots[position]
    let wantedDigit = int(aNumber[position]) - 48
    var candidateDigit = wantedDigit - 1
    var chosenDigit = -1
    while candidateDigit >= 0:
      if beforeCounts[candidateDigit] > 0 and not (position == 0 and candidateDigit == 0):
        chosenDigit = candidateDigit
        break
      candidateDigit -= 1
    if chosenDigit >= 0:
      var builtNumber = ""
      for prefixIndex in 0 ..< position:
        builtNumber.add aNumber[prefixIndex]
      builtNumber.add chr(48 + chosenDigit)
      var remaining = beforeCounts
      remaining[chosenDigit] -= 1
      var digitValue = 9
      while digitValue >= 0:
        var repeatCount = remaining[digitValue]
        while repeatCount > 0:
          builtNumber.add chr(48 + digitValue)
          repeatCount -= 1
        digitValue -= 1
      return builtNumber
    position -= 1
  return "0"

while scanPos < inputData.len:
  let aNumber = nextField(inputData, scanPos)
  if aNumber.len == 0:
    break
  let bNumber = nextField(inputData, scanPos)
  if bNumber.len == 0:
    break
  var availableDigits = newSeq[int](10)
  for digitChar in bNumber:
    availableDigits[int(digitChar) - 48] += 1
  appendOutput(buildAtLeast(aNumber, availableDigits, aNumber.len))
  outputBuffer.add '\n'
  appendOutput(buildBelow(aNumber, availableDigits, aNumber.len))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
