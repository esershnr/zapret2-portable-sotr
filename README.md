# Zapret 2 Portable (Türkiye & Superonline)

Bu repo, **Türkiye** ve özellikle **Superonline** ağ altyapısındaki DPI / erişim kısıtlamalarını aşmak için optimize edilmiş taşınabilir (portable) **Zapret 2** yapılandırmasıdır. 

Discord (ses kanalları ve medya sunucuları dahil) ile engelli web sitelerine kesintisiz erişim sağlarken; oyun platformlarına (Steam, Ubisoft, Rockstar, Epic Games vb.) kesinlikle müdahale etmez.

---

## 🚀 Özellikler

- **Superonline ve Türkiye İSS Uyumu:** Superonline DPI filtreleri ve Türkiye geneli kısıtlamalar için özel olarak test edilmiş ve ayarlanmıştır.
- **Discord & Web Optimizasyonu:** Discord ses/görüntü/medya bağlantıları ve popüler servisler için hazır domain listeleri.
- **Oyun Dostu:** Oyun sunucularında ping artışına veya bağlantı kopmalarına yol açmaz.
- **Taşınabilir (Portable):** Kurulum gerektirmeden tek tıkla çalıştırılabilir.
- **Windows Servis Desteği:** Arka planda terminal penceresi açılmadan otomatik olarak Windows ile birlikte başlatılabilir.

---

## 📖 Kullanım Seçenekleri

### Seçenek 1: Manuel Kullanım (Portatif)
1. [`Baslat.bat`](Baslat.bat) dosyasına sağ tıklayıp **Yönetici olarak** çalıştırın.
   - Açılan terminal penceresini kapatmayın (isterseniz simge durumuna küçültebilirsiniz).
   - Discord ve web siteleri için erişim anında aktifleşir.
2. Programı kapatmak istediğinizde [`Durdur.bat`](Durdur.bat) dosyasını çalıştırmanız yeterlidir.

### Seçenek 2: Windows Servisi (Otomatik & Arka Planda)
1. [`Servis_Kur.bat`](Servis_Kur.bat) dosyasına çift tıklayın ve yönetici iznini onaylayın.
   - Hiçbir CMD/terminal penceresi açık kalmaz.
   - Windows her başladığında sistem servisi olarak arka planda sessizce çalışır.
2. Servisi kaldırmak istediğinizde [`Servis_Sil.bat`](Servis_Sil.bat) dosyasını çalıştırmanız yeterlidir.

### Seçenek 3: Baslat.bat Sizde Çalışmıyorsa (Blockcheck ile Kişisel Ayar)
Hazır ayar Superonline'da test edildi. Farklı bir İSS'de (Türk Telekom, Vodafone, Turknet vb.) çalışmazsa:
1. Çalışan zapret varsa kapatın; VPN, GoodbyeDPI gibi araçları da kapatın.
2. [`Blockcheck.cmd`](Blockcheck.cmd) dosyasını çalıştırın.
   - İlk çalıştırmada [zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle) (~40 MB) `blockcheck\bundle` klasörüne indirilir.
   - Windows Defender zapret dosyalarını silebileceği için klasörü istisnalara eklemeyi önerir.
   - Test edilecek alan adlarını sorar (varsayılan: `discord.com`). 5-20 dakika sürebilir.
3. Test bitince size özel **`Baslat-Kisisel.bat`** ve **`Servis_Kur-Kisisel.bat`** oluşturulur. Artık bunları kullanın.
   - Strateji iki listedeki (`list-discord.txt`, `list-other.txt`) tüm sitelere uygulanır.
   - Tam test çıktısı: `blockcheck\blockcheck2.log`. Sorun olursa bu dosyayı paylaşın.

---

## 🔧 DNS ve Sorun Çözümü

- Eğer Discord açılışta *"Checking for updates"* ekranında takılıyorsa veya bağlantı sorunları yaşıyorsanız:
  - [`DNS_Ayarla.cmd`](DNS_Ayarla.cmd) dosyasını 1 kez çalıştırın.
  - Bu işlem ağ kartınıza **Cloudflare DNS (1.1.1.1 & 1.0.0.1 ve IPv6)** adreslerini tanımlar.
  - Cloudflare yerine Google DNS (8.8.8.8) isterseniz [`DNS_Ayarla_Google.cmd`](DNS_Ayarla_Google.cmd) kullanın.
- Blockcheck "DNS HIJACK" uyarısı verirse İSS'niz DNS cevaplarını değiştiriyor demektir; önce DNS'i ayarlayın.
- Başlatma dosyaları Windows'ta varsayılan olarak kapalı olan **TCP timestamp** özelliğini açar (`netsh interface tcp set global timestamps=enabled`). Bazı stratejiler buna ihtiyaç duyar.

---

## 📁 Liste Yönetimi (`files/` Klasörü)

Kendi engelli web sitelerinizi veya alan adlarınızı eklemek isterseniz:
- [`files/list-discord.txt`](files/list-discord.txt) ➔ Discord servis ve medya alan adları
- [`files/list-other.txt`](files/list-other.txt) ➔ Diğer engelli web siteleri

---

## 👏 Teşekkür & Atıf (Credits)

- **Zapret:** Bu proje, [@bol-van](https://github.com/bol-van) tarafından geliştirilen harika DPI atlatma aracı [zapret2](https://github.com/bol-van/zapret2) ve [zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle) üzerine inşa edilmiştir.
- **Yapılandırma & Optimizasyon:** [@esershnr](https://github.com/esershnr)

---

## ⚖️ Sorumluluk Reddi (Disclaimer)

Bu yazılım ve yapılandırma yalnızca bilgi edinme, sansürsüz internet erişimi ve eğitim amaçlı sunulmuştur. Kullanımdan doğabilecek sorumluluk kullanıcıya aittir.
