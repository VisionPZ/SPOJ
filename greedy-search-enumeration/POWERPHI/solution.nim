const flushBlockBytes = 1 shl 17
const answerModulus: int64 = 1000000007'i64

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

proc fibonacciPair(exponentValue: int64): (int64, int64) =
  if exponentValue == 0:
    return (0'i64, 1'i64)
  let halfExponent = exponentValue div 2
  let (halfFibonacci, halfSuccessor) = fibonacciPair(halfExponent)
  let doubledSuccessor = (2'i64 * halfSuccessor) mod answerModulus
  let difference = (doubledSuccessor - halfFibonacci + answerModulus) mod answerModulus
  let evenFibonacci = (halfFibonacci * difference) mod answerModulus
  let evenSuccessor = (halfFibonacci * halfFibonacci + halfSuccessor * halfSuccessor) mod answerModulus
  if (exponentValue and 1'i64) == 0'i64:
    return (evenFibonacci, evenSuccessor)
  return (evenSuccessor, (evenFibonacci + evenSuccessor) mod answerModulus)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let exponentValue = int64(nextInt(inputData, scanPos))
  var answerValue: int64
  if exponentValue == 0:
    answerValue = 1'i64
  elif exponentValue == 1:
    answerValue = 2'i64
  else:
    let (termFibonacci, termSuccessor) = fibonacciPair(exponentValue)
    answerValue = (2'i64 * termSuccessor - termFibonacci) mod answerModulus
    if answerValue < 0:
      answerValue += answerModulus
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
