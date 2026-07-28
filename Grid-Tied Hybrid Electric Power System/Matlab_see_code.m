clear all
clc
clearvars
close all

% Simulação anual de um sistema PV + eólico + bateria + rede

load('Data_T.mat')

% Parâmetros do painel fotovoltaico Sharp ND-R250A5
Pref = 250;
Gref_sic = 1000;
Tref_sic = 25;
a_voc = -0.0029;

Tref_noct = 20;
NOCT = 47.5;
Gref_noct = 800;

Ns = 5;
Np = 25;
umppt = 0.95;

Ppv_instalada = Pref * Ns * Np;



% Parâmetros da turbina Bergey BWC XL.1
Pw_r = 1.2e3;

Vcin = 2.0;
Vr = 13.0;
Vcont = 20.0;

Nwg = 4;

Pwind_instalada = Pw_r * Nwg;

% Média móvel do preço da energia
media_dias = 24*5;

% Simulação de 1 ano
data_i = 1;
data_e = data_i + 24*365 - 1;
data_e = min(data_e, length(Data_T.G));

t = data_i:1:data_e;

G = Data_T.G(data_i:1:data_e);
Vw = Data_T.wind(data_i:1:data_e);
e_load = Data_T.load(data_i:1:data_e);
Tamb = Data_T.temp(data_i:1:data_e);
preco = Data_T.price(data_i:1:data_e)/1000;

N = length(t);

Ppv = zeros(1,N);
Pwind = zeros(1,N);
Pcompra = zeros(1,N);
Pvenda = zeros(1,N);
P_net = zeros(1,N);


% Parâmetros da bateria
% Modelo escolhido: BYD Battery-Box Commercial C130

Ebat_max = 131e3;        % capacidade útil da bateria [Wh] = 131 kWh
Pbat_max = 88e3;         % potência máxima de carrega/descarrega [W] = 88 kW

SOC_ini = 50          % estado inicial da bateria [%]
SOC_min = 20;        % limite mínimo de utilização [%]
SOC_max = 90;       % limite máximo de utilização [%]

eta_carrega = 0.95;  % rendimento quando a bateria carrega
eta_descarrega = 0.95; % rendimento quando a bateria descarrega

Ebat = Ebat_max * SOC_ini/100;

Pbatt = zeros(1,N);
SOC = zeros(1,N);

% Simulação horária
for h = 1:N

    % Produção fotovoltaica
    Tcell = Tamb(h) + (G(h)/Gref_noct)*(NOCT - Tref_noct);
    Ppv(h) = umppt * (Pref * (G(h)/Gref_sic) * (1 + a_voc*(Tcell - Tref_sic)));
    Ppv(h) = max(Ppv(h), 0);
    Ppv(h) = Ppv(h) * Ns * Np;

    % Produção eólica
    if Vw(h) > Vcin && Vw(h) < Vr
        Pwind(h) = Pw_r * ((Vw(h)^3 - Vcin^3) / (Vr^3 - Vcin^3));
    
    elseif Vw(h) >= Vr && Vw(h) < Vcont
        Pwind(h) = Pw_r;
    
    else
        Pwind(h) = 0;
    end

    Pwind(h) = Pwind(h) * Nwg;

    % Balanço entre carga e produção
    P_net(h) = e_load(h) - Ppv(h) - Pwind(h);

    % Cálculo do preço médio
    if h > media_dias
        preco_medio = mean(preco(h-media_dias:h));
    else
        preco_medio = mean(preco(1:h));
    end

    SOC_atual = 100 * Ebat / Ebat_max;

    % Gestão da bateria e da rede
    if P_net(h) < 0

        excesso = abs(P_net(h));
        E_livre = Ebat_max * SOC_max/100 - Ebat;

        if preco(h) > preco_medio || SOC_atual >= SOC_max
            Pvenda(h) = excesso;
        else
            P_carrega = min([excesso, Pbat_max, E_livre]);
            Ebat = Ebat + P_carrega * eta_carrega;
            Pbatt(h) = -P_carrega;
            Pvenda(h) = excesso - P_carrega;
        end

    else

        falta = P_net(h);
        E_disponivel = Ebat - Ebat_max * SOC_min/100;

        if preco(h) < preco_medio || SOC_atual <= SOC_min
        
            Pcompra(h) = falta;
        else
            P_descarrega = min([falta, Pbat_max, E_disponivel]);
            Ebat = Ebat - P_descarrega / eta_descarrega;
            Pbatt(h) = P_descarrega;
            Pcompra(h) = falta - P_descarrega;
        end

    end

    Ebat = min(max(Ebat, Ebat_max*SOC_min/100), Ebat_max*SOC_max/100);
    SOC(h) = 100 * Ebat / Ebat_max;

end

% Resultados principais
Ptotal = Ppv + Pwind;

[~, idx_max] = max(Ptotal);
dia_max_producao = floor((t(idx_max)-1)/24) + 1;

energia_total = sum(Ptotal)/1000;
energia_carga = sum(e_load)/1000;
energia_comprada = sum(Pcompra)/1000;
energia_vendida = sum(Pvenda)/1000;
energia_bateria_carrega = sum(abs(Pbatt(Pbatt < 0)))/1000;
energia_bateria_descarrega = sum(Pbatt(Pbatt > 0))/1000;
saldo_energia = energia_total - energia_carga;

[~, idx_preco_max] = max(preco);
hora_preco_max = t(idx_preco_max);

