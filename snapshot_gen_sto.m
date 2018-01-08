function [X] = snapshot_gen_sto(doas, snapshot, ncov, scov)
%SNAPSHOT_GEN_STO Generates snapshots for the stochastic model.
%Inputs:
%   doas - DOA vector. For 2D DOAs, each column represents a DOA pair.
%   ncov - Covariance matrix of the additive complex circular-symmetric
%          Gaussian noise. Can be a scalar, vector (for uncorrelated noise
%          with different powers), or a matrix.
%   scov - Covariance matrix of the source signals. Can be a scalar, vector
%          (for uncorrelated sources with different powers), or a matrix.
%Outputs:
%   X - Snapshots, where each columns is a single snapshot.
% if nargin <= 4
%     scov = 1;
% end
% if nargin <= 3
%     ncov = 1;
% end
% if nargin <= 2
%     snapshot = 1;
% end
c = 340; 
fl=2000; 
f0=3000; 
fh=4000; 
Fs=10000; 
bw=fh-fl;
Nfft=128;%ѡȡÿ�ε�ʱ�����ݳ��ȣ���dft���� 
N=Nfft*snapshot;%����ʱ���źŵ��ܵ��� 
Pn=ncov;  %��Ϊ�����϶�һ��������Ҫ����̶�����ȷ����ͬ�ź�Դ�Ĺ��� 
SNR = 10*log10(scov / ncov);
Ps=Pn*10 .^(SNR/10); 

Nsignal = length(doas);
%���������˹�����������ҵ�ͨ�˲��õ�����źţ������st�� 
ss=randn(N,Nsignal)*diag(sqrt(Ps)); 
st=[]; 
[bb,aa]=butter(10,[fl/(Fs/2),fh/(Fs/2)]); 
for r=1:Nsignal 
    temp=filter(bb,aa,ss(:,r)); 
    st=[st,temp]; 
end
%�����źŵĹ����� 
window=[];%�����׼ӵĴ� 
noverlap=[]; 
[Pxx,f]=psd(ss(:,1),Nfft,Fs,window,noverlap); 
% figure,plot(f,Pxx); 
[Pyy,f]=psd(st(:,1),Nfft,Fs,window,noverlap); 
% figure,plot(f,Pyy); 

J1=round(Nfft*fl/Fs+1);%��DFT�ĵ�J1��Ƶ��fl��Ӧ���� 
J2=round(Nfft*fh/Fs+1);  
J=J2-J1+1;%ѡ�õ�Ƶ�ʵ���Ŀ 
fll=(J1-1)*Fs/Nfft;%��J1�����Ӧ��ģ��Ƶ�� 
fhh=(J2-1)*Fs/Nfft;%��J2�����Ӧ��ģ��Ƶ�� 
subband=linspace(fll,fhh,J);%�����Ӵ�Ƶ�� 

wavelength = c/subband(1);
d = wavelength / 2;
design = design_array_1d('coprime', [3 4], d);
Nsensor = design.element_count;
Xfallsnapshot=zeros(Nsensor,J,snapshot);%���ڴ�Ŷ�ο���Ƶ�����ݣ�XfallsnapshotΪ3ά����

for number=1:snapshot%����ѭ����ʼ 
     
    Sf=fft(st((number-1)*Nfft+1:number*Nfft,:)); 
    %fft�ǰ��н��еģ�ÿһ�ж��任����Ӧ�����ź� 
    %Sf�Ĺ�ģΪ��Nfft��Nsignal�� 
     
 
    Sf=Sf(J1:J2,:);%��SfƵ�ʷ���Ϊ��Ĳ���ȥ����������ģΪ��J��Nsignal�� 
     
    %������������ 
    randn('state',sum(100*clock)); 
    nn=sqrt(Pn/2)*randn(Nsensor,J); 
    randn('state',sum(100*clock)); 
    nn=nn+j*sqrt(Pn/2)*randn(Nsensor,J); 
    Nf=fft(conj(nn'));%��Ϊfft���н��У���������Ҫ��nt�ĸ��н���fft�������ȶ�nt����ת�ã�fft����ת�û��� 
    Nf=conj(Nf');%Nf�Ĺ�ģΪ(Nsensor,J) 
     
    %���潨��ģ�͵õ�Ƶ��������ݱ��ʽ�������Afsf�� 
    Afsf=zeros(Nsensor,J); 

    for m=1:Nsignal 
        a=steerMultiFre(Nsensor, doas(m),c,subband);%aΪ��ģΪ��Nsensor��J��
        Sf1=repmat(conj(Sf(:,m))',Nsensor,1);%��ÿһ���źű��(Nsensor,J)�Ĺ�ģ 
        b = a.';
        as1=b.*Sf1; 
        Afsf=Afsf+as1; %�����ź��ۼӵõ�Ƶ���ź�����   
    end 
    Xf=Afsf+Nf;%���յ���Ƶ������ 
    Xfallsnapshot(:,:,number)=Xf; 
     
end%����ѭ����� 

X = Xfallsnapshot;

end

%��Ƶ�ʵ����������γɺ���

function s=steerMultiFre(Nsensor, doas,c,subband)

A = zeros(length(subband), Nsensor);
for ii = 1:length(subband)
    wavelength = c/subband(ii);
    d = wavelength / 2;
    design = design_array_1d('coprime', [3 4], d);
       A(ii, :) = exp(2j*pi/wavelength*(design.element_positions' * sin(doas)));
end
% 
s = A;
    
end
