## Problem

Read a list of stone colors. Cut the string once, then discard stones from both parts. The two remaining strings must match, either as written or after one is rotated by 180 degrees. Print the largest total length of the two matching strings and the smallest cut position that achieves it.

| Quantity | Bound |
| --- | --- |
| Test cases | 500 |
| Characters per case | 8000 |
| Total input size | 100 kB |
| Time limit | 25000 ms |
| Memory limit | 1536 MB |

The total input size sets the scale, so each character must cost a small fixed amount.

## Idea

Compute the longest common subsequence for every cut in one sweep per direction. The first sweep compares the prefix with the suffix in the same order. The second sweep compares the prefix with the reversed suffix. Each sweep uses a one-dimensional state array and visits every character pair once. Recomputing an LCS from scratch for every cut would cost cubic time.

Each sweep costs O(n²) time and O(n) memory for a string of n characters.

## Why It Works

For a cut at position c, the kept stones form a common subsequence of the left part and the right part. A rotation reverses the right part before comparison.

The first sweep follows the ALCS recurrence. It tracks two boundary values per column:

- `curHorizontal[j]`: the lowest left-row where the horizontal gain reaches column j.
- `curVertical[j]`: the highest left-row where the vertical gain reaches column j.
- On a letter match, both values swap their sources.
- On a mismatch, the horizontal value takes the larger source and the vertical value takes the smaller one.

After row i, each column j gives one gain boundary. Count the boundaries in columns after i whose value is at most i. That count is the LCS of the prefix of length i with the suffix starting at i + 1. The `+1` accounts for column i itself, which always matches.

The second sweep builds chains of matching pairs. A pair links a stone left of the cut with a stone right of the cut. The right index decreases as the left index grows, which models the rotated earring. The array `revMatch` stores the best chain ending at each left stone. Propagating the maximum makes every prefix value available.

The generator prints the boundary row for `abcbca` at i = 2 as `0 0 3 2 5 4`. Only column 4 has a value at most 2, so the straight comparison gives length 1. The rotated comparison gives length 2 at cut 2. The answer is therefore `4 2`.

## Code

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The whole input is read into one buffer before parsing. The bounds check is disabled for the hot loops. Reading line by line here happens once, not once per answer. The cost is linear in the input size.

```nim
proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips separators and builds each integer by hand. The output buffer flushes after flushBlockBytes bytes. One write then covers many answers. Each buffer flush costs one stream write.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  while scanPos < inputData.len and (inputData[scanPos] < 'a' or inputData[scanPos] > 'z'):
    scanPos += 1
  let strStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] >= 'a' and inputData[scanPos] <= 'z':
    scanPos += 1
  let strLen = scanPos - strStart
```

The inner loops skip leading whitespace and keep each color string in place. No substring is copied. The cost is one pass over the input characters.

```nim
  var straightMatch = newSeq[uint16](strLen + 1)
  if strLen >= 2:
    var prevHorizontal = newSeq[uint16](strLen + 1)
    var curHorizontal = newSeq[uint16](strLen + 1)
    var curVertical = newSeq[uint16](strLen + 1)
    for j in 0..strLen:
      prevHorizontal[j] = uint16(j)
    for i in 1..strLen:
      curVertical[0] = 0
      let leftLetter = inputData[strStart + i - 1]
      for j in 1..strLen:
        if leftLetter == inputData[strStart + j - 1]:
          curHorizontal[j] = curVertical[j - 1]
          curVertical[j] = prevHorizontal[j]
        else:
          let across = curVertical[j - 1]
          let above = prevHorizontal[j]
          curHorizontal[j] = if across > above: across else: above
          curVertical[j] = if across < above: across else: above
      if i < strLen:
        var reached = 0
        for j in (i + 1)..strLen:
          if curHorizontal[j] <= uint16(i):
            reached += 1
        straightMatch[i] = uint16(reached)
      swap prevHorizontal, curHorizontal
```

The row loop runs once per left prefix length. The column loop runs once per right position. The counting loop skips column i and every column before it. Swapping the two row arrays avoids a copy. The sweep costs O(n²) time and three arrays of n + 1 values.

```nim
  var revMatch = newSeq[uint16](strLen + 1)
  if strLen >= 2:
    for j in countdown(strLen - 1, 1):
      for p in countdown(j - 1, 0):
        if inputData[strStart + p] == inputData[strStart + j]:
          let candidate = (if p > 0: int(revMatch[p - 1]) else: 0) + 1
          if candidate > int(revMatch[p]):
            revMatch[p] = uint16(candidate)
      for p in 1..<strLen:
        if revMatch[p - 1] > revMatch[p]:
          revMatch[p] = revMatch[p - 1]
      revMatch[j] = revMatch[j - 1]
```

The outer loop adds one right stone at a time. The inner loop extends chains from the left. The forward pass makes the array non-decreasing, so every shorter prefix is ready. The result at index j is the rotated LCS for cut j. This sweep also costs O(n²) time and one array.

```nim
  var bestLength = 0
  var bestCut = 1
  for cut in 1..<strLen:
    let oneSide = int(straightMatch[cut])
    let turnedSide = int(revMatch[cut])
    let pairLength = 2 * (if oneSide > turnedSide: oneSide else: turnedSide)
    if pairLength > bestLength:
      bestLength = pairLength
      bestCut = cut
  appendOutput($(bestLength) & " " & $(bestCut) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan visits cuts from left to right. A strict comparison keeps the leftmost cut on ties. The final write flushes the partial output block. One answer costs one scan over the cuts.

## Complexity

Reading costs O(n) time and O(n) space for one input buffer. The straight sweep costs O(n²) time and O(n) space. The rotated sweep costs O(n²) time and O(n) space. Output costs O(t) time and one block of space.

Total time is O(n²) per case and O(1) extra space beyond the buffers. A fresh LCS for every cut would cost O(n³) time per case.
