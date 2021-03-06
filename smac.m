%% smac.m
% This program solves 2D cavity flow by smac method
clear; close all; clc;

%% Definition
Re = 10;          % Reynolds number = nu*ut/L
N = 21;             % Number of grids [-]
nu = 1.5e-5;        % kinetic viscosity [m^2/2]
ut = 1.0;           % Boundary condition
L = nu*Re/ut;       % Cavity Length
dl = L/N;           % grid size dx, dy
r = 0.1;            % diffuison number 
cou = 0.25;         % courant number　> 1.0 for explicit scheme
dtd  = r/nu*(dl^2); % dt
dta  = cou*dl/ut;
dt   = min(dtd,dta);
t = 0.0;

%% Calculation Control
NO = 500;           % time step
NOF = 10;            % file num per time-step
crit = 1.0e-6;      % criteria for convergence [Pa]

%% Display info.
fprintf('Conditions\n');
fprintf('\tReynolds number :%e\n',Re);
fprintf('\tdl\t\t:%e\n',dl);
fprintf('\tdt\t\t:%e\n',dt);
fprintf('\tL\t\t:%e\n',L);

%% Grid
% for x-direction
x = zeros(N+2,1); dx = zeros(N+2,1);
x(1) = 0.0;dx(1) = 0.0; dx(N+2) = 0.0;
dx(2:N+1) = dl;

for i = 2:N+2
    x(i) = x(i-1) + 0.5*(dx(i)+dx(i-1));
end

% for y-direction
dy = dx; y = x;

%% Variables
% V = (u(y,x),v(y,x)), p(y,x) : pressure
u = zeros(N+2,N+2); v = zeros(N+2,N+2);
p = zeros(N+2,N+2);pn = zeros(N+2,N+2); 

% Boundary condition
u(N+2,2:N+1) = ut;
uo = u; vo = v; ui = u; vi = v; pp = p;

%% coefficient u[j,i]->[1:N,2:N], v[j,i]->[2:N, 1:N]
cuw = zeros(N+1,N+1);cue = zeros(N+1,N+1);
cus = zeros(N+1,N+1);cun = zeros(N+1,N+1);
cud = zeros(N+1,N+1);cuo = zeros(N+1,N+1);

cvw = zeros(N+1,N+1);cve = zeros(N+1,N+1);
cvs = zeros(N+1,N+1);cvn = zeros(N+1,N+1);
cvd = zeros(N+1,N+1);cvo = zeros(N+1,N+1);

%% diffusion
auw = zeros(N+1,1);aue = zeros(N+1,1);
aus = zeros(N+1,1);aun = zeros(N+1,1);
avw = zeros(N+1,1);ave = zeros(N+1,1);
avs = zeros(N+1,1);avn = zeros(N+1,1);

%% advection
fuw = zeros(N+1,N+1);fue = zeros(N+1,N+1);
fus = zeros(N+1,N+1);fun = zeros(N+1,N+1);
fvw = zeros(N+1,N+1);fve = zeros(N+1,N+1);
fvs = zeros(N+1,N+1);fvn = zeros(N+1,N+1);

%% poisson eq. p[j,i]->[1:N, 1:N]
cw = zeros(N+1,1);ce = zeros(N+1,1);
cs = zeros(N+1,1);cn = zeros(N+1,1);
cd = zeros(N+1,N+1); 

%% fixed coefficient au[j direc.], av[i direc.]
auw(:) = nu; aue(:) = nu;
aus(:) = nu; aun(:) = nu;
aus(2) = 2.0*nu;aun(N+1) = 2.0*nu;

avw(:) = nu; ave(:) = nu;
avs(:) = nu; avn(:) = nu;
avw(2) = 2.0*nu;ave(N+1) = 2.0*nu;

cuo(:,:) = dl^2/dt; cvo(:,:) = dl^2/dt;
cw(:) = 1.0; ce(:) = 1.0;
cs(:) = 1.0; cn(:) = 1.0;

for i = 2:N+1
    for j = 2:N+1
        cd(j,i) = (ce(i)+cw(i)+cn(j)+cs(j));
    end
end

%% Simulation (while flgt == 1)
cnf = 0;  % count
flgt = 1; % time step loop

f1 = figure;
ax = gca;
[X,Y] = meshgrid(x/L,y/L);[~,c] = contourf(X,Y,p,10);
crange = [-4, 4];
caxis(crange);
plot_title = sprintf('Re:%d %4dstep %7.4f[s]  Pressure and Velocity distribution',Re,0,t);
title(plot_title)
set(c,'LineStyle','none');colormap('parula');
xlim([0,1]); ax.XLabel.String = 'L/x[-]';
ylim([0,1]); ax.YLabel.String = 'L/y[-]';

bar = colorbar;
bar.Label.String = 'Pressure [Pa]';

hold on;

q = quiver(X,Y,ui,vi,4.0,'Color','white');

drawnow

filename = sprintf('Re%dplot%04d.png',Re,0);
saveas(f1,filename)
hold off;


