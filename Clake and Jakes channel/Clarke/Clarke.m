% plot Clark channel model
clear
clc
fm=100;     % ���Doppler
ts_mu=50;   % ����ʱ��
scale=1e-6;
ts=ts_mu*scale; %����ʱ��
fs=1/ts;    % sample frequency
Nd=1e6;     % ������

%generat channel information
[h,Nfft,Nifft,Doppler_coeff]=Clarke_model(fm,fs,Nd);
subplot(211)
plot([1:Nd]*ts,10*log10(abs(h)));
str=sprintf('channel model by Clarke with fm=%d[Hz],Ts=%d[mus]',fm,ts_mu);
title(str);
% �ŵ�����
subplot(223)
hist(abs(h),50);
% �ŵ���λ
subplot(224)
hist(angle(h),50);
            