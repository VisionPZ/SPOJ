# CERC07R — Reaux! Sham! Beaux! (SPOJ)

<https://www.spoj.com/problems/CERC07R/>

## Problem

Score games of rock, paper, scissors when each player names symbols in a different language. Report wins, the singular or plural point label, and the winner or a tie.

Input holds games. Each starts with two lines of language code and player name. Rounds follow as two words, one per player. A line with `-` ends a game; `.` ends the last game. Output holds five lines per game: header, two score lines, outcome, and a blank line.

| item | bound |
|---|---|
| languages | cs, en, fr, de, hu, it, jp, pl, es |
| rounds per game | at most 100 |
| name length | at most 20 letters |
| judge limit | 1000 ms, 1536 MB |

Some languages list two words for the same symbol, so word lookup must allow aliases.

Sample input:

```
cs Pepik
en Johnny
Nuzky Scissors
Papir Rock
Papir Scissors
-
de Gertruda
cs Lenka
Stein Papir
Schere Kamen
.
```

Sample output:

```
Game #1:
Pepik: 1 point
Johnny: 1 point
TIED GAME

Game #2:
Gertruda: 0 points
Lenka: 2 points
WINNER: Lenka

```

## Idea

Translate every symbol word into one of three numbers, like sorting cards into three piles. Rock beats scissors, scissors beat paper, and paper beat rock form a cycle. Numbered shapes make the winner a single modular check. Translating each round by hand for every pair of languages would be error prone; one lookup table per language settles it. Map once, then compare numbers.

## Why It Works

1. Each language word names one of three shapes.
2. Numbers 0, 1, and 2 stand for rock, scissors, and paper.
3. Shape (k + 1) modulo 3 beats shape k.
4. Equal shapes give no point to either player.
5. The larger point total names the winner; equal totals give a tie.
6. One point uses `point`; every other count uses `points`.

| term | meaning |
|---|---|
| `firstLanguage` | two-letter code for the first player |
| `shapeOf` | lookup that returns 0, 1, or 2 for a word |
| `firstPoints` | rounds won by the first player |
| `pointWord` | singular or plural label for a score |

The table names the values that decide each output line.

A script trace of the sample:

```
game 1: Nuzky vs Scissors -> tie
        Papir vs Rock -> Johnny scores
        Papir vs Scissors -> Pepik scores
        scores 1 - 1 -> TIED GAME
game 2: Stein vs Papir -> Lenka scores
        Schere vs Kamen -> Lenka scores
        scores 0 - 2 -> WINNER: Lenka
```

The trace reproduces both sample result blocks.

## Code

**Bulk input and token reader.** All lines become one string, and whitespace separates words.

```nim
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
```

Blank and dash lines need no separate parse.
`nextToken` returns an empty string at input end.
Output flushes in blocks, not per line.

**Translation table.** Each language maps its words to three numbered shapes.

```nim
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
```

`wordIn` accepts both spellings of an alias.
Unknown words never appear in valid input.
`pointWord` handles the singular exception.

**Game driver.** The loop reads rounds, scores them, and writes five lines.

```nim
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
```

A dash continues to the next game.
A dot ends the last game after its report.
The modular check awards at most one point per round.

**Final flush.** The remaining buffered text goes out once.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

No output write happens inside a round loop.

## Complexity

Every round costs one word lookup and one comparison.

| phase | time | space |
|---|---|---|
| input read | one pass over words | one input string |
| round scoring | constant work per round | a few counters and words |
| output | one write per block | block buffer |

The lookup table has fixed size across all languages.

| measure | Big O |
|---|---|
| time | O(total rounds) |
| space | O(1) beyond the input string |

Building a phrase-by-phrase rule table for every language pair would cost far more. Numeric shapes are the takeaway.
