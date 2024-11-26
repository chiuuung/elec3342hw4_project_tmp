'''
    Author: Jiajun Wu, CASR, HKU
    Generate multipule sine waves (txt) including a sentence for a VHDL test bench.
    Default spec:
	    - sample rate 96kHz
'''

import math
import argparse
import random
import numpy as np
import scipy

def cal_sample_num(adc_rate, symbol_rate, head_tail=False):
    if head_tail == True:
        # need to keep for the head 4 symbols and tail 4 symbols
        samples_num = int(adc_rate*5/symbol_rate)
    else:
        samples_num = int(adc_rate/symbol_rate)
    return samples_num


# args = docopt(__doc__)
parser = argparse.ArgumentParser(description='testbench_config')
parser.add_argument(
    '--adc_bw', '-b', help='ADC bit width (default 12-bit)', default=12)
parser.add_argument(
    '--adc_freq', '-f', help='ADC sampling frequency (rate), default 96000', default=96000)
parser.add_argument(
    '--sym_rate', '-r', help='Symbol rate of decoder (default 16)', default=16)
parser.add_argument(
    '--info_str', '-s', help='Information which needs to be decoded (default FLATWHITE!)', default="FLATWHITE!")
args = parser.parse_args()

dic_table = {'A': ['1', '2'], 'B': ['1', '3'], 'C': ['1', '4'], 'D': ['1', '5'], 'E': ['1', '6'],
             'F': ['2', '1'], 'G': ['2', '3'], 'H': ['2', '4'], 'I': ['2', '5'], 'J': ['2', '6'],
             'K': ['3', '1'], 'L': ['3', '2'], 'M': ['3', '4'], 'N': ['3', '5'], 'O': ['3', '6'],
             'P': ['4', '1'], 'Q': ['4', '2'], 'R': ['4', '3'], 'S': ['4', '5'], 'T': ['4', '6'],
             'U': ['5', '1'], 'V': ['5', '2'], 'W': ['5', '3'], 'X': ['5', '4'], 'Y': ['5', '6'],
             'Z': ['6', '1'], '!': ['6', '2'], '.': ['6', '3'], '?': ['6', '4'], ' ': ['6', '5'],}

# frequency (Hz)
freq_table = {
    "0": 2093.00,
    "1": 1760.00,
    "2": 1396.91,
    "3": 1174.66,
    "4": 987.77,
    "5": 783.99,
    "6": 659.25,
    "7": 523.25,
}
symbol_rate = args.sym_rate
adc_samp_rate = int(args.adc_freq)
print(adc_samp_rate)
wave_bits = args.adc_bw
code_str = args.info_str
wave_amp = 2 ** (wave_bits - 1)
signal_amp = int(wave_amp * 0.6)
noise_amp = int(wave_amp * 0.3)
noise_freq = 40000
random_amp = int(wave_amp * 0.1)
samples = []

print(f'Signal amplitude : {signal_amp} Noise amplitude: {noise_amp}')

print('-- Coding infomation into a symbol sequence')
print(code_str)
symbol_seq = ['0', '7', '0', '7']
for i in range(len(code_str)):
    symbol_seq = symbol_seq + dic_table.get(code_str[i])
symbol_seq = symbol_seq + ['7', '0', '7', '0']
print(symbol_seq)

print('-- Sine wave table generating')
sine_wave_list = []
total_samp_num = 0
for index in range(len(symbol_seq)):
    # head_tail = (index == 0) or (index == len(symbol_seq) - 1)
    wave_freq = freq_table.get(symbol_seq[index])
    samples_num = cal_sample_num(adc_samp_rate, symbol_rate, False)
    for samp in range(samples_num):
        # 40kHz noise
        noise_component = int(noise_amp/3 * math.sin(2 * math.pi * noise_freq * samp / adc_samp_rate) + noise_amp/3)
        # 20kHz noise
        noise_component += int(noise_amp/3 * math.sin(2 * math.pi * noise_freq/2 * samp / adc_samp_rate) + noise_amp/3)
        # 10kHz noise
        noise_component += int(noise_amp/3 * math.sin(2 * math.pi * noise_freq/3 * samp / adc_samp_rate) + noise_amp/3)
        # random noise
        noise_component += int(random_amp * random.random())
        signal_component = int(signal_amp * math.sin(2 * math.pi * wave_freq * samp / adc_samp_rate) + signal_amp)
        new_sample = noise_component + signal_component
        
        if new_sample > 4095:
            new_sample = 4095
        elif new_sample < 0:
            new_sample = 0
        bin_sample = (bin(((1 << 12) - 1) & new_sample)[2:]).zfill(12)
        samples.append(new_sample)
        sine_wave_list.append(bin_sample)
    total_samp_num += samples_num
print(total_samp_num)

print('-- Writing file')
with open("info_wave.txt", "w") as f:
    amp_index = 0
    for samp_amp in sine_wave_list:
        if amp_index < (total_samp_num - 1):
            f.write(samp_amp + '\n')
        else:
            f.write(samp_amp)
        amp_index += 1
x = np.array(samples, dtype=np.int16)
scipy.io.savemat('info_wave.mat', {'x': x})