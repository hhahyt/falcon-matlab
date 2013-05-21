matlabrc;
%clear;
close all;clc
eps = 3e-3;


l = 0.05; %m
mesh = 0:0.001:l;

E = 205000*10^6; %Pa

q = 100; %N/m
bok = 0.01; %m - bok kwadratowej belki
I = bok^4/12; %m4
%I = 3.06/100000

m = 0.1; %masa el ruchomego kg

F = 0;


h = haptikdevice;

pos = read_position(h);
yold = pos(2) /1000;
ynew = pos(2) /1000;%poczatkowe polozenia, do liczenia pochodnych
told = 0;
count = 1;
figure

ret = [];
contact = 0;
trend = 0;
trend_in = 0;
last_trend_in = 0;
last_Q = 0;
force_scale = 4000; %tyle razy mniejsza sila generowana niz obliczona

tic
while toc < 15
    
    t = toc;
    pos = read_position(h);
    x = pos(1) /1000;
    y = pos(2) /1000;
    z = pos(3) /1000;

    if (x < l) && (x > 0)
        %F = m * ((y - yold)/(toc - told) - yold)/(toc - told)

       dx = 0.0:.001:x; 
       ynew = y;
       
        dy = y - yold;
        dt = toc - told;

        v = div(dy,dt);
        a = div(v, dt);

        F = m * a;

        if(sign(dy) ~=0)
            trend = sign(dy);
        end

        if contact == 0 && sign(dy) ~= 0
            trend_in = sign(dy);
            [trend_in toc];
        end

        %zderzenie
        if(abs(y - belka(F,x)) < eps) && (contact == 0)
            if(last_trend_in ~= 0  && last_trend_in == trend) || last_trend_in == 0

                contact = 1;
                trend_in = trend;
                last_trend_in = trend;

            end
        elseif (abs(y - belka(F,x)) > eps && (yold ~= 0) && y~=0 && (sign(yold) ~= sign(y)) && (contact == 0))
            %gdy duza predkosc, na razie slabe, bo zostaje w kontakcie po
            %obu stronach( na nowo lapie)
            
            %contact = 1;
            %trend_in = trend;
            %last_trend_in = trend;
            %[yold, y, abs(y - belka(F,x)), eps]
            
            %contact = 0;
        else
            %null;
        end


        if(contact == 1)


            Q = 3 * y * E*I / (x^3); % y => w, x => l
            w = Q*dx.^3/(3*E*I);
            wprim = Q*dx.^2/(2*E*I);
            [Q, F toc];
            
            


            [sign(y) abs(belka(Q,x)), eps, x,Q];


            %empirycznie dobrany wspolczynnik, > 1 zapobiega drganiom
            %manipulatora w okolicy pol rownowagi i zapewnia ciaglosc
            %kontaktu z belka
            %zbyt duza wartosc - nie wylapuje odpowienio kontaktu
            if (abs(belka(Q,x)) < 1.044*eps)

                if(last_trend_in ~= 0  && last_trend_in == -trend) || last_trend_in == 0

                    contact = 0;
                    konto = 0;
                    [abs((belka(Q,x))), last_trend_in, trend, (last_trend_in == -trend)];
                end
            else
                
                
                apply_force(h,-Q/force_scale);
            end
            

            %F = 100;
            %wspornikowa
            %w = 5*F*l^2/(24*E*I) * dx.^2 -  F*l/(12*E*I) * dx.^3;

            %wsp, sila na 'koncu'
            %w = F*dx.^3/(3*E*I);
        else
            apply_force(h,0);
            elsekontakt = 0;
            dx = 0:0.001:l;
            w = dx *0;
        end
%if length(w) >= 1
%    last = w(end-1);
%else
%    last = w(end);
%end
%a =  (-1)*(w(end) - last / 0.1);

%sizeMesh = length(mesh);
%reszta = w(end) + a*(mesh(length(w):length(mesh))-length(w)*0.001);
%w = [w, reszta]

%reszta_dx = mesh(length(dx):length(mesh))
%dx = [dx,reszta_dx]


%dx liczony od zamocowania do miejsca dzialania sily
%nalezy obliczyc kat stycznej i przedluzyc


       % ret = [ret; [dy, dt, v, a, F, 0, x,y,z, w(end)]];

    else
        contact = 0;
        last_trend_in = 0;
        dx = 0:0.001:l;
        w = dx *0;
    end

    


%Q - wartosc sily, obliczona na podstawie m*d2x/dt2 z falcona
%b - punkt uderzenia w belke (belka jeset w srodku, roznica polozen )
%x - zmienna od 0 - l

%Rb = F*x/l;
%Ra = F - Rb;

%Mg = Ra*x - F*(x-b);

          clf
          hold on
          %plot(dx,w);
          plot(x,y,'o');
          
          step = 0.001;
          da = 0:step:bok;
Y = zeros(length(dx),length(da));
for i=1:length(da)
    Y(:,i) = w(:)  - da(i);
end
Y = Y';
X = meshgrid(dx,da);
[sizey,sizex] = size(X);
if(sizex > 1 && sizey > 1 && length(X) == length(Y))
    color = zeros(sizey,sizex);
    center = (sizey)/2;
    for i=1:sizex
        for j=1:sizey
            if j < center
                z = center - j;
            else
                z = j - center;
            end
            
            color(j,i) = (1.5*sizex-i)*(1)*z;
        end
    end

    if w(end)~=0
        
        colormap(jet(ceil(abs(w(end)*1000))));
    else
        colormap(jet(2));
    end
%colormap('pink');
    surf(X,Y,color,'EdgeColor','none')
    %colorbar();

end


          %axis([-100,100,-100,100]) 
          %axis([-0.02,0.08,-0.15,0.15]) troche mala jeszcze
          axis([-0.01,0.07,-0.06,0.06]) 
          axis square;
          
          text(dx(end) + 0.005,w(end), ['w = ',num2str(w(end)*1000), 'mm'],'FontSize',10);
          %M(count)=getframe; %nie potrzebuje nagrywac
          %count=count+1;
          getframe;
          
          yold = ynew;
          told = toc;
end
          %plot(dx,w);
          %hold on
          %plot(x,y,'*');
          %axis([-100,100,-100,100]) 
          %axis([-0.02,0.08,-0.15,0.15]) 
          
close(h);
clear h

%movie(M,2,12);