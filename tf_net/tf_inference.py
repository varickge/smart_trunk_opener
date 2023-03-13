import argparse
import os
import warnings
from pathlib import Path

import numpy as np
import scipy
import tensorflow as tf
from tensorflow import keras

import matplotlib.pyplot as plt
warnings.filterwarnings("ignore")
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"


def cleaning(inp, correcting_size=8):
    """
    A function for cleaning noise from ref_kicks files
    if a single kick contains zeros function converts they to ones.
        -`inp`: folder_path -- Data folder path,
                correcting_size -- window size for dilation and erosion
        -`return`: numpy array without noise.
    """
    structure = np.ones(correcting_size)
    label_kick_filled_dilated = scipy.ndimage.binary_dilation(inp, structure=structure)
    # after taking out redundant zeros, at the end and at the beginning of the kick there are extra ones
    # so it is necessary to kick them out
    label_kick_filled_erosed = scipy.ndimage.binary_erosion(
        label_kick_filled_dilated, structure=structure
    ).astype(int)

    return label_kick_filled_erosed


def decode(inp):
    """
    A function, that given the target input data, decodes the amplitudes and bins.
    Decoding via FFT, getting the n_max amplitudes (here 2)
        -`inp`: Nx8 ,  Target data (target.npy).
        -`return`: Nx2x2
    """

    N = inp.shape[0]

    tmp = inp.reshape(N, -1)
    target_bins = tmp[:, ::2]
    target_amps = tmp[:, 1::2]
    # FFT part, bitshifts
    decoded_bins = target_bins & 0x00FF
    decoded_amps = ((target_bins & 0xFF00) >> 8) + ((target_amps & 0x00FF) << 4)

    amps = decoded_amps.reshape(N, 2, 2)
    bins = decoded_bins.reshape(N, 2, 2)

    return amps, bins


def load_target_data(folder_path):
    """
    A function for loading and decoding the targer data from the given path.
        -`inp`: Folder path.
        -`return`: time-data with shape (N,8)
    """
    target_data = np.load(folder_path)
    
    amps, bins = decode(target_data)
    len_points = amps.shape[0]
    amps, bins = amps.reshape(len_points, 4), bins.reshape(len_points, 4)
    data = np.hstack((amps, bins)).astype(np.float32)

    data[:, [4, 5, 6, 7]] = data[:, [4, 5, 6, 7]] / 31  # deviding bins to it's max
    data = data[:, [0, 4, 1, 5, 2, 6, 3, 7]]  # reordering data to amplitudes and bins
    
    return data


def model_seq(weights_path, kernel_size, split_len):

    """
    A function for creating tensorflow sequential model
        -`weights_path`: Model weights path
        -`kernel_size`: The kernel size of conv function
        -`split_len`: model input batch size
        -`return`: model with pretrained weights, split_len
    """

    model = keras.Sequential(
        [
            tf.keras.Input(shape=(split_len - kernel_size + 1, 8), batch_size=None),
            tf.keras.layers.GRU(units=64, return_sequences=False),
            tf.keras.layers.Dense(2),
            tf.keras.layers.Softmax(),
        ]
    )
    model.load_weights(weights_path)

    return model


def inference(path, split_len=50, confidence=0.7):
    """
    Function for inference on given file.
        -`path`: imput file path
    """
    eps = 1e-8
    stride = 1
    split_len = 50
    kernel = np.ones(3) / 3

    # load the model
    script_path = Path(os.path.realpath(__file__)).parent
    weights_path = script_path / "models" / "our_train_our_fit_full.h5"    
    model = model_seq(weights_path, len(kernel), split_len)
    
    # data loading and splitting
    target_data = load_target_data(path)
    mask = np.arange(split_len) + np.arange(target_data.shape[0] - split_len, step=stride)[..., None]
    data = target_data[mask]
    
    # conv normalization
    mask_conv = np.arange(split_len - kernel.shape[0] + 1)[:, None] + np.arange(kernel.shape[0])
    data_avg = (data[..., [0, 2, 4, 6]][:, mask_conv] * kernel[..., None]).sum(axis=-2)
    data_avg = data_avg / np.maximum(np.max(data_avg, axis=1), eps)[:, None]
    joint_data = np.concatenate([data_avg, data[:, kernel.shape[0]-1:, [1, 3, 5, 7]]], axis=-1)
    joint_data = joint_data[..., [0, 4, 1, 5, 2, 6, 3, 7]]  # reordering the data           
    
    # model prediction
    pred = model.predict(joint_data, verbose=0)
    pred = np.where(pred > confidence)[1]
    pred = np.concatenate((np.zeros(split_len), pred))  # to cancel th AI delay
    
    # getting kick's start and stop indices
    label, group_index = scipy.ndimage.label(pred)
    labels_i, labels_j, labels_i_count = np.unique(label, return_index=True, return_counts=True)
    kick_start, kick_stop = labels_j[1:], labels_j[1:] + labels_i_count[1:] - 1

    for i in range(len(kick_start)):
        start = int(kick_stop[i]-split_len)
        stop = int(kick_start[i])
        if start >= stop:
            continue
        print('{{"frame":   {}, "kick_start": {}}}'.format(stop, start))     

        
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "target_path",
        type=str,
        help="folder name of a file containing recordings",
    )
  
    args = parser.parse_args()
    path = args.target_path

    inference(path)
