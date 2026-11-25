# ACT — Alpha Centauri Tennis (SPOJ)

<https://www.spoj.com/problems/ACT/>

## Problem

Each test case gives the player count and the full list of ball winners in a finished match. Report the letter of the player who won the match.

Input starts with `t`, the number of test cases. Each following line holds `N`, then a string `S` of uppercase letters. The letter at position `i` names the winner of ball `i`. Output one letter per line: the winner of that match.

Notation: `t` is the test count, and `N` is the player count. `S` is one transcript, `i` is a position in `S`, and `S[-1]` is its last letter.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `t` | at most 150 |
| Players `N` | at most 10, using the first `N` capital letters |
| Transcript length `S` | 2 to 50 000 letters |
| Judge limit | 1000 ms, 1536 MB |

The transcripts are correct and complete, so each one stops when its match ends.

The sample case:

```
1
3 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
```

```
B
```

Both blocks are byte-exact copies of the statement sample.

## Idea

The winner of the last ball is the winner of the match. This works like a finish-line photo: the final name written down is the champion.

The program reads all input once, then scans each transcript to its last uppercase letter. The scan is linear, with one byte read per ball. One letter and one newline per case are the only output work.

A full rules simulation is the naive way. It updates points, games and set points for each ball. It also checks several conditions on every ball and stores arrays for every player.

The last letter of a correct transcript is the whole answer.

## Why It Works

Four facts carry the proof.

1. A game ends on a ball won by the player who takes that game.
2. A set ends on a game won by the player who takes that set.
3. The match ends on a set won by the player who takes that match.
4. The transcript is correct and complete, so it stops on that final ball. Its last letter names the match winner.

The terms used below:

| Term | Meaning |
|---|---|
| transcript | the string of ball-winner letters in one test case |
| final ball | the last letter of the transcript |
| game winner | the player who takes the points that end a game |
| set winner | the player reaching six games with a two-game lead |
| match winner | the player reaching three set points |

Each term names the same player once the transcript ends.

A script trace of the sample transcript:

```
case N=3, transcript = 48 copies of B
ball  1: points = [0, 1, 0], games this set = [0, 0, 0], set points = [0, 0, 0]
ball  2: points = [0, 2, 0], games this set = [0, 0, 0], set points = [0, 0, 0]
ball  3: points = [0, 3, 0], games this set = [0, 0, 0], set points = [0, 0, 0]
ball  4: points = [0, 0, 0], games this set = [0, 1, 0], set points = [0, 0, 0], game 1 won
ball  8: points = [0, 0, 0], games this set = [0, 2, 0], set points = [0, 0, 0], game 2 won
ball 20: points = [0, 0, 0], games this set = [0, 5, 0], set points = [0, 0, 0], game 5 won
ball 24: points = [0, 0, 0], games this set = [0, 0, 0], set points = [0, 2, 0], game 6 won, set 1 won (worth 2), set points = 2
ball 44: points = [0, 0, 0], games this set = [0, 5, 0], set points = [0, 2, 0], game 11 won
ball 48: points = [0, 0, 0], games this set = [0, 0, 0], set points = [0, 4, 0], game 12 won, set 2 won (worth 2), set points = 4
last letter of transcript = B
```

The simulated winner and the last letter are both B.

## Code

**Constants.** Two fixed values serve the reader and the writer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 16
```

`firstDigitValue` is the byte value of digit zero. `flushBlockBytes` sets a 64 KiB write block. Both values stay fixed across all cases.

**Integer reader.** This proc walks the buffer by index.

```nim
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

`scanPos` skips the spaces around each number. Each digit costs one byte read and one multiply. No substring or parse call is built.

**Winner reader.** This proc finds the final uppercase letter of a transcript.

```nim
proc lastBallWinner(inputData: string, scanPos: var int): char =
  while scanPos < inputData.len and (inputData[scanPos] < 'A' or inputData[scanPos] > 'Z'):
    scanPos += 1
  var winnerLetter = inputData[scanPos]
  while scanPos < inputData.len and inputData[scanPos] >= 'A' and inputData[scanPos] <= 'Z':
    winnerLetter = inputData[scanPos]
    scanPos += 1
  return winnerLetter
```

`winnerLetter` holds the last letter seen, so the scan needs one pass. Uppercase letters are the only token bytes in a transcript. The cost is one byte read per ball.

**Driver.** One input buffer and one output buffer handle the whole file.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for _ in 0 ..< caseCount:
  discard nextInt(inputData, scanPos)
  outputBuffer.add lastBallWinner(inputData, scanPos)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
outputBuffer.setLen 0
```

`caseCount` bounds the one case loop. The player count is read and discarded, since serve order never changes the score. `outputBuffer` grows until `flushBlockBytes`, then reuses its allocation. The final `stdout.write` writes the tail.

## Complexity

The work splits into three passes over bounded data.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all input lines | input bytes |
| Case scan | one pass over each transcript | one letter |
| Output | one write per 64 KiB block | 64 KiB buffer |
| Total for 150 maximum-length cases | about 7.5 million byte reads | input plus 64 KiB |

Input size dominates, and the output stays tiny.

The asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(total transcript length) |
| Space | O(total input bytes) |

A full rules simulation also costs O(total transcript length), but it checks every ball and stores per-player state. The direct scan reads each letter once and stops at the last one.
