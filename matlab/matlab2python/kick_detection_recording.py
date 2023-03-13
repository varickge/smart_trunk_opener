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
    selectedWindow = 6
    c = 3e8
    fc = 24.125e9
    lambda_ = c / fc

    TH = 100
    targetLen = 2
    FrameTime = 40e-3
    Fsamp = 1 / PRT
    TimeAxis = []
    time_avg_len = 12

    AveVelocities = np.zeros((len(target), 2))
    MovAveVelocities = np.zeros((len(target), 2))
    acceleration = np.zeros((len(target), 2))
    MovAveAcc = np.zeros((len(target), 2))

    # Kick detection variables
    kick_stop = np.array([0])
    kick_stopgraph = 0
    kick_stopWarnGraph = 0
    kick_start = np.array([1])
    kick_detectedVec = []
    kick_detectedVecPatch = []
    kick_detected = 0
    detection_speed = 1 / 40  # m/s

    frame_count = target.shape[0]
    target = target.reshape(frame_count, 8)
    trgtDataReadCount = 2 * targetLen * 2
    t = np.zeros((frame_count,))

    for i in range(frame_count):
        count = i + 1
        t[count - 1] = (count - 1) * FrameTime
        considertargetLen = 2
        AveVelocities[count - 1, 0:2] = convrtAveVelocity(
            target[count - 1, 0 : (4 * targetLen)].astype(np.float64),
            considertargetLen,
            TH,
            N_FFT,
            PRT,
            lambda_,
            targetLen,
        )

        if count >= time_avg_len:
            localIndex = count - round(0.5 * (time_avg_len))
            MovAveVelocities[localIndex - 1, 0] = 1.5 * np.mean(
                AveVelocities[count - time_avg_len : count, 0]
            )
            MovAveVelocities[localIndex - 1, 1] = 1.5 * np.mean(
                AveVelocities[count - time_avg_len : count, 1]
            )
            acceleration[localIndex - 1, 0] = (
                MovAveVelocities[localIndex - 1, 0]
                - MovAveVelocities[localIndex - 2, 0]
            ) / FrameTime
            acceleration[localIndex - 1, 1] = (
                MovAveVelocities[localIndex - 1, 1]
                - MovAveVelocities[localIndex - 2, 1]
            ) / FrameTime

        if count > (time_avg_len * 2):
            localIndices_acc = np.arange(1, time_avg_len + 1) + (
                count - round(1.5 * (time_avg_len))
            )  # changed this
            localIndex = count - 1 * time_avg_len
            MovAveAcc[localIndex - 1, 0] = 1.5 * np.mean(
                acceleration[localIndices_acc - 1, 0]
            )
            MovAveAcc[localIndex - 1, 1] = 1.5 * np.mean(
                acceleration[localIndices_acc - 1, 1]
            )

            if kick_start[-1] == 1:
                if abs(MovAveVelocities[localIndex - 1, 1]) > detection_speed:
                    kick_start[-1] = localIndex
            else:
                if kick_stop[-1] == 0:
                    if (
                        sum(
                            (
                                abs(
                                    MovAveVelocities[
                                        -1 * np.arange(5) + localIndex - 1, 1
                                    ]
                                )
                                < detection_speed
                            )
                        )
                        > 3
                    ) & (localIndex - kick_start[-1] > 3):
                        kick_stop[-1] = localIndex - 3
                        kick_detected_patch = 0
                        kick_detected = validateKick(
                            kick_start[-1],
                            kick_stop[-1],
                            t,
                            MovAveVelocities[:, 1],
                            MovAveAcc[:, 1],
                            time_avg_len,
                        )

                        if kick_detected:
                            kick_detected_patch = validateKick(
                                kick_start[-1],
                                kick_stop[-1],
                                t,
                                MovAveVelocities[:, 0],
                                MovAveAcc[:, 0],
                                time_avg_len,
                            )
                            yagiKick = True  # the client  added for gui

                            if kick_detected_patch:
                                patchKick = True  # the client  added for gui
                                kick_stopgraph = [kick_stopgraph, kick_stop]
                            else:
                                patchKick = False  # the client  added for gui
                                kick_stopWarnGraph = [kick_stopWarnGraph, kick_stop]
                        else:
                            yagiKick = False  # the client  added for gui
                            patchKick = False

                        print(
                            '{{"frame":   {},    yagi_kick: {}, patch_kick: {}, "kick_start": {}}}'.format(
                                i, int(yagiKick), int(patchKick), kick_start[-1] - 1
                            )
                        )

                        yagiKick = False
                        patchKick = False

                        kick_detectedVec = [kick_detectedVec, kick_detected]
                        kick_detectedVecPatch = [
                            kick_detectedVecPatch,
                            kick_detected_patch,
                        ]
                        kick_start = np.append(kick_start, 1)
                        kick_stop = np.append(kick_stop, 0)

    fig, ax = plt.subplots(2, 1, figsize=(8, 5))

    ax[0].plot(np.arange(count) * FrameTime, MovAveVelocities[:, 0], color="green")
    ax[0].plot(np.arange(count) * FrameTime, MovAveAcc[:, 0], color="red")

    ax[1].plot(np.arange(count) * FrameTime, MovAveVelocities[:, 1], color="green")
    ax[1].plot(np.arange(count) * FrameTime, MovAveAcc[:, 1], color="red")

    ax[0].set_title("PC0(Patch) antenna 1")
    ax[1].set_title("PC1(Yagi) antenna 2")

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


