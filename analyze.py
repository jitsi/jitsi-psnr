#!/usr/bin/env python
import pandas as pd
import sys
import math

# This is assumed to be the *capture* frame frequency, so each frame period
# (i.e. how much time it takes for a new frame to be captured) is 1/FREQUENCY.

FREQUENCY = 30/1000
PERIOD_MS = 1/FREQUENCY

def read_csv(filepath):
    return pd.read_csv(filepath, index_col='capture_frame', delimiter=' ')

def augment_dataframe(df):
    df['next_input_frame'] = df['input_frame'].shift(-1)
    df['previous_input_frame'] = df['input_frame'].shift(1)

    periods = []
    # Compare each frame from 1 to n - 1 with the next one computing how long
    # we stayed on a particular frame along the way.
    current_period = PERIOD_MS
    for capture_frame, row in df.iterrows():
        # Compare frame i with i + 1 to see if the frame has changed.
        input_frame = row['input_frame']
        next_input_frame = row['next_input_frame']
        previous_input_frame = row['previous_input_frame']

        if math.isnan(next_input_frame):
            # This is handling the last frame.
            if input_frame != previous_input_frame:
                periods.append(PERIOD_MS)
            else:
                periods.append(current_period)
        elif input_frame != next_input_frame:
            periods.append(current_period)
            current_period = PERIOD_MS
        else:
            current_period = current_period + PERIOD_MS
            periods.append(None)

    df['period'] = periods
    df = df.drop('next_input_frame', axis=1) # drop helper column
    df = df.drop('previous_input_frame', axis=1) # drop helper column

    return df

def plot_dataframe(df, label, ax_psnr, ax_period):
    ax_psnr.plot(df.index * PERIOD_MS, df['psnr'], label=label)
    ax_period.plot(df.index * PERIOD_MS, df['period'], label=label)

def trim_dataframe(df):
    df = df.dropna()
    # assume it takes no more than 10s to setup the UI
    df = df.tail(len(df) - 300) 
    # assume it takes no more than 5 frames for OS artifacts to dissapear.
    return df.head(len(df) - 5)

def trim_dataframes(df_list):
    return list(map(lambda df: trim_dataframe(df), df_list))

def plot_command():
    import matplotlib.pyplot as plt
    import os
    if len(sys.argv) >= 4:
        f, (ax1, ax2) = plt.subplots(2, sharex=True)
        commonprefix = None
        df_list = []
        file_list = []
        for i in range(2, len(sys.argv)):
            filename = sys.argv[i]
            if commonprefix is None:
                commonprefix = filename
            else:
                commonprefix = os.path.commonprefix([filename, commonprefix])
            df_list.append(read_csv(filename))
            file_list.append(filename)

        df_list = trim_dataframes(df_list)
        for i in range(0, len(df_list)):
            label = file_list[i][len(commonprefix):-4]
            plot_dataframe(df_list[i], label, ax1, ax2)

        ax2.legend()
        plt.savefig(commonprefix.rstrip('_') + '.png')
    elif len(sys.argv) == 3:
        filename1 = sys.argv[2]
        df1 = read_csv(filename1)
        f, (ax1, ax2) = plt.subplots(2, sharex=True)
        plot_dataframe(df1, None, ax1, ax2)
        ax2.legend()
        plt.savefig(sys.argv[2].replace('csv', 'png'))

def compute_freezes(df1, freeze_threshold_ms):
    freeze_duration = df1[df1['period'] > freeze_threshold_ms]['period'].sum()
    total_duration = len(df1) * PERIOD_MS
    print(str(freeze_threshold_ms) + ' freeze percentage: ' + str(freeze_duration / total_duration))

def describe_command():
    df = read_csv(sys.stdin)
    compute_freezes(df, 70)
    compute_freezes(df, 100)

def trim_command():
    df = trim_dataframe(read_csv(sys.stdin))
    df.to_csv(sys.stdout, sep=' ')

def augment_command():
    df = augment_dataframe(read_csv(sys.stdin))
    df.to_csv(sys.stdout, sep=' ')

def main():
    if sys.argv[1] == "plot":
        plot_command()
    elif sys.argv[1] == "trim":
        trim_command()
    elif sys.argv[1] == "describe":
        describe_command()
    elif sys.argv[1] == "augment":
        augment_command()

if __name__ == "__main__":
    main()
