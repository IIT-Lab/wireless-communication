%***************************************************************
% scheme1_v1.m
% @wp  2018-3-7
% 仿真方案一：
% 设备与射频源之间的密钥建立
% 射频信号为两个不同频率的正弦信号的叠加
% 循环测试正弦信号PT与tag模型之间的通信模型，其中包括信号初始功率，tag端的功率，发射回来再PT端的功率
% 
% 信号参数：
% 信号频率900MHz，采样点10，采样频率9000MHz,周期10000*10
% 高斯噪声为8dB，信号幅值为4，发射系数为1.0
% 循环1000次
%***************************************************************

% Table is a rayleigh fading channel model in indoor
% Excess tap delay[ns]    	Relative power[dB]
% 0  						0.0
% 50  						-3.0
% 110						-10.0
% 170						-18.0 
% 290						-26.0
% 310						-32.0

clc;
clear;
close all;

f1 = 900e6;				% 信号频率900MHz,信号周期为10/9 ns
f2 = 950e6;				% 信号频率900MHz,信号周期为10/9 ns
N  = 10;				% 信号周期内的采样点数
Fs = N*f1;				% sampling frequency, 采样频率
T = 1/Fs;  				% sampling period, 采样周期
L = 100*N; 			% length of signal

t = (0:L-1)*T;			% 采样时间s，fs的值越大，出来的波形失真越小
A = 4/2;				% 信号幅值

%% 设置高斯噪声
SNR_tag = 8;

%% 构造初始信号
source = A*sin(2*pi*f1*t)+A*sin(2*pi*f2*t);
figure;
plot(t(1:1000),source(1:1000));
title('source signal');

%% 计算初始信号的功率
[Pxx_hamming, F]= periodogram(source, hamming(length(source)),[],Fs,'centered', 'psd');
power_source = bandpower(Pxx_hamming, F, 'psd');
power_source_db = 10*log10(power_source/2);
%***************************************************************
% 
num = 1:200;
power_source_array(num) = power_source_db;
power_tag_array(num) = 0;
power_pt_array(num) = 0;

for index = num

	%% 构造rayleigh信道
	delay_vector = [0, 50, 110, 170, 290, 310]*1e-9; 	% Discrete delays of four-path channel (s)
	gain_vector  = [0 -3.0 -10.0 -18.0 -26.0 -32.0]; 	% Average path gains (dB)			
	max_Doppler_shift = 50;  					% Maximum Doppler shift of diffuse components (Hz)			
	rayleigh_chan = rayleighchan(T,max_Doppler_shift,delay_vector,gain_vector);

	%% 初始信号经过rayleigh信道，并保持该信道特性用于下次反射
	rayleigh_chan.ResetBeforeFiltering = 0;
	data_after_rayleigh = filter(rayleigh_chan,source); 

	%% 添加高斯噪声
	data_tag = awgn(data_after_rayleigh,SNR_tag,'measured');

	%% 计算在tag端接收信号的功率
	[Pxx_hamming_tag, F_tag] = periodogram(data_tag,hamming(length(data_tag)),[],Fs,'centered','psd');
	power_tag = bandpower(Pxx_hamming_tag,F_tag,'psd');
	power_tag_db = 10*log10(power_tag/2);

	power_tag_array(index) = power_tag_db;

	%%************************************************************
	%% 反射路径 
	%% 发射因子为0.5
	coeffi = 1.0;
	data_back = data_tag.*coeffi;

	%% 反射后，信号再次经过rayleigh信道
	rayleigh_chan.ResetBeforeFiltering = 0;
	back_after_rayleigh = filter(rayleigh_chan,data_back); 


	%% 添加高斯噪声
	data_pt = awgn(back_after_rayleigh,SNR_tag,'measured');

	%% 计算在tag端接收信号的功率
	[Pxx_hamming_pt, F_pt] = periodogram(data_pt,hamming(length(data_pt)),[],Fs,'centered','psd');
	power_pt = bandpower(Pxx_hamming_pt,F_pt,'psd');
	power_pt_db = 10*log10(power_pt/2);

	power_pt_array(index) = power_pt_db;

end

figure;
plot(num(1:200),power_pt_array(1:200),'r-');
hold on;
plot(num(1:200),power_tag_array(1:200),'b-');
legend('RSS in PT','RSS in tag');

result1 = power_source_array+power_pt_array;
result2 = power_tag_array*2;

figure;
plot(num(1:200),result1(1:200),'*-');
hold on;
plot(num(1:200),result2(1:200),'+-');


r = corr2(power_pt_array,power_tag_array)

r = corr2(result1,result2)