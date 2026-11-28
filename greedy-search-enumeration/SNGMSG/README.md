# SNGMSG — Encode Message (SPOJ)

<https://www.spoj.com/problems/SNGMSG/>

## Problem

Decode each message by subtracting a key digit that a bouncing pointer supplies for every character. The pointer walks forward, repeats each end digit, and reverses until the message ends.

The input starts with `T`, the number of test cases. Each case has one key line of digits followed by one encoded line of lowercase letters. The message length is at most 500, and the key value is at most 1000000.

| item | bound |
|---|---|
| test cases | below 10001 |
| message length | at most 500 letters |
| key value | at most 1000000 |
| judge limit | 1000 ms, 1536 MB |

Leading zeros stay significant, so the key is read as text.

The sample input:

```
6
132
nxovdba
212
uitktjvjmc
011
lfbejngafspsasfjnposubot
123
jnrygzpw
11
lfbejngafspsasfjnposubot
130
behipbobu
```

The sample output:

```
mumtaaz
shrishtika
leadingzerosareimportant
iloveyou
keadimfzerorzreimonrtans
abhimanyu
```

## Idea

Treat the key digits like a ball bouncing between two walls, touching each wall twice before turning. Each message letter consumes one digit from that bounce.

The algorithm decodes each character directly. It maps the character index to a key position with one modulo and one subtraction. A pointer simulation would step and reverse at every end, adding state updates per character. The arithmetic position removes that state and costs one modulo per letter.

The bounce position is computed, never simulated.

## Why It Works

1. A key of length L repeats its ends, so one full bounce has period 2L.
2. Positions 0 through L-1 appear first, then positions L-1 down to 0.
3. Tick t maps to position t when t < L, and to 2L-1-t otherwise.
4. Encoding added the key digit modulo 26, so decoding subtracts that digit modulo 26.
5. Adding 26 before the modulo keeps the letter index non-negative for digits 0 to 9.

| term | meaning |
|---|---|
| `keyDigits` | key text, so leading zeros survive |
| `bounceTick` | count of consumed characters |
| `digitPosition` | index into the key for the current character |
| `originalCode` | decoded letter index from 0 to 25 |

Every term is a plain integer, so the decode uses no floating point.

A script trace for key 132 and the first sample message:

```
char keypos digit code decoded
n 0 1 13 12 m
x 1 3 23 20 u
o 2 2 14 12 m
v 2 2 21 19 t
d 1 3 3 0 a
b 0 1 1 0 a
a 0 1 0 25 z
```

The seven decoded letters spell `mumtaaz`, which matches the sample.

## Code

**Input and token reading.** The reader keeps the key as text and the scanner skips whitespace.

```nim
const flushBlockBytes = 1 shl 17

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One `readLine` loop loads all input before parsing starts.
`nextWord` preserves key zeros that an integer parse would drop.
`appendOutput` flushes whole blocks instead of writing each line.

**Direct bounce decode.** Each character uses an arithmetic key position and one modulo.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let keyDigits = nextWord(inputData, scanPos)
  let encodedMessage = nextWord(inputData, scanPos)
  let keyLength = keyDigits.len
  let bounceLength = 2 * keyLength
  var decodedMessage = newString(encodedMessage.len)
  var bounceTick = 0
  for messageIndex in 0 .. encodedMessage.len - 1:
    var digitPosition = bounceTick mod bounceLength
    if digitPosition >= keyLength:
      digitPosition = bounceLength - 1 - digitPosition
    let shift = int(keyDigits[digitPosition]) - 48
    let originalCode = (int(encodedMessage[messageIndex]) - 97 - shift + 26) mod 26
    decodedMessage[messageIndex] = chr(originalCode + 97)
    bounceTick += 1
  appendOutput(decodedMessage)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per encoded letter, at most 500 times per case.
The `+ 26` guard moves a negative subtraction back into the alphabet range.
The final write flushes the buffered answers after the last case.

## Complexity

Each case touches every letter once and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over the input text | one input string |
| decode | one modulo and one write per letter | one output string |
| output | one write per block | block buffer |

The decode phase dominates and grows with total message length.

| measure | Big O |
|---|---|
| time | O(total message length) |
| space | O(longest message) |

A pointer simulation also runs in linear time but updates direction state per letter. The arithmetic position keeps that constant small and ends the decode with one buffered write.
