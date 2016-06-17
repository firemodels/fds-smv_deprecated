% Hamins
% 12-9-15
% Modificaiton of McDermott's mccaffrey_plume_copy2_45.m to plot McCaffrey's NBSIR 79-1910
% And plot effect of Burner iniital temperature considering the files
% "McCaffrey_57_kW_11", "McCaffrey_57_kW_11_100" and "McCaffrey_57_kW_11_Xr" where the burner
% surface temp was set to 100 C, 150 C, and adiabatic, respectively
% compare three files set as adiabatic, 100 and 150 for the burner surface

% McDermott
% 7-7-14
% mccaffrey_plumes.m

close all
clear all

plot_style
Font_Interpreter='latex';

Q = [14.4 21.7 33.0 44.9 57.5]; % in kW [14.4 21.7 33.0 44.9 57.5]
g = 9.8;          % m/s^2
rho = 1.18;       % kg/m^3
cp = 1;           % kJ/kg-K
T0 = 273.15 + 20; % K

% Z* = Z/D*
% length DS = D Star = D*
DS = (Q/(rho*cp*T0*sqrt(g))).^(2/5) % m      "."  power funciton
% units 

% use McCaffrey's figs as basis; plot everything as z/Q^(2/5)

% datadir = '../../Validation/McCaffrey_Plume/FDS_Output_Files/';
% need additional forwawrd slash "/" !!!  see next line
datadir = '../../../Validation/McCaffrey_Plume/FDS_Input_Files/';
% plotdir = '../../../Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/McCaffrey_Plume/';
plotdir = '\\BLAZE\ahamins\GitHub\fds-smv_ahamins\Manuals\FDS_Validation_Guide\SCRIPT_FIGURES\McCaffrey_Plume';

chid = {'McCaffrey_57_kW_11_line','McCaffrey_57_kW_11_T100_line','McCaffrey_57_kW_11_T150_line'};
% three files set as adiabatic, 100 and 150 for the burner surface
% these files have 2 header lines and three columns: location, T, V
mark = {'ko','rd','gd'};
n_chid = length(chid); % number of vector entries

% McCaffrey plume correlations - fits to the data from his figures
% Velocity on p. 8 
zq = logspace(-2,0,100); % logspace generates 100 points between 0.01 and 1
% zq is --> z/Q^(2/5)

for i=1:length(zq)
    if zq(i)<0.08
        vq(i) = 6.84*zq(i)^0.5;
        Tq(i) = 800*zq(i)^0;
    elseif zq(i)>=0.08 & zq(i)<=0.2
        vq(i) = 1.93*zq(i)^0;
        Tq(i) = 63*zq(i)^(-1);
    elseif zq(i)>0.2
        vq(i) = 1.12*zq(i)^(-1/3);
        Tq(i) = 21.6*zq(i)^(-5/3);
    end
end
% McCaffrey correlations above in terms of z/Q^2/5

% Baum and McCaffrey plume correlations below (in terms of Z*, not z/Q^2/5)
% where Z* = z/D* = z/(Q/p Cp T Sqrt(g))^-(2/5)
% 2nd IAFSS, p. 134
zs = logspace(-2,1,100); % generates 100 points between 0.01 and 10
%change 1 to 0 in above --> go to 1 not 10
n = [1/2 0 -1/3];
A = [2.18 2.45 3.64];
B = [2.91 3.81 8.41];

for i=1:length(zs)
    if zs(i)<1.32             % Z*
        j=1;
    elseif zs(i)>=1.32 & zs(i)<=3.3
        j=2;
    elseif zs(i)>3.3
        j=3;
    end
    us(i) = A(j)*zs(i)^n(j);
    Ts(i) = B(j)*zs(i)^(2*n(j)-1);
end

hh(n_chid+1)=loglog(zs,us,'b--','linewidth',2); hold on
% hold on retains plots in the current axes so that new plots added to the axes do not delete existing plots. 
xmin = 0.2;
xmax = 20;
ymin = 1;
ymax = 5.0;
axis([xmin xmax ymin ymax])
% grid on
% xlabel('$z/Q^{2/5}$ (m $\cdot$ kW$^{-2/5}$ )','FontSize',Label_Font_Size,'Interpreter',Font_Interpreter)
% ylabel('$V/Q^{1/5}$ (m $\cdot$ s$^{-1}$ $\cdot$ kW$^{-1/5}$ )','FontSize',Label_Font_Size,'Interpreter',Font_Interpreter)
xlabel('$z^* = z/D^*$','FontSize',Label_Font_Size,'Interpreter',Font_Interpreter)
ylabel('$v^* = v/\sqrt{g D^*} $','FontSize',Label_Font_Size,'Interpreter',Font_Interpreter)

