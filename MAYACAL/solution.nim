const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  cycleTzolkin = 260
  cycleHaab = 365
  cycleCalendarRound = 18980
  referenceDay = 1152000
  finalDay = 1439999
  daysPerBaktun = 144000
  daysPerKatun = 7200
  daysPerTun = 360
  daysPerWinal = 20
  referenceTzolkinPosition = 99
  referenceHaabPosition = 42
  referenceResidue = 2
  tzolkinNames = ["Imix", "Ik", "Akbal", "Kan", "Chikchan", "Kimi", "Manik", "Lamat", "Muluk", "Ok", "Chuen", "Eb", "Ben", "Ix", "Men", "Kib", "Kaban", "Etznab", "Kawak", "Ajaw"]
  haabNames = ["Pohp", "Wo", "Sip", "Zotz", "Sek", "Xul", "Yaxkin", "Mol", "Chen", "Yax", "Sak", "Keh", "Mak", "Kankin", "Muan", "Pax", "Kayab", "Kumku", "Wayeb"]
  haabMonthLengths = [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 5]
  haabMonthStarts = [0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 220, 240, 260, 280, 300, 320, 340, 360]

proc modNorm(value, modulus: int): int =
  let wrapped = value mod modulus
  if wrapped < 0:
    result = wrapped + modulus
  else:
    result = wrapped

proc findNameIndex(names: openArray[string], word: string): int =
  result = -1
  for i in 0 .. names.len - 1:
    if names[i] == word:
      result = i
      return

proc skipSeparators(inputData: string, i: var int) =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] == ' ' or inputData[i] == '\n' or inputData[i] == '\r' or inputData[i] == '\t'):
    inc i

proc scanNumber(inputData: string, i: var int): int =
  skipSeparators(inputData, i)
  var value = 0
  let dataLength = inputData.len
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (int(inputData[i]) - firstDigitValue)
    inc i
  result = value

proc scanWord(inputData: string, i: var int, wordBuffer: var string) =
  wordBuffer.setLen(0)
  skipSeparators(inputData, i)
  let dataLength = inputData.len
  while i < dataLength and ((inputData[i] >= 'A' and inputData[i] <= 'Z') or (inputData[i] >= 'a' and inputData[i] <= 'z')):
    wordBuffer.add inputData[i]
    inc i

proc appendLongCountDate(outputBuffer: var string, dayNumber: int) =
  var remaining = dayNumber
  let baktunCount = remaining div daysPerBaktun
  remaining = remaining mod daysPerBaktun
  let katunCount = remaining div daysPerKatun
  remaining = remaining mod daysPerKatun
  let tunCount = remaining div daysPerTun
  remaining = remaining mod daysPerTun
  let winalCount = remaining div daysPerWinal
  let kinCount = remaining mod daysPerWinal
  outputBuffer.add($baktunCount & "." & $katunCount & "." & $tunCount & "." & $winalCount & "." & $kinCount & "\n")

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""
var i = 0
var tzolkinWord = ""
var haabWord = ""
let caseCount = scanNumber(inputData, i)
var j = 0
while j < caseCount:
  let tzolkinNumber = scanNumber(inputData, i)
  scanWord(inputData, i, tzolkinWord)
  let haabNumber = scanNumber(inputData, i)
  scanWord(inputData, i, haabWord)
  let tzolkinNameIndex = findNameIndex(tzolkinNames, tzolkinWord)
  let haabMonthIndex = findNameIndex(haabNames, haabWord)
  var occurrenceCount = 0
  var firstDay = 0
  if tzolkinNumber >= 1 and tzolkinNumber <= 13 and tzolkinNameIndex >= 0 and haabMonthIndex >= 0:
    let monthLength = haabMonthLengths[haabMonthIndex]
    if haabNumber >= 1 and haabNumber <= monthLength:
      let tzolkinPosition = tzolkinNameIndex + 20 * modNorm((tzolkinNumber - 1 - tzolkinNameIndex) * 2, 13)
      let haabPosition = haabMonthStarts[haabMonthIndex] + haabNumber - 1
      if modNorm(tzolkinPosition - haabPosition, 5) == referenceResidue:
        let deltaTzolkin = modNorm(tzolkinPosition - referenceTzolkinPosition, cycleTzolkin)
        let deltaHaab = modNorm(haabPosition - referenceHaabPosition, cycleHaab)
        var stepCount = 0
        while stepCount < 73 and (deltaTzolkin + cycleTzolkin * stepCount) mod cycleHaab != deltaHaab:
          inc stepCount
        if stepCount < 73:
          firstDay = referenceDay + deltaTzolkin + cycleTzolkin * stepCount
          if firstDay <= finalDay:
            occurrenceCount = (finalDay - firstDay) div cycleCalendarRound + 1
  outputBuffer.add $occurrenceCount
  outputBuffer.add '\n'
  var k = 0
  while k < occurrenceCount:
    appendLongCountDate(outputBuffer, firstDay + cycleCalendarRound * k)
    inc k
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  inc j
if outputBuffer.len > 0:
  stdout.write outputBuffer