horas_bateria = find(Pbatt ~= 0);
media_producao = mean(Ptotal);

disp('============================================================')
disp('RESULTADOS DA SIMULAÇÃO ANUAL')
disp('============================================================')
disp(['Potência PV instalada: ', num2str(Ppv_instalada/1000), ' kW'])
disp(['Potência eólica instalada: ', num2str(Pwind_instalada/1000), ' kW'])
disp(['Potência renovável total instalada: ', num2str((Ppv_instalada + Pwind_instalada)/1000), ' kW'])
disp(['Dia com maior produção total: ', num2str(dia_max_producao)])
disp(['Energia total gerada: ', num2str(energia_total), ' kWh'])
disp(['Energia total consumida pela carga: ', num2str(energia_carga), ' kWh'])
disp(['Energia total comprada: ', num2str(energia_comprada), ' kWh'])
disp(['Energia total vendida: ', num2str(energia_vendida), ' kWh'])
disp(['Energia quando a bateria carrega: ', num2str(energia_bateria_carrega), ' kWh'])
disp(['Energia quando a bateria descarrega: ', num2str(energia_bateria_descarrega), ' kWh'])
disp(['Saldo energético total: ', num2str(saldo_energia), ' kWh'])
disp(['Hora com preço máximo da energia: ', num2str(hora_preco_max)])
disp(['Horas com uso da bateria: ', num2str(length(horas_bateria))])
disp(['Média de potência gerada por hora: ', num2str(media_producao), ' W'])
disp(['SOC final da bateria: ', num2str(SOC(end)), ' %'])
disp(['Último preço médio calculado: ', num2str(preco_medio), ' €/kWh'])
disp('============================================================')

% Escalas de tempo para os gráficos
tempo_dias = t/24;

semana_escolhida = 1;

idx_semana_i = (semana_escolhida - 1)*24*7 + 1;
idx_semana_f = idx_semana_i + 24*7 - 1;
idx_semana_f = min(idx_semana_f, N);

idx_semana = idx_semana_i:idx_semana_f;
tempo_semana = 1:length(idx_semana);

Pbatt_descarrega = max(Pbatt, 0);
Pbatt_carrega = -min(Pbatt, 0);

% Gráfico anual de áreas
figure(1)
clf
hold on

matriz_anual = [Ppv', Pwind', Pcompra', Pvenda', Pbatt_descarrega', Pbatt_carrega'];

area(tempo_dias, matriz_anual/1000)
plot(tempo_dias, e_load/1000, 'k', 'LineWidth', 1.2)

legend({'PV','Wind','Compra da rede','Venda à rede','Bateria descarrega','Bateria carrega','Carga'}, 'Location','best')
xlabel('Tempo [dias]')
ylabel('Potência [kW]')
title('Sistema híbrido PV + Eólico + Bateria + Rede - 1 ano')

grid on
box on
hold off

% SOC anual
figure(2)
clf
hold on

plot(tempo_dias, SOC, 'LineWidth', 1.2)
yline(SOC_min, '--', 'SOC mínimo')
yline(SOC_max, '--', 'SOC máximo')

grid on
box on

xlabel('Tempo [dias]')
ylabel('SOC [%]')
title('Estado de carga da bateria - 1 ano')
ylim([0 100])

hold off

% Bateria anual
figure(3)
clf
hold on

area(tempo_dias, Pbatt_descarrega/1000)
area(tempo_dias, -Pbatt_carrega/1000)
yline(0, '--')

grid on
box on

xlabel('Tempo [dias]')
ylabel('Potência da bateria [kW]')
title('Potência da bateria - carrega e descarrega - 1 ano')

legend({'Bateria descarrega','Bateria carrega','Zero'}, 'Location','best')

hold off

% Gráfico semanal de áreas
figure(4)
clf
hold on

matriz_semana = [Ppv(idx_semana)', Pwind(idx_semana)', Pcompra(idx_semana)', Pvenda(idx_semana)', Pbatt_descarrega(idx_semana)', Pbatt_carrega(idx_semana)'];

area(tempo_semana, matriz_semana/1000)
plot(tempo_semana, e_load(idx_semana)/1000, 'k', 'LineWidth', 1.5)

legend({'PV','Wind','Compra da rede','Venda à rede','Bateria descarrega','Bateria carrega','Carga'}, 'Location','best')
xlabel('Tempo [horas]')
ylabel('Potência [kW]')
title(['Sistema híbrido PV + Eólico + Bateria + Rede - Semana ', num2str(semana_escolhida)])

grid on
box on
hold off

% SOC semanal
figure(5)
clf
hold on

plot(tempo_semana, SOC(idx_semana), 'LineWidth', 1.5)
yline(SOC_min, '--', 'SOC mínimo')
yline(SOC_max, '--', 'SOC máximo')

grid on
box on

xlabel('Tempo [horas]')
ylabel('SOC [%]')
title(['Estado de carga da bateria - Semana ', num2str(semana_escolhida)])
ylim([0 100])

hold off

% Bateria semanal
figure(6)
clf
hold on

area(tempo_semana, Pbatt_descarrega(idx_semana)/1000)
area(tempo_semana, -Pbatt_carrega(idx_semana)/1000)
yline(0, '--')

grid on
box on

xlabel('Tempo [horas]')
ylabel('Potência da bateria [kW]')
title(['Potência da bateria - carrega e descarrega - Semana ', num2str(semana_escolhida)])

legend({'Bateria descarrega','Bateria carrega','Zero'}, 'Location','best')

hold off