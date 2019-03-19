#!/usr/bin/env python
import matplotlib.pyplot as plt
import pandas as pd
import sys

# This is assumed to be the *capture* frame frequency, so each frame period
# (i.e. how much time it takes for a new frame to be captured) is 1/FREQUENCY.

FREQUENCY = 30/1000
PERIOD_MS = 1/FREQUENCY

def read_csv(filepath):
    df = pd.read_csv(filepath, index_col='frame_num', delimiter=' ')

    frame_num_start = df.index.min()
    frame_num_end = len(df) + frame_num_start - 1

    instants = []
    periods = []

    # Compare each frame from 1 to n - 1 with the next one computing how long
    # we stayed on a particular frame along the way.
    current_period = PERIOD_MS
    current_instant = 0
    for frame_num in range(frame_num_start, frame_num_end):
        instants.append(current_instant)
        current_instant += PERIOD_MS

        # Compare frame i with i + 1 to see if the frame has changed.
        cur_seq_num = df.loc[frame_num, 'sequence_num']
        next_seq_num = df.loc[frame_num + 1, 'sequence_num']
        if cur_seq_num < 1 or next_seq_num < 1:
            # we failed to read the sequence number of either the current or the
            # next frame.
            periods.append(current_period)
            current_period = PERIOD_MS
        elif cur_seq_num != next_seq_num:
            periods.append(current_period)
            current_period = PERIOD_MS
        else:
            current_period = current_period + PERIOD_MS
            periods.append(None)

    # This is for the last frame, we can't check whether it's changed or not.
    periods.append(None)
    instants.append(None)

    df['time'] = instants
    df['period'] = periods

    return df

def plot_file(df, ax_psnr, ax_period):
    #df = df[df['psnr'] > -1]
    ax_psnr.plot(df['time'], df['psnr'])
    ax_period.plot(df['time'], df['period'])

def main():
    if sys.argv[1] == "plot":
        if len(sys.argv) >= 4:
            f, (ax1, ax2) = plt.subplots(2, sharex=True)
            for i in range(2, len(sys.argv)):
                filename = sys.argv[i]
                df = read_csv(filename)
                plot_file(df, ax1, ax2)
            plt.savefig('/home/gpolitis/Videos/compare.png')
        elif len(sys.argv) == 3:
            filename1 = sys.argv[2]
            df1 = read_csv(filename1)
            f, (ax1, ax2) = plt.subplots(2, sharex=True)
            plot_file(df1, ax1, ax2)
            plt.savefig(sys.argv[2].replace('csv', 'pdf'))
    elif sys.argv[1] == "describe":
        filename1 = sys.argv[2]
        df1 = read_csv(filename1)
        print(df1.describe())
    elif len(sys.argv) == 2:
        filename1 = sys.argv[1]
        df1 = read_csv(filename1)
        df1.to_csv(sys.stdout, sep=' ')

if __name__ == "__main__":
    main()
