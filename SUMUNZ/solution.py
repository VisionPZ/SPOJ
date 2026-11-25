import sys

firstDigitValue = 48
minusSignValue = 45


def nextSignedNumber(data, position):
    length = len(data)
    while position < length:
        byteValue = data[position]
        if firstDigitValue <= byteValue <= firstDigitValue + 9 or byteValue == minusSignValue:
            break
        position += 1
    sign = 1
    if position < length and data[position] == minusSignValue:
        sign = -1
        position += 1
    value = 0
    found = position < length
    while position < length and firstDigitValue <= data[position] <= firstDigitValue + 9:
        value = value * 10 + data[position] - firstDigitValue
        position += 1
    return sign * value, position, found


inputData = sys.stdin.buffer.read()
scanPos = 0
total = 0
while True:
    elementValue, scanPos, found = nextSignedNumber(inputData, scanPos)
    if not found:
        break
    if elementValue == 0:
        break
    total += elementValue

sys.stdout.write(str(total) + "\n")
