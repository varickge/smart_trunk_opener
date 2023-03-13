import argparse
import os
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


def kick_detection(recording):
    """Kick detection based on target.npy"""

    print("Starting offline kick prediction!")

    if not os.path.exists(recording):
        print("Error: Recording not found:" + str(recording))
        return

    target = np.load((recording))

    PRT = 0.500e-3
    numPCs = 2
    N_FFT = 32
    c = 3e8
    fc = 24.2e9
    lambda_ = c / fc

    TH = 100
    targetLen = 2
    FrameTime = 40e-3
    Fsamp = 1 / PRT
    time_avg_len = 10

    buff_size = 50
    buffer_average_vel = np.zeros((buff_size, 2))
    buffer_mov_average_vel = np.zeros((buff_size, 2))
    buffer_average_acc = np.zeros((buff_size, 2))
    buffer_mov_average_acc = np.zeros((buff_size, 2))

    buffer_kick_start = 1
    buffer_kick_stop = 0

    start_index = []
    stop_index = []

    # Kick detection variables
    kick_detected = 0
    detection_speed = 1 / 40  # m/s
    considertargetLen = 2

    frame_count = target.shape[0]
    trgtDataReadCount = 2 * targetLen * 2
    target = target.reshape(frame_count, trgtDataReadCount)

    fig, ax = plt.subplots(2, 1, figsize=(30, 20))

    for i in range(frame_count):
        vel = convrtAveVelocity(
            target[i, 0 : (4 * targetLen)],
            considertargetLen,
            TH,
            N_FFT,
            PRT,
            lambda_,
            targetLen,
        )

        buffer_average_vel = shift_vector_left(buffer_average_vel, vel)

        if i >= time_avg_len - 1:
            # Idea: we can use EWMA betta=0.95

            # May be changed in the future

            local_index = -1 - (time_avg_len // 2)
            buffer_mov_average_vel = shift_vector_left_skip(
                buffer_mov_average_vel,
                1.0 * np.mean(buffer_average_vel[-time_avg_len:-1], axis=0),
                skip=local_index,
            )

            buffer_average_acc = shift_vector_left_skip(
                buffer_average_acc,
                (
                    buffer_mov_average_vel[local_index - 1]
                    - buffer_mov_average_vel[local_index - 2]
                )
                / FrameTime,
                skip=local_index,
            )

        if i > 2 * time_avg_len - 1:

            local_index = -1 - time_avg_len
            local_indices_acc = np.arange(1, time_avg_len + 1) + (
                -1 - 3 * time_avg_len // 2
            )

            buffer_mov_average_acc = shift_vector_left_skip(
                buffer_mov_average_acc,
                1.0 * np.mean(buffer_average_acc[local_indices_acc - 1], axis=0),
                skip=local_index + 1,
            )

            if buffer_kick_start == 1:
                if np.abs(buffer_mov_average_vel[local_index - 1, 1]) > detection_speed:
                    buffer_kick_start = local_index
            else:
                buffer_kick_start -= 1  # shift left the start index

                if buffer_kick_stop == 0:
                    if (
                        (
                            np.abs(
                                buffer_mov_average_vel[
                                    -np.arange(5) + local_index - 1, 1
                                ]
                            )
                            < detection_speed
                        ).sum()
                        > 3
                    ) and (local_index - buffer_kick_start > 3):
                        buffer_kick_stop = local_index - 3

                        yagiKick = validateKick(
                            i,
                            ax,
                            buffer_kick_start,
                            buffer_kick_stop,
                            buffer_mov_average_vel[:, 1],
                            buffer_mov_average_acc[:, 1],
                            time_avg_len,
                            FrameTime,
                        )

                        patchKick = validateKick(
                            i,
                            ax,
                            buffer_kick_start,
                            buffer_kick_stop,
                            buffer_mov_average_vel[:, 0],
                            buffer_mov_average_acc[:, 0],
                            time_avg_len,
                            FrameTime,
                        )

                        print(
                            '{{"frame":   {},    yagi_kick: {}, patch_kick: {}, "kick_start": {}}}'.format(
                                i, int(yagiKick), int(patchKick), i + buffer_kick_start
                            )
                        )

                        if yagiKick and patchKick:
                            start_index.append(i + buffer_kick_start)
                            stop_index.append(i)

                        buffer_kick_start = 1
                        buffer_kick_stop = 0

    ax[0].plot(
        np.arange(buffer_mov_average_vel.shape[0]) * FrameTime,
        buffer_mov_average_vel[:, 0],
        color="green",
    )
    ax[0].plot(
        np.arange(buffer_mov_average_acc.shape[0]) * FrameTime,
        buffer_mov_average_acc[:, 0],
        color="red",
    )

    ax[1].plot(
        np.arange(buffer_mov_average_vel.shape[0]) * FrameTime,
        buffer_mov_average_vel[:, 1],
        color="green",
    )
    ax[1].plot(
        np.arange(buffer_mov_average_acc.shape[0]) * FrameTime,
        buffer_mov_average_acc[:, 1],
        color="red",
    )

    ax[0].set_title("PC0 (Patch) antenna 1")
    ax[1].set_title("PC1 (Yagi) antenna 2")

    ax[0].set_xlabel("$Frame (s)$")
    ax[1].set_xlabel("$Frame (s)$")

    ax[0].set_ylabel("$Velocity,m/s$")
    ax[1].set_ylabel("$Velocity,m/s$")

    ax2_0 = ax[0].twinx()
    ax2_1 = ax[1].twinx()
    ax2_0.set_ylabel("$Acceleration,m/s^2$")
    ax2_1.set_ylabel("$Acceleration,m/s^2$")

    plt.tight_layout()
    plt.show()

    return start_index, stop_index


def shift_vector_left(vec, value):
    vec[:-1] = vec[1:]
    vec[-1] = value
    return vec


def shift_vector_left_skip(vec, value, skip):
    vec[: skip - 1] = vec[1:skip]
    vec[skip - 1] = value
    return vec


def convrtAveVelocity(
    TargetData, numofTarget, TH, N_FFT, PRT, lambda_, numofTargetfromATR22
):
    averageVelocity = np.zeros((2,))

    for i in range(2):
        Target_MaxValue = np.zeros((numofTarget,))  # the shape may be not right
        Target_MaxLocations = np.zeros((numofTarget,))  # the shape may be not right
        rawTarget = TargetData[
            np.arange(1, 2 * numofTarget + 1) + (i * 2 * numofTargetfromATR22) - 1
        ]  # PC0 and PC1
        # rawTarget = np.concatenate((np.array([1]), rawTarget))
        counterTHexceedingTarget = 0

        for j in range(numofTarget):
            Target_MaxValue[j] = (((0x00FF & int(rawTarget[j * 2 + 1])) << 4)) + (
                (0xFF00 & int(rawTarget[j * 2])) >> 8
            )
            if Target_MaxValue[j] > TH:
                counterTHexceedingTarget += 1
                Target_MaxLocations[j] = 0x00FF & int(rawTarget[j * 2])
                if Target_MaxLocations[j] > N_FFT / 2:
                    Target_MaxLocations[j] -= N_FFT

        if counterTHexceedingTarget:
            averageVelocity[i] = (
                np.mean(Target_MaxLocations[: counterTHexceedingTarget + 1])
                * lambda_
                / 2
                / PRT
                / (N_FFT - 1)
            )  # changes this
        else:
            averageVelocity[i] = 0

    return averageVelocity


def validateKick(
    i,
    ax,
    buffer_kick_start,
    buffer_kick_stop,
    buffer_mov_average_vel,
    buffer_mov_average_acc,
    time_avg_len,
    FrameTime,
):

    kick_start_acc = buffer_kick_start - time_avg_len // 2
    kick_stop_acc = buffer_kick_stop + time_avg_len // 2

    if (
        buffer_kick_stop - buffer_kick_start
    ) * FrameTime < 0.5:  # minimum kick duration 500 ms # changed this
        return False

    if (
        buffer_kick_stop - buffer_kick_start
    ) * FrameTime > 2:  # maximum kick duration 2 s  # changed this
        return False

    if (
        buffer_mov_average_vel[
            buffer_kick_start
            - 1 : (buffer_kick_stop - buffer_kick_start) // 3
            + buffer_kick_start
        ].min()
        < 0
    ):
        return False  # first third of the kick need to approach radar

    if (
        buffer_mov_average_vel[
            buffer_kick_stop
            - (buffer_kick_stop - buffer_kick_start) // 3
            - 1 : buffer_kick_stop
        ].max()
        > 0
    ):
        return False  # last third of the kick need to depart from radar

    if (
        buffer_mov_average_acc[
            (kick_stop_acc - (kick_stop_acc - kick_start_acc + 1) // 6)
            - 1 : kick_stop_acc
        ].min()
        < 0
    ):
        return False  # last sixth of the kick need to accelerate towards radar (brake)

    left = round(kick_start_acc + (kick_stop_acc - kick_start_acc) * 3.9 / 8) - 1
    right = round(kick_stop_acc - (kick_stop_acc - kick_start_acc + 1) * 3.9 / 8)

    if buffer_mov_average_acc[left:right].max() > 0:
        return False  # mid third of the kick need to accelerate away from radar

    if np.sum(buffer_mov_average_vel[buffer_kick_start - 1 : buffer_kick_stop] != 0) < (
        0.80 * (buffer_kick_stop - buffer_kick_start - 1)
    ):
        return False

    return True


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("--target", type=str, help="a path to the input target file")
    args = parser.parse_args()
    recording_path = args.target

    kick_detection(recording_path)
