# ATMS — Automatic Teller Machines (SPOJ)
<https://www.spoj.com/problems/ATMS/>

## Problem

A borrower must assemble an exact amount from 100 ATMs that pay or collect powers of two.
The bank needs a recipe to obtain each loan and another to return it, or a refusal.

The first line gives the client count. Each next line holds a positive integer below 10 to the thirtieth power, written with at most 30 digits. Print two lines per client with ATM numbers in decreasing order, or the word No.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Clients n | up to 10000 |
| Amount | fewer than 30 decimal digits |
| ATMs | numbered 0 to 99 |
| Judge time | 5 s |
| Judge memory | 1536 MB |

Decimal digit arithmetic handles amounts far beyond 64 bits.

The sample input and its expected output follow byte for byte.

```
2
7
633825300114114700748351602698
```

```
4 3 1 0
3 0
No
99 3 1
```


## Idea

Convert the amount to signed binary digits (plus or minus powers of two), like writing a number on a balanced scale.
The program walks the decimal digits from low to high and keeps the current sign. On each step it records a used bit, adjusts the low digit by one, and divides the whole digit array by two.
Two calls with opposite starting signs give the obtain recipe and the return recipe. Trying subsets of 100 ATMs is impossible, while this scan takes a few hundred digit steps.
A signed bit expansion gives both recipes in one short loop.

## Why It Works

1. Even ATMs pay a power of two, and odd ATMs collect one. Each used bit therefore contributes a signed power of two.
2. Dividing by two after the adjustment reveals the next bit of the signed expansion.
3. With a negative sign, an odd digit is raised by one so the step subtracts one unit; otherwise it is lowered by one.
4. `usedBits` records the exponents, and an exponent above 99 produces No.
5. The decreasing output order follows directly from walking the bits downward.

Four terms describe the scan.

| Term | Meaning |
| --- | --- |
| signed bit | one used exponent with a plus or minus sign |
| sign flag | current direction of the next adjustment |
| used bit | ATM exponent chosen on this step |
| digit array | decimal amount stored low digit first |

They explain why one scan covers both recipes.

A script check of 7 records bits 0, 1, 3, and 4 with signs plus, minus, minus, plus.
That sum is 16 minus 8 minus 2 plus 1, which equals 7.
Printing the exponents downward gives 4 3 1 0, matching the sample.

## Code

**Digit loader.**
```nim
proc nextDigits(data: string, position: var int, digits: var array[0..digitCapacity - 1, int]) =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var tokenEnd = position
  while tokenEnd < data.len and data[tokenEnd] >= '0' and data[tokenEnd] <= '9':
    tokenEnd += 1
  for i in 0..<digitCapacity:
    digits[i] = 0
  var digitIndex = 0
  var k = tokenEnd - 1
  while k >= position:
    digits[digitIndex] = int(data[k]) - firstDigitValue
    digitIndex += 1
    k -= 1
  position = tokenEnd
```

The loader stores the token low digit first. Old values are cleared before each client. The parser stops at the end of the digit token.

**Zero test.**
```nim
proc digitsAreZero(digits: array[0..digitCapacity - 1, int]): bool =
  for i in 0..<digitCapacity:
    if digits[i] != 0:
      return false
  return true
```

The test checks the fixed digit array. It ends the main loop once every digit is zero. The cost is one pass over 40 slots.

**Signed bit expansion.**
```nim
proc appendAtmList(valueDigits: array[0..digitCapacity - 1, int], negative: bool) =
  var workDigits = valueDigits
  var signNegative = negative
  var usedBits: array[0..bitCapacity - 1, bool]
  var highestBit = -1
  var bitIndex = 0
  while not digitsAreZero(workDigits):
    let oddDigit = workDigits[0] mod 2
    if oddDigit == 1:
      usedBits[bitIndex] = true
      highestBit = bitIndex
    if signNegative:
      if oddDigit == 1:
        var digitIndex = 0
        while true:
          let raised = workDigits[digitIndex] + 1
          workDigits[digitIndex] = raised mod 10
          if raised < 10:
            break
          digitIndex += 1
    elif oddDigit == 1:
      var digitIndex = 0
      while workDigits[digitIndex] == 0:
        workDigits[digitIndex] = 9
        digitIndex += 1
      workDigits[digitIndex] -= 1
    var carry = 0
    for i in countdown(digitCapacity - 1, 0):
      let current = carry * 10 + workDigits[i]
      workDigits[i] = current div 2
      carry = current mod 2
    signNegative = not signNegative
    bitIndex += 1
  if highestBit > lastAtmIndex:
    appendOutput("No")
  else:
    var firstNumber = true
    for i in countdown(highestBit, 0):
      if usedBits[i]:
        if not firstNumber:
          outputBuffer.add ' '
        appendOutput($(i))
        firstNumber = false
  outputBuffer.add '\n'
```

An odd digit selects one ATM exponent. The low digit is raised or lowered based on the sign flag. A long division by two advances to the next exponent.

**Client driver.**
```nim
let caseCount = nextInt(inputData, scanPos)
var valueDigits: array[0..digitCapacity - 1, int]
for caseIndex in 0..<caseCount:
  nextDigits(inputData, scanPos, valueDigits)
  appendAtmList(valueDigits, false)
  appendAtmList(valueDigits, true)

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each client is processed twice, once per sign. The two calls emit the obtain and return lines. A single write flushes all collected text.


## Complexity

The loop runs for a few hundred bit steps, each touching a fixed digit array.

| Phase | Time | Space |
| --- | --- | --- |
| digit loading | O(D) | digit array |
| signed expansion | O(bits times D) | used bit array |
| output | O(bits) | one output block |

The fixed arrays make the work predictable for the largest amount.

Big O uses D as the digit count and B as the number of bit steps.

| Measure | Big O |
| --- | --- |
| time | O(B times D) per client |
| space | O(D) |

Subset search over 100 ATMs would need two to the hundredth power trials.
