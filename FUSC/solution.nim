const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var fib: array[64, int64]
fib[0] = 0
fib[1] = 1
for index in 2 .. 63:
  fib[index] = fib[index - 1] + fib[index - 2]

proc subtreeMax(leftValue, rightValue: int64, remaining: int): int64 =
  if remaining == 0: return leftValue
  let higher = fib[remaining + 1]
  let lower = fib[remaining]
  return max(higher * leftValue + lower * rightValue,
             lower * leftValue + higher * rightValue)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let limit = nextInt(inputData, scanPos)
if limit == 0:
  appendOutput("0")
else:
  var remainingDigits = ""
  var temporary = limit
  while temporary > 1:
    remainingDigits.add char(firstDigitValue + int(temporary mod 2))
    temporary = temporary div 2

  var remainingBits = remainingDigits.len
  var answer = fib[remainingBits + 1]
  var leftValue = 1'i64
  var rightValue = 1'i64

  var digitIndex = remainingDigits.len - 1
  while digitIndex >= 0:
    remainingBits -= 1
    if remainingDigits[digitIndex] == '1':
      answer = max(answer, subtreeMax(leftValue, leftValue + rightValue, remainingBits))
      leftValue = leftValue + rightValue
    else:
      let nextRight = leftValue + rightValue
      rightValue = nextRight
    digitIndex -= 1

  answer = max(answer, leftValue)
  appendOutput($answer)

outputBuffer.add '\n'
stdout.write outputBuffer
