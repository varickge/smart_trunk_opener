from ifxdaq.sensor.radar_ifx_mimose import RadarIfxMimose
from ifxdaq.record import DataRecorder
import argparse
import numpy as np
from pathlib import Path
import keyboard
import os
import shutil
import json

config_path = "RadarIfxMimose_00.json"


def gauss(n):
    """
    A window function that is applied on the raw data before the Fourier Transformation.
    Parameters:
        -`n`: The number of samples for constructing the window.
    """
    n += 1
    x = np.arange(-n // 2 + 1, n // 2)
    x = 2 * x / n
    y = np.exp(-1 / (1 - x**2))

    return y / y.sum()


def fft(inp, window):
    """
        A function that converts the raw data into target data. The function removes the mean from the data, applies a window function, \
        performs Fourier Transformation, takes the strongest 2 FFTs/targets, does the bit shifts and saves the data.
        Parameters:
            -`inp`: Raw data (radar.npy).
            -`window`: The window function. 
    """

    window = window(inp.shape[-1])
    window /= window.sum()
    
    I = inp[:, :, 0, :]
    Q = inp[:, :, 1, :]

    data = I + 1j * Q
    data -= data.mean(axis=-1, keepdims=True)
    data = data * window

    fft_data = np.fft.fft(data, axis=-1)

    amps = np.abs(fft_data)
    # Get top k values
    bins = np.argpartition(amps, -2, axis=-1)[..., -2:][..., ::-1]
    values = np.take_along_axis(amps, indices=bins, axis=-1)

    values = values.astype(np.uint16)
    bins = bins.astype(np.uint16)

    d_bins = bins + ((values & 0x00FF) << 8)
    d_amps = (values & 0x0FF0) >> 4

    # merge bits for allowing matlab to reconstruct them.
    save_data = np.stack(
        (
            d_bins[:, 0, 0],
            d_amps[:, 0, 0],
            d_bins[:, 0, 1],
            d_amps[:, 0, 1],
            d_bins[:, 1, 0],
            d_amps[:, 1, 0],
            d_bins[:, 1, 1],
            d_amps[:, 1, 1],
        ),
        axis=-1,
    )

    return values, bins, save_data


def to_json(ref_kick_path):
    '''
    A function for converting the given `ref_kick` to json format:
        Input:
            -`ref_kick_path`: Path to the ref_kick for which the kick.json file needs to be created
        Output:
            - List of dictionaries in the following format [ {"kick":0}, {"kick":1}, ..., {"kick":0} ]
    '''
    res_for_json = []
    timestamps = []
    for i in np.load(ref_kick_path).tolist() :
        res_for_json.append({"kick":i})
    
    return res_for_json


if __name__ == "__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument(
	    "--destination",
	    type=str,
	    help="Recording destination folder path",
	    required=True,
	)

	parser.add_argument(
	    "--configuration",
	    type=str,
	    help="Radar configuration path",
	    default=config_path
	)

	parser.add_argument(
	    "--frames",
	    type=int,
	    help="Number of frames to record",
	    required=True,
	    default=100
	)

	args = parser.parse_args()
	labels = np.zeros(0)

	with RadarIfxMimose(args.configuration) as device:
		with DataRecorder(args.destination, device.frame_format, device.meta_data, device.config_file) as rec:
			print("The recording has begun")
			try:
				for i, (frame) in enumerate(device):
					rec.write(frame)

					if keyboard.is_pressed("space"):
						print("Kick")
						labels = np.concatenate((labels, np.ones(1)))
					else:
						print("Non kick")
						labels = np.concatenate((labels, np.zeros(1)))

					if (i > args.frames) and (args.frames > 0):
						break
			except KeyboardInterrupt:
				print("The recording terminated")

    
    dst = Path(args.destination)
    os.mkdir(dst / "RadarIfxMimose_00")
    os.mkdir(dst / "Labels_00")
    
    shutil.copy(dst / "format.version", dst / "Labels_00")
    shutil.move(dst / "format.version", dst / "RadarIfxMimose_00")

    shutil.copy(dst / "meta.json", dst / "Labels_00")
    shutil.copy(dst / "meta.json", dst / "RadarIfxMimose_00")
    
    shutil.copy(dst / "radar_timestamp.csv", dst / "Labels_00/label_timestamp.csv")
    
    shutil.move(dst / "config.json", dst / "RadarIfxMimose_00")
    shutil.move(dst / "radar.npy", dst / "RadarIfxMimose_00")
    shutil.move(dst / "radar_timestamp.csv", dst / "RadarIfxMimose_00")

    
    raw_data = np.load(dst / "RadarIfxMimose_00/radar.npy")
    raw_data = raw_data[:, [1, 0]]
    np.save(dst / "RadarIfxMimose_00/radar.npy", raw_data)

    _, __, result = fft(raw_data, gauss)

    np.save(dst / "RadarIfxMimose_00/target", result)
    np.save(dst / "ref_kicks", labels.astype(np.uint16))
    
    if os.path.exists(dst / "ref_kicks.npy"):
        json_dict = to_json(dst / "ref_kicks.npy")
        with open(dst / "Labels_00/kick.json", "w") as f:    
            json.dump(json_dict, f)