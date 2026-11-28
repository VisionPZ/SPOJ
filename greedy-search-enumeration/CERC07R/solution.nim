const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var token = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc wordIn(word: string, candidates: openArray[string]): bool =
  for candidate in candidates:
    if word == candidate:
      return true
  return false

proc shapeOf(language: string, word: string): int =
  if language == "cs":
    if wordIn(word, ["Kamen"]):
      return 0
    if wordIn(word, ["Nuzky"]):
      return 1
    if wordIn(word, ["Papir"]):
      return 2
  elif language == "en":
    if wordIn(word, ["Rock"]):
      return 0
    if wordIn(word, ["Scissors"]):
      return 1
    if wordIn(word, ["Paper"]):
      return 2
  elif language == "fr":
    if wordIn(word, ["Pierre"]):
      return 0
    if wordIn(word, ["Ciseaux"]):
      return 1
    if wordIn(word, ["Feuille"]):
      return 2
  elif language == "de":
    if wordIn(word, ["Stein"]):
      return 0
    if wordIn(word, ["Schere"]):
      return 1
    if wordIn(word, ["Papier"]):
      return 2
  elif language == "hu":
    if wordIn(word, ["Ko", "Koe"]):
      return 0
    if wordIn(word, ["Ollo", "Olloo"]):
      return 1
    if wordIn(word, ["Papir"]):
      return 2
  elif language == "it":
    if wordIn(word, ["Sasso", "Roccia"]):
      return 0
    if wordIn(word, ["Forbice"]):
      return 1
    if wordIn(word, ["Carta", "Rete"]):
      return 2
  elif language == "jp":
    if wordIn(word, ["Guu"]):
      return 0
    if wordIn(word, ["Choki"]):
      return 1
    if wordIn(word, ["Paa"]):
      return 2
  elif language == "pl":
    if wordIn(word, ["Kamien"]):
      return 0
    if wordIn(word, ["Nozyce"]):
      return 1
    if wordIn(word, ["Papier"]):
      return 2
  elif language == "es":
    if wordIn(word, ["Piedra"]):
      return 0
    if wordIn(word, ["Tijera"]):
      return 1
    if wordIn(word, ["Papel"]):
      return 2
  return -1

proc pointWord(pointCount: int): string =
  if pointCount == 1:
    return "point"
  return "points"

var gameNumber = 0
while true:
  let openingToken = nextToken(inputData, scanPos)
  if openingToken.len == 0 or openingToken == ".":
    break
  gameNumber += 1
  let firstLanguage = openingToken
  let firstName = nextToken(inputData, scanPos)
  let secondLanguage = nextToken(inputData, scanPos)
  let secondName = nextToken(inputData, scanPos)
  var firstPoints = 0
  var secondPoints = 0
  var finalGame = false
  while true:
    let roundToken = nextToken(inputData, scanPos)
    if roundToken == "-" or roundToken == ".":
      if roundToken == ".":
        finalGame = true
      break
    let firstShape = shapeOf(firstLanguage, roundToken)
    let secondShape = shapeOf(secondLanguage, nextToken(inputData, scanPos))
    if firstShape != secondShape:
      if (firstShape + 1) mod 3 == secondShape:
        firstPoints += 1
      else:
        secondPoints += 1

  appendOutput("Game #" & $gameNumber & ":\n")
  appendOutput(firstName & ": " & $firstPoints & " " & pointWord(firstPoints) & "\n")
  appendOutput(secondName & ": " & $secondPoints & " " & pointWord(secondPoints) & "\n")
  if firstPoints == secondPoints:
    appendOutput("TIED GAME\n")
  else:
    if firstPoints > secondPoints:
      appendOutput("WINNER: " & firstName & "\n")
    else:
      appendOutput("WINNER: " & secondName & "\n")
  appendOutput("\n")
  if finalGame:
    break

stdout.write outputBuffer
outputBuffer.setLen 0