% FDS results velocity

% for i=1:n_chid
for i=1:n_chid
    % M = importdata([datadir,chid{i},'_line.csv'],',',2);
    % M = importdata([datadir,chid{i}],',',2);
    % file has 5 columns/2 headers: Height	tc	vel	tmp	wvel
    if i==1
        M = importdata('../../../Validation/McCaffrey_Plume/FDS_Input_Files/McCaffrey_57_kW_11_line.csv',',',2);
    end 
    if i==2
        M = importdata('../../../Validation/McCaffrey_Plume/FDS_Input_Files/McCaffrey_57_kW_11_T100_line.csv',',',2);
    end
    if i==3
        M = importdata('../../../Validation/McCaffrey_Plume/FDS_Input_Files/McCaffrey_57_kW_11_T150_line.csv',',',2);
       % M = importdata('../../../Validation/McCaffrey_Plume/Test2/McCaffrey_33_kW_11_line.csv',',',2);
    end
    if i==4
        M = importdata('../../../Validation/McCaffrey_Plume/Test2/McCaffrey_45_kW_11_line.csv',',',2);
    end
    if i==5
        M = importdata('../../../Validation/McCaffrey_Plume/Test2/McCaffrey_57_kW_11_line.csv',',',2);
    end
    z = M.data(:,find(strcmp('Height',M.colheaders)));
    dz = z(2)-z(1);
    z = z + dz/2; % use with "wvel" for staggered storage location
    v = M.data(:,find(strcmp('wvel',M.colheaders)));

    %zq_fds = z./Q(i)^(2/5);
    %vq_fds = v./Q(i)^(1/5);

    zs_fds = z./DS(i);
    vs_fds = v./sqrt(g*DS(i));

    hh(i)=loglog(zs_fds,vs_fds,mark{i}); % log-log plot of Y vs. X (X, Y, index)
end

leg_key = {'Tb = adiabatic','Tb = 100 C','Tb = 150 C','$A(z^*\,)^n$'};
%leg_key = {'57.5 kW','$A(z^*\,)^n$'};
lh = legend(hh,leg_key,'location','northwest');
set(lh,'Interpreter',Font_Interpreter)
legend boxoff

% add SVN if file is available

SVN_Filename = [datadir,'McCaffrey_57_kW_11_svn.txt'];
if exist(SVN_Filename,'file')
    SVN = importdata(SVN_Filename);
    x_lim = get(gca,'XLim');
    y_lim = get(gca,'YLim');
    X_SVN_Position = 10^( log10(x_lim(1))+ SVN_Scale_X*( log10(x_lim(2)) - log10(x_lim(1)) ) );
    Y_SVN_Position = 10^( log10(y_lim(1))+ SVN_Scale_Y*( log10(y_lim(2)) - log10(y_lim(1)) ) );
    text(X_SVN_Position,Y_SVN_Position,['SVN ',num2str(SVN)], ...
        'FontSize',10,'FontName',Font_Name,'Interpreter',Font_Interpreter)
end

% print to pdf

set(gcf,'Visible',Figure_Visibility);
set(gcf,'PaperUnits',Paper_Units);
set(gcf,'PaperSize',[Paper_Width Paper_Height]);
set(gcf,'PaperPosition',[0 0 Paper_Width Paper_Height]);
print(gcf,'-dpdf',[plotdir,'McCaffrey_Velocity_Correlation'])


% FDS results temperature rise

figure

hh(n_chid+1)=loglog(zs,Ts,'r--','linewidth',2); hold on

xmin = 0.1;
xmax = 20;
ymin = 0.1;
ymax = 5;
axis([xmin xmax ymin ymax])
%grid on
%xlabel('$z/Q^{2/5}$ (m $\cdot$ kW$^{-2/5}$ )','FontSize',Label_Font_Size,'Interpreter',Font_Interpreter)
%ylabel('$\Delta T$ ($^\circ$C)','FontSize',Label_Font_Size,'Interpreter',Font_Interpreter)
xlabel('$z^* = z/D^*$','FontSize',Label_Font_Size,'Interpreter',Font_Interpreter)
ylabel('$\Theta^* = (T-T_0)/T_0$','FontSize',Label_Font_Size,'Interpreter',Font_Interpreter)

