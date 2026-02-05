clc;
clear;

% Malzeme ve kesit özellikleri
epsilon_sy = 0.002175;          % Akma birim şekil değiştirmesi
fyd = 435;                      % Tasarım akma dayanımı (MPa)
fcd = 23.3333;                  % Beton tasarım basınç dayanımı (MPa)
elastisitemodulu = 2*10^5;      % Çelik elastisite modülü (MPa)
kisa_kenar = 300;               % Kesit genişliği (mm)
uzun_kenar = 700;               % Kesit yüksekliği (mm)
paspayi = 50;                   % Pas payı (mm)
k_1 = 0.79;                     % Beton basınç bloğu katsayısı
faydali_yukseklik = uzun_kenar - paspayi;

% Donatı özellikleri
donati_capi = 18;               % Donatı çapı (mm)
donati_alani = pi * donati_capi^2 / 4;  % Tek donatı alanı (mm²)
toplam_yerlestirilecek_donati = 10;

% Donatı bölgesi matrisini oluştur
donati_bolgesi = zeros(kisa_kenar, uzun_kenar);

% Kullanıcıdan donatı yerlerini al
fprintf('Donatı yerleştirme (1 ile %d mm arası y koordinatları)\n', uzun_kenar);
for i = 1:toplam_yerlestirilecek_donati
    fprintf('\n%d. donatı:\n', i);
    donati_x = input('  x koordinatı (mm): ');
    donati_y = input('  y koordinatı (mm): ');
    
    % Sınır kontrolü
    if donati_x < 1 || donati_x > kisa_kenar || donati_y < 1 || donati_y > uzun_kenar
        warning('Koordinatlar geçersiz! Donatı kesit dışında.');
        continue;
    end
    
    donati_bolgesi(donati_y, donati_x) = 1;
end

% Toplam donatı alanı
toplam_donati_alani = toplam_yerlestirilecek_donati * donati_alani;
fprintf('\nToplam donatı alanı: %.2f mm²\n', toplam_donati_alani);

% Donatıları görselleştir
se = strel('disk', donati_capi/2);
B = imdilate(donati_bolgesi, se);
figure('Name', 'Donatı Yerleşimi');
imagesc(B);
colormap(gray);
axis equal tight;
title('Donatılar ile Yerleşim Alanı');
xlabel('Uzun Kenar (mm)');
ylabel('Kısa Kenar (mm)');
colorbar;

% Donatı bulunan satırları bul
[row, ~] = find(donati_bolgesi == 1);
v = zeros(size(donati_bolgesi, 1), 1);
v(row) = 1;

% Tarafsız eksen hesabı için iterasyon parametreleri
tolerance = 0.1;            % Kuvvet dengesi toleransı (N)
max_iterations = 100000;    % Maksimum iterasyon sayısı
iteration = 0;
c = uzun_kenar / 2;        % Başlangıç tarafsız eksen konumu (mm)
step_size = 0.01;          % Adım büyüklüğü (mm)

% Tarafsız eksen hesabı - İyileştirilmiş algoritma
fprintf('\nTarafsız eksen hesaplanıyor...\n');

% Bisection yöntemi için başlangıç değerleri
c_min = paspayi;
c_max = uzun_kenar - paspayi;
c = (c_min + c_max) / 2;

netkuvvet = inf;

