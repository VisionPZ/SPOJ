import sys

firstDigitValue = 48


def nextNumber(data, position):
    length = len(data)
    while position < length and not (firstDigitValue <= data[position] <= firstDigitValue + 9):
        position += 1
    value = 0
    found = position < length
    while position < length and firstDigitValue <= data[position] <= firstDigitValue + 9:
        value = value * 10 + data[position] - firstDigitValue
        position += 1
    return value, position, found


try:
    sys.set_int_max_str_digits(10000000)
except AttributeError:
    pass

inputData = sys.stdin.buffer.read()
scanPos = 0
maxValue, scanPos, found = nextNumber(inputData, scanPos)
factorialValue = 1
multiplier = 2
while multiplier <= maxValue:
    factorialValue *= multiplier
    multiplier += 1
sys.stdout.write(str(factorialValue) + "\n")