for i=1:n_chid
    % M = importdata([datadir,chid{i},'_line.csv'],',',2);
    % file has 5 columns/2 headers: Height	tc	vel	tmp	wvel
    % use brute force to read files
    if i==1
        M = importdata('../../../Validation/McCaffrey_Plume/FDS_Input_Files/McCaffrey_57_kW_11_line.csv',',',2);
    end 
    if i==2
        M = importdata('../../../Validation/McCaffrey_Plume/FDS_Input_Files/McCaffrey_57_kW_11_T100_line.csv',',',2);
    end
    if i==3
        M = importdata('../../../Validation/McCaffrey_Plume/FDS_Input_Files/McCaffrey_57_kW_11_T150_line.csv',',',2);
        % M = importdata('../../../Validation/McCaffrey_Plume/Test2/McCaffrey_33_kW_11_line.csv',',',2);
    end
    if i==4
        M = importdata('../../../Validation/McCaffrey_Plume/Test2/McCaffrey_45_kW_11_line.csv',',',2);
    end
    if i==5
        M = importdata('../../../Validation/McCaffrey_Plume/Test2/McCaffrey_57_kW_11_line.csv',',',2);
    end    
    z = M.data(:,find(strcmp('Height',M.colheaders)));
    T = M.data(:,find(strcmp('tmp',M.colheaders))) + 273.15;
    %zq_fds = z./Q(i)^(2/5);
    %hh(i)=loglog(zq_fds,T,mark{i});
    hh(i)=loglog(z./DS(i),(T-T0)/T0,mark{i});
end

leg_key = {'Tb = adiabatic', 'Tb = 100 C','Tb = 150 C','$B(z^*\,)^{2n-1}$'};
%leg_key = {'57.5 kW','$B(z^*\,)^{2n-1}$'};
lh = legend(hh,leg_key,'location','southwest');
set(lh,'Interpreter',Font_Interpreter)
legend boxoff

% add SVN if file is available

SVN_Filename = [datadir,'McCaffrey_57_kW_45_svn.txt'];
if exist(SVN_Filename,'file')
    SVN = importdata(SVN_Filename);
    x_lim = get(gca,'XLim');
    y_lim = get(gca,'YLim');
    X_SVN_Position = 10^( log10(x_lim(1))+ SVN_Scale_X*( log10(x_lim(2)) - log10(x_lim(1)) ) );
    Y_SVN_Position = 10^( log10(y_lim(1))+ SVN_Scale_Y*( log10(y_lim(2)) - log10(y_lim(1)) ) );
    text(X_SVN_Position,Y_SVN_Position,['SVN ',num2str(SVN)], ...
        'FontSize',10,'FontName',Font_Name,'Interpreter',Font_Interpreter)
end

% print to pdf

set(gcf,'Visible',Figure_Visibility);
set(gcf,'PaperUnits',Paper_Units);
set(gcf,'PaperSize',[Paper_Width Paper_Height]);
set(gcf,'PaperPosition',[0 0 Paper_Width Paper_Height]);
print(gcf,'-dpdf',[plotdir,'McCaffrey_Temperature_Correlation'])


% Velocity profile in the plume

figure


SVN_Filename = [datadir,'McCaffrey_57_kW_11_svn.txt'];
if exist(SVN_Filename,'file')
    SVN = importdata(SVN_Filename);
    x_lim = get(gca,'XLim');
    y_lim = get(gca,'YLim');
    X_SVN_Position = x_lim(1)+SVN_Scale_X*(x_lim(2)-x_lim(1));
    Y_SVN_Position = y_lim(1)+SVN_Scale_Y*(y_lim(2)-y_lim(1));
    text(X_SVN_Position,Y_SVN_Position,['SVN ',num2str(SVN)], ...
        'FontSize',10,'FontName',Font_Name,'Interpreter',Font_Interpreter)
end

% print to pdf

set(gcf,'Visible',Figure_Visibility);
set(gcf,'PaperUnits',Paper_Units);
set(gcf,'PaperSize',[Paper_Width Paper_Height]);
set(gcf,'PaperPosition',[0 0 Paper_Width Paper_Height]);
print(gcf,'-dpdf',[plotdir,'McCaffrey_Velocity_Profile_Flame'])

