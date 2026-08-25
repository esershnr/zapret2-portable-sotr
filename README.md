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
1. [`Baslat.bat`](file:///Baslat.bat) dosyasına sağ tıklayıp **Yönetici olarak** çalıştırın.
   - Açılan terminal penceresini kapatmayın (isterseniz simge durumuna küçültebilirsiniz).
   - Discord ve web siteleri için erişim anında aktifleşir.
2. Programı kapatmak istediğinizde [`Durdur.bat`](file:///Durdur.bat) dosyasını çalıştırmanız yeterlidir.

### Seçenek 2: Windows Servisi (Otomatik & Arka Planda)
1. [`Servis_Kur.bat`](file:///Servis_Kur.bat) dosyasına çift tıklayın ve yönetici iznini onaylayın.
   - Hiçbir CMD/terminal penceresi açık kalmaz.
   - Windows her başladığında sistem servisi olarak arka planda sessizce çalışır.
2. Servisi kaldırmak istediğinizde [`Servis_Sil.bat`](file:///Servis_Sil.bat) dosyasını çalıştırmanız yeterlidir.

---

## 🔧 DNS ve Sorun Çözümü

- Eğer Discord açılışta *"Checking for updates"* ekranında takılıyorsa veya bağlantı sorunları yaşıyorsanız:
  - [`DNS_Ayarla.cmd`](file:///DNS_Ayarla.cmd) dosyasını 1 kez çalıştırın.
  - Bu işlem ağ kartınıza **Cloudflare DNS (1.1.1.1 & 1.0.0.1 ve IPv6)** adreslerini tanımlar.

---

## 📁 Liste Yönetimi (`files/` Klasörü)

Kendi engelli web sitelerinizi veya alan adlarınızı eklemek isterseniz:
- [`files/list-discord.txt`](file:///files/list-discord.txt) ➔ Discord servis ve medya alan adları
- [`files/list-other.txt`](file:///files/list-other.txt) ➔ Diğer engelli web siteleri

---

## 👏 Teşekkür & Atıf (Credits)

- **Zapret:** Bu proje, [@bol-van](https://github.com/bol-van) tarafından geliştirilen harika DPI engelleme aracı [zapret](https://github.com/bol-van/zapret) üzerine inşa edilmiştir.
- **Yapılandırma & Optimizasyon:** [@esershnr](https://github.com/esershnr)

---

## ⚖️ Sorumluluk Reddi (Disclaimer)

Bu yazılım ve yapılandırma yalnızca bilgi edinme, sansürsüz internet erişimi ve eğitim amaçlı sunulmuştur. Kullanımdan doğabilecek sorumluluk kullanıcıya aittir.
