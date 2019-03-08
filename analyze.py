#!/usr/bin/env python
import matplotlib.pyplot as plt
import pandas as pd
import sys

# This is assumed to be the *capture* frame rate, so each frame duration is
# 1/FPMS.

FPMS = 30/1000
DURATION_MS = 1/FPMS

filepath = sys.argv[1]
df = pd.read_csv(filepath, index_col='frame_num', delimiter=' ')

time = 0
times = []
durations = []

# Compare each frame from 1 to n - 1 with the next one computing how long
# we stayed on a particular frame along the way.
current_duration = DURATION_MS
for i in range(1, len(df)):
    times.append(time)
    time += DURATION_MS

    # Compare frame i with i + 1 to see if the frame has changed.
    if df.loc[i, 'seqno'] != df.loc[i + 1, 'seqno']:
        durations.append(current_duration)
        current_duration = DURATION_MS
    else:
        current_duration = current_duration + DURATION_MS
        durations.append(None)

# This is for the last frame, we can't check whether it's changed or not.
durations.append(None)
times.append(None)

df['time'] = times
df['duration'] = durations

print(df.describe())
df.plot(x='time',y=['psnr', 'duration'], subplots=True, title=filepath)
plt.show()
