const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const dayCount = 7
const kindSelfGuilty = 0
const kindSelfInnocent = 1
const kindOtherGuilty = 2
const kindOtherInnocent = 3
const kindDay = 4

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

proc nextLine(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r' or data[pos] == ' ' or data[pos] == '\t'):
    pos += 1
  var line = ""
  while pos < data.len and data[pos] != '\n' and data[pos] != '\r':
    line.add data[pos]
    pos += 1
  if pos < data.len and data[pos] == '\r':
    pos += 1
  if pos < data.len and data[pos] == '\n':
    pos += 1
  return line

proc nextToken(text: string, pos: var int): string =
  while pos < text.len and not ((text[pos] >= 'a' and text[pos] <= 'z') or (text[pos] >= 'A' and text[pos] <= 'Z')):
    pos += 1
  var word = ""
  while pos < text.len and ((text[pos] >= 'a' and text[pos] <= 'z') or (text[pos] >= 'A' and text[pos] <= 'Z')):
    word.add text[pos]
    pos += 1
  return word

proc findName(names: seq[string], candidate: string): int =
  for nameIndex in 0 .. names.len - 1:
    if names[nameIndex] == candidate:
      return nameIndex
  return -1

proc findDay(candidate: string): int =
  let weekdays = @["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  for dayIndex in 0 .. dayCount - 1:
    if weekdays[dayIndex] == candidate:
      return dayIndex
  return -1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasDigits(inputData, scanPos):
  let personCount = nextInt(inputData, scanPos)
  let liarCount = nextInt(inputData, scanPos)
  let sentenceCount = nextInt(inputData, scanPos)
  var names = newSeq[string](personCount)
  for personIndex in 0 .. personCount - 1:
    names[personIndex] = nextLine(inputData, scanPos)
  var speakers = newSeq[int](sentenceCount)
  var kinds = newSeq[int](sentenceCount)
  var targets = newSeq[int](sentenceCount)
  for sentenceIndex in 0 .. sentenceCount - 1:
    let speech = nextLine(inputData, scanPos)
    kinds[sentenceIndex] = -1
    var colonPos = 0
    while colonPos < speech.len and speech[colonPos] != ':':
      colonPos += 1
    if colonPos >= speech.len:
      continue
    let speaker = findName(names, speech[0 .. colonPos - 1])
    if speaker < 0:
      continue
    speakers[sentenceIndex] = speaker
    var wordPos = colonPos + 1
    let firstWord = nextToken(speech, wordPos)
    let secondWord = nextToken(speech, wordPos)
    let thirdWord = nextToken(speech, wordPos)
    let fourthWord = nextToken(speech, wordPos)
    if firstWord == "I" and secondWord == "am":
      if thirdWord == "guilty":
        kinds[sentenceIndex] = kindSelfGuilty
      elif thirdWord == "not" and fourthWord == "guilty":
        kinds[sentenceIndex] = kindSelfInnocent
    elif firstWord == "Today" and secondWord == "is":
      let statedDay = findDay(thirdWord)
      if statedDay >= 0:
        kinds[sentenceIndex] = kindDay
        targets[sentenceIndex] = statedDay
    else:
      let subject = findName(names, firstWord)
      if subject >= 0 and secondWord == "is":
        if thirdWord == "guilty":
          kinds[sentenceIndex] = kindOtherGuilty
          targets[sentenceIndex] = subject
        elif thirdWord == "not" and fourthWord == "guilty":
          kinds[sentenceIndex] = kindOtherInnocent
          targets[sentenceIndex] = subject
  var possible = newSeq[bool](personCount)
  for culprit in 0 .. personCount - 1:
    for day in 0 .. dayCount - 1:
      var forcedLiars = 0
      var flexiblePeople = 0
      var consistent = true
      for person in 0 .. personCount - 1:
        var hasUseful = false
        var allTrue = true
        var allFalse = true
        for sentenceIndex in 0 .. sentenceCount - 1:
          if kinds[sentenceIndex] < 0 or speakers[sentenceIndex] != person:
            continue
          var truth: bool
          case kinds[sentenceIndex]
          of kindSelfGuilty:
            truth = person == culprit
          of kindSelfInnocent:
            truth = person != culprit
          of kindOtherGuilty:
            truth = targets[sentenceIndex] == culprit
          of kindOtherInnocent:
            truth = targets[sentenceIndex] != culprit
          else:
            truth = day == targets[sentenceIndex]
          hasUseful = true
          if not truth:
            allTrue = false
          if truth:
            allFalse = false
        if not hasUseful:
          flexiblePeople += 1
        elif not allTrue and not allFalse:
          consistent = false
          break
        elif allFalse:
          forcedLiars += 1
      if consistent and forcedLiars <= liarCount and liarCount <= forcedLiars + flexiblePeople:
        possible[culprit] = true
  var winnerCount = 0
  var winnerName = ""
  for culprit in 0 .. personCount - 1:
    if possible[culprit]:
      winnerCount += 1
      winnerName = names[culprit]
  if winnerCount == 0:
    appendOutput("Impossible")
  elif winnerCount > 1:
    appendOutput("Cannot Determine")
  else:
    appendOutput(winnerName)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