for n = 0:NO
    fprintf('\tpmax:%e pmin:%e ppmax:%e\n',max(max(p)),min(min(p)),max(max(pp)));
    flgt = 0;
    % u, v calculation
    if n == 250
        ut = -ut;
        u(N+2,2:N+1) = ut;
        ui(N+2,2:N+1) =ut;
    end
       
    for i = 2:N+1
        for j = 2:N+1
            %
            fuw(j,i) = 0.5* (uo(j,i)  +uo(j,i-1))    * dl; fue(j,i) = 0.5* (uo(j,i)  +uo(j,i+1))    * dl;
            fus(j,i) = 0.5* (vo(j,i)  +vo(j,i-1))    * dl; fun(j,i) = 0.5* (vo(j+1,i)+vo(j+1,i-1))  * dl;  

            fvw(j,i) = 0.5* (uo(j,i)  +uo(j-1,i))    * dl; fve(j,i) = 0.5* (uo(j,i+1)+uo(j-1,i+1))  * dl; 
            fvs(j,i) = 0.5* (vo(j,i)  +vo(j-1,i))    * dl; fvn(j,i) = 0.5* (vo(j,i)  +vo(j+1,i))    * dl;  

            cuw(j,i) = auw(j) + 0.5*fuw(j,i); cue(j,i) = aue(j) - 0.5*fue(j,i);
            cus(j,i) = aus(j) + 0.5*fus(j,i); cun(j,i) = aun(j) - 0.5*fun(j,i);

            cvw(j,i) = avw(i) + 0.5*fvw(j,i); cve(j,i) = ave(i) - 0.5*fve(j,i);
            cvs(j,i) = avs(i) + 0.5*fvs(j,i); cvn(j,i) = avn(i) - 0.5*fvn(j,i);
        end
    end
    cud(:,:) = cuw(:,:) + cue(:,:) + cus(:,:) + cun(:,:)...
              -fuw(:,:) + fue(:,:) - fus(:,:) + fun(:,:);
    cvd(:,:) = cvw(:,:) + cve(:,:) + cvs(:,:) + cvn(:,:)...
              -fvw(:,:) + fve(:,:) - fvs(:,:) + fvn(:,:);
    for i = 2:N+1
        for j = 2:N+1
            u(j,i) = (...
                      cuw(j,i)*uo(j,i-1) + cue(j,i)*uo(j,i+1)...
                     +cus(j,i)*uo(j-1,i) + cun(j,i)*uo(j+1,i)...
                     + (cuo(j,i)-cud(j,i))*uo(j,i)...
                     + (p(j,i-1)-p(j,i))*dl...
                     )/cuo(j,i);
            v(j,i) = (...
                      cvw(j,i)*vo(j,i-1) + cve(j,i)*vo(j,i+1)...
                     +cvs(j,i)*vo(j-1,i) + cvn(j,i)*vo(j+1,i)...
                     + (cvo(j,i)-cvd(j,i))*vo(j,i)...
                     + (p(j-1,i)-p(j,i))*dl...
                     )/cvo(j,i);            
        end
    end
    % update BC
    u(:,2) = 0.0; v(2,:) = 0.0;
    
    % pressure iteration loop
    pn(:,:) = p(:,:); pp(:,:) = 0.0;
    
    flg = 1;          % Control flag
    l = 0;            % Countour
    
    while flg == 1
        l = l+1;
        flg = 0;
        % Boundary condition
        p(2:N+1,1) = pp(2:N+1,2); p(1,2:N+1) = pp(2,2:N+1);
        for i = 2:N+1
            for j = 2:N+1
                % Gauss-Seidel scheme
                p(j,i) = ( cw(i) * p(j,i-1)+ ce(i) * pp(j,i+1)...
                         + cs(j) * p(j-1,i) + cn(j) * pp(j+1,i)...
                         - (( u(j,i+1) - u(j,i) ) * dl +( v(j+1,i) - v(j,i) ) * dl )/dt)/cd(j,i);
%                Jacobi scheme
%                 p(j,i) = ( cw(i) * pp(j,i-1)+ ce(i) * pp(j,i+1)...
%                          + cs(j) * pp(j-1,i)+ cn(j) * pp(j+1,i)...
%                          - (( u(j,i+1) - u(j,i) ) * dl +( v(j+1,i) - v(j,i) ) * dl )/dt)/cd(j,i);
            end
        end
        
        p(2:N+1,N+2) = p(2:N+1,N+1); p(N+2,2:N+1) = p(N+1,2:N+1);
        
        % convergence check
        for i = 1:N+2
            for j = 1:N+2
                if abs(p(j,i) - pp(j,i)) > crit
                    flg = 1;
                end 
            end
        end
        
        if rem(l, 100) == 0
            fprintf('\t\titr = %d\n', l);
        end
        % update value
        pp(:,:) = p(:,:);
        
    end
    
    fprintf('time = %d\n', n);
        % velocity upadate
        for i = 2:N+1
            u(2:N,i) = u(2:N,i) - dt*(p(2:N,i)-p(2:N,i-1))/dl;
            v(i,2:N) = v(i,2:N) - dt*(p(i,2:N)-p(i-1,2:N))/dl;
        end
        p(:,:) = pn(:,:) + p(:,:);
        % update value
        uo = u; vo = v;
        
        % velocity vector for quiver
        for i = 2:N+1
            for j = 2:N+1
                ui(j,i) = 0.5*(u(j,i) + u(j,i+1));
                vi(j,i) = 0.5*(v(j,i) + v(j+1,i));
            end
        end
    
    t = t + dt;
    % Show result
    if rem(n,NOF) == 0
        [~,c] = contourf(X,Y,p,10);
        caxis(crange);
        bar = colorbar;
        plot_title = sprintf('Re:%d %4dstep %7.4f[s]  Pressure and Velocity distribution',Re,n,t);
        title(plot_title)
        
        set(c,'LineStyle','none');colormap('parula');
        xlim([0,1]); ax.XLabel.String = 'L/x[-]';
        ylim([0,1]); ax.YLabel.String = 'L/y[-]';
        
        bar.Label.String = 'Pressure [Pa]';
        
        hold on;
        
        q = quiver(X,Y,ui,vi,4.0,'Color','white');
        drawnow
        
        
        hold off;
        
        filename = sprintf('Re%dplot%04d.png',Re,n);
        saveas(f1,filename)
             
    end
   
end