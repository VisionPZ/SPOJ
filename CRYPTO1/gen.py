import datetime
import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

MODULUS = 4000000007
WEEKDAY = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
MONTH = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
EPOCH = datetime.datetime(1970, 1, 1, tzinfo=datetime.timezone.utc)


def clock_line(seconds):
    moment = EPOCH + datetime.timedelta(seconds=seconds)
    return "%s %s %2d %02d:%02d:%02d %d" % (
        WEEKDAY[moment.weekday()], MONTH[moment.month - 1], moment.day,
        moment.hour, moment.minute, moment.second, moment.year)


def encrypt(seconds):
    return "%d\n" % (seconds * seconds % MODULUS)


def write(name, seconds_list):
    open("in/%s.txt" % name, "w").write("".join(encrypt(s) for s in seconds_list))
    open("out/%s.out" % name, "w").write("".join(clock_line(s) + "\n" for s in seconds_list))


SAMPLE_SECONDS = 1087143639
assert encrypt(SAMPLE_SECONDS) == "1749870067\n"
assert clock_line(SAMPLE_SECONDS) == "Sun Jun 13 16:20:39 2004"

write("1_sample", [SAMPLE_SECONDS])

edge = [0, 1, 59, 3600, 86399, 86400, 1893456000, 1899999999,
        952051199, 952051200, 2147483647 // 1]
edge = [s for s in edge if 0 <= s <= 1900000000]
edge = [0, 1, 60, 3599, 86399, 86400, 952051199, 952051200, 1893456000, 1899999999]
write("2_edges", edge)

rng = random.Random(1)
leap_day = int((datetime.datetime(2000, 2, 29, tzinfo=datetime.timezone.utc) - EPOCH).total_seconds())
wide = [leap_day, leap_day + 86400, leap_day - 1] + [rng.randrange(0, 1900000000) for _ in range(7)]
write("3_wide", wide)

rng2 = random.Random(7)
random_seconds = [rng2.randrange(0, 1900000000) for _ in range(1000)]
write("4_random", random_seconds)

rng3 = random.Random(11)
io_seconds = [rng3.randrange(0, 1900000000) for _ in range(50000)]
write("5_io", io_seconds)
