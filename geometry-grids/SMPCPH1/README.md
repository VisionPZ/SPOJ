# SMPCPH1 — Substitution cipher (SPOJ)

<https://www.spoj.com/problems/SMPCPH1/>

## Problem

Rotate a private alphabet by one place, then replace every matching plain letter with its successor. The last key letter maps back to the first, and all other characters pass through unchanged.

Input: `n`, then `n` distinct key characters, then `m`, then `m` lines of plaintext.
Output: the encoded lines, one line per plaintext line.

| item | bound |
|---|---|
| key length `n` | 2 to 26 |
| line count `m` | 2 to 100 |
| plain text length | at most 1000 characters |
| plain text alphabet | spaces and lowercase Latin letters |
| judge limit | 1000 ms |
| memory | 1536 MB |

Verbatim sample from the statement:

```
6
spojit
3
after this training 
we will solve even
difficult and tricky problems easily
```

```
afser shtp sratntng
we wtll pjlve even
dtfftculs and srtcky orjblemp eaptly
```

## Idea

Picture a round table of labeled chairs. Each key letter points to the next chair, and the final letter points back to the first one.

The real algorithm is a direct substitution table of 26 entries, filled once from the key. Each character costs one array lookup, so the total cost is linear in the text length.

## Why It Works

1. The key letters are distinct, so every mapping target is defined exactly once.
2. Index `ord(character) - 97` turns each lowercase letter into a table slot.
3. Characters outside the key keep their default mapping to themselves.
4. Spaces, newlines, and tabs are copied verbatim, so line structure survives.
5. Trailing spaces on each output line are trimmed, matching the printed sample.

| term | meaning |
|---|---|
| `cipherKey` | the `n` distinct key letters |
| `substitution` | array of 26 characters, one per lowercase letter |
| `plaintextLineCount` | m, the number of text lines |
| `lineBuffer` | the current encoded line before it is written |

Script-generated mapping for the sample key `spojit`:

```
s -> p   p -> o   o -> j   j -> i   i -> t   t -> s
"after" -> "afser"
"this"  -> "shtp"
"training" -> "sratntng"
```

The cipher is a single cycle of length six, so applying it six times returns the original word.

## Code

**Constants and integer reader.** Reads the key length and the line count.

```nim
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, pos: var int): int =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9'):
    pos += 1
  var value = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    value = value * 10 + int(inputData[pos]) - 48
    pos += 1
  return value
```

Non-digits are skipped before the first digit. The scan position is shared through the variable parameter.

**Key reader and line trimmer.** Takes exactly `n` non-space characters and removes trailing blanks.

```nim
proc readKey(inputData: string, pos: var int, keyLength: int): string =
  result = ""
  while result.len < keyLength:
    while pos < inputData.len and inputData[pos] <= ' ':
      pos += 1
    if pos >= inputData.len:
      break
    result.add inputData[pos]
    pos += 1

proc trimLine(lineBuffer: var string) =
  while lineBuffer.len > 0:
    let lastChar = lineBuffer[lineBuffer.len - 1]
    if lastChar == ' ' or lastChar == '\t' or lastChar == '\r':
      lineBuffer.setLen lineBuffer.len - 1
    else:
      break
```

`readKey` ignores whitespace, so a key spread over lines still works. `trimLine` shortens the buffer in place, without a new string.

**Table build.** Fills the 26-slot table from the key cycle.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let keyLength = nextInt(inputData, pos)
let cipherKey = readKey(inputData, pos, keyLength)
let plaintextLineCount = nextInt(inputData, pos)

var substitution: array[26, char]
for index in 0 ..< 26:
  substitution[index] = chr(97 + index)
for index in 0 ..< keyLength:
  let sourceChar = cipherKey[index]
  let targetChar = cipherKey[(index + 1) mod keyLength]
  substitution[ord(sourceChar) - 97] = targetChar

while pos < inputData.len and inputData[pos] != '\n':
  pos += 1
if pos < inputData.len:
  pos += 1
```

The default table is the identity map. The `mod` expression wraps the last key letter to the first one. The scan then jumps to the first plaintext line.

**Encoded writer.** Processes exactly the requested lines and flushes in blocks.

```nim
var outputBuffer = ""
var lineBuffer = ""
for _ in 0 ..< plaintextLineCount:
  lineBuffer.setLen 0
  while pos < inputData.len and inputData[pos] != '\n':
    let currentChar = inputData[pos]
    pos += 1
    if currentChar >= 'a' and currentChar <= 'z':
      lineBuffer.add substitution[ord(currentChar) - 97]
    else:
      lineBuffer.add currentChar
  if pos < inputData.len:
    pos += 1
  trimLine lineBuffer
  outputBuffer.add lineBuffer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

Reusing `lineBuffer` keeps allocations low. The final write covers the tail after the last block flush.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| table build | 26 + key length steps | 26 characters |
| text encoding | one step per plain character | one line |
| output | one write per 128 KiB block | 128 KiB |

| measure | Big O |
|---|---|
| time | O(key length + text length) |
| space | O(26 + longest line) |

A search through the key for each letter would cost O(key length) per character. The direct table reduces that to one indexed load per character.