def convrtAveVelocity(
    TargetData, numofTarget, TH, N_FFT, PRT, lambda_, numofTargetfromATR22
):
    # for one frame, TargetData -> (8,)
    averageVelocity = np.zeros((2,))  # the shape may be not  right

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
                1
                * np.mean(Target_MaxLocations[: counterTHexceedingTarget + 1])
                * lambda_
                / 2
                / PRT
                / (N_FFT - 1)
            )  # changes this
        else:
            averageVelocity[i] = 0

    return averageVelocity


def validateKick(kick_start, kick_stop, t, avg_speeds, avg_acceleration, time_avg_len):

    isKick_valid = 1
    kick_start_acc = kick_start - round(time_avg_len / 2)
    kick_stop_acc = kick_stop + round(time_avg_len / 2)

    if (
        t[kick_stop - 1] - t[kick_start - 1]
    ) < 0.5:  # minimum kick duration 500 ms # changed this
        isKick_valid = 0

    if (
        t[kick_stop - 1] - t[kick_start - 1]
    ) > 2:  # maximum kick duration 2 s  # changed this
        isKick_valid = 0

    if (
        min(
            avg_speeds[
                kick_start - 1 : round((kick_stop - kick_start) / 3 + kick_start)
            ]
        )
        < 0
    ):
        isKick_valid = 0  # first third of the kick need to approach radar

    if (
        max(avg_speeds[round(kick_stop - (kick_stop - kick_start) / 3) - 1 : kick_stop])
        > 0
    ):
        isKick_valid = 0  # last third of the kick need to depart from radar

    if (
        min(
            avg_acceleration[
                round(kick_stop_acc - (kick_stop_acc - kick_start_acc + 1) / 6)
                - 1 : kick_stop_acc
            ]
        )
        < 0
    ):
        isKick_valid = (
            0  # last sixth of the kick need to accelerate towards radar (brake)
        )

    if (
        max(
            avg_acceleration[
                round(kick_start_acc + (kick_stop_acc - kick_start_acc) * 3.9 / 8)
                - 1 : round(
                    kick_stop_acc - (kick_stop_acc - kick_start_acc + 1) * 3.9 / 8
                )
            ]
        )
        > 0
    ):
        isKick_valid = 0  # mid third of the kick need to accelerate away from radar

    # check for patch antenna
    if sum(abs(avg_speeds[kick_start - 1 : kick_stop] != 0)) < (
        0.80 * (kick_stop - kick_start - 1)
    ):
        isKick_valid = 0  # first third of the kick need to approach radar

    return isKick_valid


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("--target", type=str, help="a path to the input target file")
    args = parser.parse_args()
    recording_path = args.target

    kick_detection(recording_path)
