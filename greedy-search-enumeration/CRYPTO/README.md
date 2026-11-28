# CRYPTO — Cryptography (SPOJ)

<https://www.spoj.com/problems/CRYPTO/>

## Problem

Decoding the linked substitution cipher reveals the task: add whitespace-separated integer pairs `a` and `b` until EOF.
Despite mentioning integers below `maxlongint`, `#big-numbers` tricky tests require arbitrary-precision signed addition over files up to `4 MB`.
The original statement provides no sample input, so local checks use small arithmetic cases.

## Idea

Read the entire input stream in large byte chunks and scan whitespace-delimited tokens without creating per-token string copies.
Normalize each token in place as `(neg, lo, hi)` by stripping signs and leading zeros (`-0` normalizes to positive zero).

For each pair `(a, b)`:
- If either operand is zero, copy the other normalized span directly to the output buffer.
- If both share the same sign, add digits from right to left in `workBuf`.
- If their signs differ, compare magnitudes first (`cmpMag`) and subtract the smaller from the larger, dropping leading zeros.

## Why It Works

Adding or subtracting decimal strings directly avoids quadratic big-integer conversion overhead on huge inputs.
Because `a` and `b` stay inside the single input buffer as slices, memory stays flat even when a pair has hundreds of thousands of digits.
Stripping leading zeros up front ensures `0` never prints as `-0` and lets `cmpMag` compare lengths before comparing characters.
Writing digits backward from the end of `workBuf` leaves the result contiguous in forward order without reversing a buffer.
Both `200,000`-token files and `400,000`-digit numbers run in linear time over total input bytes.

## Code

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc readInputBytes(): string =
  const chunkSize = 1 shl 16
  var res = ""
  var buf = newString(chunkSize)
  while true:
    let got = readBuffer(stdin, addr buf[0], chunkSize)
    if got <= 0:
      break
    let oldLen = res.len
    res.setLen(oldLen + got)
    copyMem(addr res[oldLen], addr buf[0], got)
  res

proc nextToken(data: string, pos: var int, tokStart, tokEnd: var int): bool {.inline.} =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  if pos >= data.len:
    return false
  tokStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  tokEnd = pos
  true

proc parseSpan(data: string, tokStart, tokEnd: int): tuple[neg: bool, lo, hi: int] {.inline.} =
  var pos = tokStart
  var neg = false
  if pos < tokEnd and (data[pos] == '-' or data[pos] == '+'):
    neg = data[pos] == '-'
    pos += 1
  while pos < tokEnd and data[pos] == '0':
    pos += 1
  if pos == tokEnd:
    neg = false
  (neg, pos, tokEnd)

proc cmpMag(data: string, aLo, aHi, bLo, bHi: int): int {.inline.} =
  let lenA = aHi - aLo
  let lenB = bHi - bLo
  if lenA != lenB:
    if lenA < lenB:
      return -1
    return 1
  for idx in 0 ..< lenA:
    let ca = data[aLo + idx]
    let cb = data[bLo + idx]
    if ca != cb:
      if ca < cb:
        return -1
      return 1
  0

var outBuf = newStringOfCap(flushBlockBytes + 1024)
var workBuf = newString(1024)

proc appendSpan(neg: bool, buf: string, lo, hi: int) {.inline.} =
  let spanLen = hi - lo
  let need = spanLen + 2
  if outBuf.len + need > flushBlockBytes and outBuf.len > 0:
    stdout.write outBuf
    outBuf.setLen(0)
  if neg:
    outBuf.add '-'
  if spanLen >= flushBlockBytes:
    if outBuf.len > 0:
      stdout.write outBuf
      outBuf.setLen(0)
    stdout.write buf[lo ..< hi]
    stdout.write "\n"
    return
  let oldLen = outBuf.len
  outBuf.setLen(oldLen + spanLen + 1)
  copyMem(addr outBuf[oldLen], unsafeAddr buf[lo], spanLen)
  outBuf[oldLen + spanLen] = '\n'
  if outBuf.len >= flushBlockBytes:
    stdout.write outBuf
    outBuf.setLen(0)

proc appendZero() {.inline.} =
  outBuf.add "0\n"
  if outBuf.len >= flushBlockBytes:
    stdout.write outBuf
    outBuf.setLen(0)

proc addMag(data: string, aLo, aHi, bLo, bHi: int, neg: bool) =
  let maxLen = max(aHi - aLo, bHi - bLo) + 1
  if workBuf.len < maxLen:
    workBuf.setLen(maxLen)
  var ia = aHi - 1
  var ib = bHi - 1
  var writePos = maxLen - 1
  var carry = 0
  while ia >= aLo or ib >= bLo or carry > 0:
    var digitSum = carry
    if ia >= aLo:
      digitSum += int(data[ia]) - firstDigitValue
      ia -= 1
    if ib >= bLo:
      digitSum += int(data[ib]) - firstDigitValue
      ib -= 1
    if digitSum >= 10:
      digitSum -= 10
      carry = 1
    else:
      carry = 0
    workBuf[writePos] = char(digitSum + firstDigitValue)
    writePos -= 1
  appendSpan(neg, workBuf, writePos + 1, maxLen)

proc subMag(data: string, bigLo, bigHi, smallLo, smallHi: int, neg: bool) =
  let maxLen = bigHi - bigLo
  if workBuf.len < maxLen:
    workBuf.setLen(maxLen)
  var ia = bigHi - 1
  var ib = smallHi - 1
  var writePos = maxLen - 1
  var borrow = 0
  while ia >= bigLo:
    var diff = int(data[ia]) - firstDigitValue - borrow
    ia -= 1
    if ib >= smallLo:
      diff -= int(data[ib]) - firstDigitValue
      ib -= 1
    if diff < 0:
      diff += 10
      borrow = 1
    else:
      borrow = 0
    workBuf[writePos] = char(diff + firstDigitValue)
    writePos -= 1
  var firstNonZero = writePos + 1
  while firstNonZero < maxLen - 1 and workBuf[firstNonZero] == '0':
    firstNonZero += 1
  appendSpan(neg, workBuf, firstNonZero, maxLen)

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  var aStart, aEnd, bStart, bEnd: int
  while nextToken(inputData, scanPos, aStart, aEnd) and nextToken(inputData, scanPos, bStart, bEnd):
    let a = parseSpan(inputData, aStart, aEnd)
    let b = parseSpan(inputData, bStart, bEnd)
    if a.lo == a.hi and b.lo == b.hi:
      appendZero()
    elif a.lo == a.hi:
      appendSpan(b.neg, inputData, b.lo, b.hi)
    elif b.lo == b.hi:
      appendSpan(a.neg, inputData, a.lo, a.hi)
    elif a.neg == b.neg:
      addMag(inputData, a.lo, a.hi, b.lo, b.hi, a.neg)
    else:
      let cmpVal = cmpMag(inputData, a.lo, a.hi, b.lo, b.hi)
      if cmpVal == 0:
        appendZero()
      elif cmpVal > 0:
        subMag(inputData, a.lo, a.hi, b.lo, b.hi, a.neg)
      else:
        subMag(inputData, b.lo, b.hi, a.lo, a.hi, b.neg)
  if outBuf.len > 0:
    stdout.write outBuf

main()
```

## Complexity

| item | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

Token scanning, magnitude comparison, addition, and subtraction each make one linear pass over total input bytes `N`.
Peak memory holds the full input buffer (`<= 4 MB`), one reusable `workBuf`, and one `128 KB` output buffer.