while abs(netkuvvet) > tolerance && iteration < max_iterations
    iteration = iteration + 1;
    netkuvvet = 0.0;
    
    % Birim şekil değiştirmeleri hesapla
    birimsekildegistirmeler = zeros(size(donati_bolgesi, 1), 1);
    for i = 1:length(v)
        if v(i) == 1
            if c > i
                birimsekildegistirmeler(i) = (c - i) * 0.003 / c;
            elseif c < i
                birimsekildegistirmeler(i) = -(i - c) * 0.003 / c;
            else
                birimsekildegistirmeler(i) = 0;
            end
        end
    end
    
    % Akan ve akmayan donatıları belirle
    akan_akmayan_donatilar = zeros(size(donati_bolgesi, 1), 1);
    for i = 1:length(birimsekildegistirmeler)
        if birimsekildegistirmeler(i) ~= 0
            if abs(birimsekildegistirmeler(i)) <= epsilon_sy
                akan_akmayan_donatilar(i) = 2; % Akmıyor
            else
                akan_akmayan_donatilar(i) = 1; % Akıyor
            end
        end
    end
    
    % Donatı kuvvetlerini hesapla
    kuvvetmatrisi = zeros(size(donati_bolgesi, 1), 1);
    for i = 1:length(akan_akmayan_donatilar)
        if akan_akmayan_donatilar(i) == 1
            % Donatı akıyor
            count_ones = sum(donati_bolgesi(i, :) == 1);
            if birimsekildegistirmeler(i) > 0
                kuvvetmatrisi(i) = fyd * donati_alani * count_ones;  % Basınç (+)
            else
                kuvvetmatrisi(i) = -fyd * donati_alani * count_ones; % Çekme (-)
            end
        elseif akan_akmayan_donatilar(i) == 2
            % Donatı akmıyor (elastik)
            count_ones = sum(donati_bolgesi(i, :) == 1);
            kuvvetmatrisi(i) = birimsekildegistirmeler(i) * elastisitemodulu * donati_alani * count_ones;
        end
    end
    
    % Net kuvveti hesapla
    netkuvvet = sum(kuvvetmatrisi);
    
    % Beton basınç bloğunu ekle
    netkuvvet = netkuvvet + 0.85 * fcd * k_1 * c * kisa_kenar;
    
    % Bisection yöntemi ile c'yi güncelle
    if netkuvvet > tolerance
        c_max = c;
        c = (c_min + c_max) / 2;
    elseif netkuvvet < -tolerance
        c_min = c;
        c = (c_min + c_max) / 2;
    else
        break; % Yakınsama sağlandı
    end
    
    % İlerleme raporu (her 1000 iterasyonda)
    if mod(iteration, 1000) == 0
        fprintf('İterasyon %d: c = %.4f mm, Net Kuvvet = %.4f N\n', iteration, c, netkuvvet);
    end
end

% Sonuçları göster
fprintf('\n========== SONUÇLAR ==========\n');
if iteration >= max_iterations
    warning('Maksimum iterasyon sayısına ulaşıldı! Yakınsama sağlanamadı.');
    fprintf('Son net kuvvet: %.4f N (Tolerans: %.2f N)\n', netkuvvet, tolerance);
else
    fprintf('Yakınsama başarılı!\n');
end
fprintf('Tarafsız eksen konumu: %.4f mm\n', c);
fprintf('Net kuvvet: %.4f N\n', netkuvvet);
fprintf('İterasyon sayısı: %d\n', iteration);
fprintf('Basınç bölgesi yüksekliği: %.4f mm\n', k_1 * c);
fprintf('Faydalı yükseklik: %.4f mm\n', faydali_yukseklik);
fprintf('c/d oranı: %.4f\n', c / faydali_yukseklik);

% Şekil değiştirme ve gerilme dağılımını görselleştir
figure('Name', 'Şekil Değiştirme ve Gerilme Dağılımı');
subplot(1, 2, 1);
y_coords = 1:uzun_kenar;
epsilon_dist = zeros(size(y_coords));
for i = 1:length(y_coords)
    if y_coords(i) < c
        epsilon_dist(i) = (c - y_coords(i)) * 0.003 / c;
    else
        epsilon_dist(i) = -(y_coords(i) - c) * 0.003 / c;
    end
end
plot(epsilon_dist * 1000, y_coords, 'b-', 'LineWidth', 2);
hold on;
plot([0 0], [0 uzun_kenar], 'k--', 'LineWidth', 1);
yline(c, 'r--', 'Tarafsız Eksen', 'LineWidth', 2);
xlabel('Birim Şekil Değiştirme (×10⁻³)');
ylabel('Kesit Yüksekliği (mm)');
title('Şekil Değiştirme Dağılımı');
grid on;
set(gca, 'YDir', 'reverse');

subplot(1, 2, 2);
% Donatı konumlarını ve kuvvetlerini göster
donati_positions = find(v == 1);
donati_forces = kuvvetmatrisi(donati_positions);
scatter(donati_forces / 1000, donati_positions, 100, 'filled');
hold on;
yline(c, 'r--', 'Tarafsız Eksen', 'LineWidth', 2);
plot([0 0], [0 uzun_kenar], 'k--', 'LineWidth', 1);
xlabel('Donatı Kuvveti (kN)');
ylabel('Kesit Yüksekliği (mm)');
title('Donatı Kuvvetleri');
grid on;
set(gca, 'YDir', 'reverse');

fprintf('\n==============================\n');