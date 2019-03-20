#!/usr/bin/env python
import matplotlib.pyplot as plt
import pandas as pd
import sys
import math
import os

# This is assumed to be the *capture* frame frequency, so each frame period
# (i.e. how much time it takes for a new frame to be captured) is 1/FREQUENCY.

FREQUENCY = 30/1000
PERIOD_MS = 1/FREQUENCY
FREEZE_THRESHOLD_MS = 70

def read_csv(filepath):
    df = pd.read_csv(filepath, index_col='frame_num', delimiter=' ')
    return augment_dataframe(df)

def augment_dataframe(df):
    df['next_sequence_num'] = df['sequence_num'].shift(-1)

    periods = []
    # Compare each frame from 1 to n - 1 with the next one computing how long
    # we stayed on a particular frame along the way.
    current_period = PERIOD_MS
    prev_seq_num = None
    for frame_num, row in df.iterrows():
        # Compare frame i with i + 1 to see if the frame has changed.
        cur_seq_num = row['sequence_num']
        next_seq_num = row['next_sequence_num']
        if math.isnan(cur_seq_num) or cur_seq_num < 1 or next_seq_num < 1:
            raise Exception('Illegal sequence number')

        if math.isnan(next_seq_num):
            # This is handling the last frame.
            if cur_seq_num != prev_seq_num:
                periods.append(PERIOD_MS)
            else:
                periods.append(current_period)
        elif cur_seq_num != next_seq_num:
            periods.append(current_period)
            current_period = PERIOD_MS
        else:
            current_period = current_period + PERIOD_MS
            periods.append(None)

        prev_seq_num = cur_seq_num

    df['period'] = periods
    df = df.drop('next_sequence_num', axis=1) # drop helper column

    return df

def plot_dataframe(df, label, ax_psnr, ax_period):
    ax_psnr.plot(df.index * PERIOD_MS, df['psnr'], label=label)
    ax_period.plot(df.index * PERIOD_MS, df['period'], label=label)

def align_dataframes(df_list):
    new_df_list = []
    # The end frame corresponds to the instant when the experiment ends (because
    # mahimahi is run with TIMEOUT(1)). So we can align the dataframes by the
    # end frame. The start frame can correspond to different instants depending
    # the time it takes for the first media to appear.
    min_end = min(map(lambda df: df.index.max(), df_list))
    max_start = max(map(lambda df: df[df.psnr.notnull()].index.min(), df_list))
    for df in df_list:
        end = df.index.max()
        df = df[df.index >= max_start]
        df = df.shift(min_end - end)
        df = df[df.psnr.notnull()]
        new_df_list.append(df)

    return new_df_list

def plot_command():
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

        df_list = align_dataframes(df_list)
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

def describe_command():
    args_len = len(sys.argv)
    df_list = []
    file_list = []
    for i in range(2, args_len):
        filename1 = sys.argv[i]
        df_list.append(read_csv(filename1))
        file_list.append(filename1)

    df_list = align_dataframes(df_list)
    for i in range(0, len(df_list)):
        print(file_list[i])
        df1 = df_list[i]
        print(df1.describe())
        freeze_duration = df1[df1['period'] > FREEZE_THRESHOLD_MS]['period'].sum()
        total_duration = (df1.index.max() - df1.index.min()) * PERIOD_MS
        print('Total duration: ' + str(total_duration))
        print('Freeze duration: ' + str(freeze_duration))
        print('Freeze percentage: ' + str(freeze_duration / total_duration))

def main():
    if sys.argv[1] == "plot":
        plot_command()
    elif sys.argv[1] == "describe":
        describe_command()
    elif len(sys.argv) == 2:
        filename1 = sys.argv[1]
        df1 = read_csv(filename1)
        df1.to_csv(sys.stdout, sep=' ')

if __name__ == "__main__":
    main()
