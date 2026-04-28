# PayTR Direkt API Entegrasyon Örnekleri

Bu depo, PayTR Direkt API (1. Adım ve 2. Adım) entegrasyonu için farklı platformlarda hazırlanmış güvenli ve basit örnek kodları içerir.

## 📂 Klasör Yapısı

### 1. [dotnet-paytr](./dotnet-paytr)
.NET (C#) platformu için PayTR entegrasyon örneklerini içerir.
- **PayTrService.cs**: Token oluşturma ve ödeme formu URL'sini alma işlemlerini yapan ana servis sınıfı.
- **Program.cs**: Servisin Konsol, MVC veya Web API projelerinde nasıl kullanılacağını gösteren örnekler.
- **README.md**: .NET projesi için detaylı kurulum ve kullanım kılavuzu.

**Öne Çıkan Özellikler:**
- SHA256 + Base64 güvenli hash algoritması.
- Test ve Canlı ortam desteği.
- Asenkron HTTP istekleri.
- Modern .NET standartlarına uygunluk.

### 2. [classic-asp-paytr](./classic-asp-paytr)
Klasik ASP (Active Server Pages) platformu için PayTR entegrasyon örneklerini içerir.
- **paytr_helper.asp**: .NET Framework'ün `System.Security.Cryptography` kütüphanesini kullanan güvenli SHA256 ve Base64 yardımcı fonksiyonları.
- **paytr_odeme.asp**: Sepet oluşturma, hash hesaplama, API isteği ve iframe yönlendirmesini yapan ana ödeme sayfası.
- **merchant-callback.asp**: PayTR'den gelen bildirimleri (IPN) karşılayan, hash doğrulaması yapan ve veritabanını güncelleyen handler.
- **README.md**: Classic ASP projesi için IIS ayarları, kurulum ve güvenlik notları.

**Öne Çıkan Özellikler:**
- CAPICOM bağımlılığı olmayan, güvenli .NET Crypto tabanlı SHA256 implementasyonu.
- Test ve Canlı mod desteği.
- Dinamik sepet ve taksit seçenekleri.
- Responsive iframe yapısı.

## 🚀 Hızlı Başlangıç

İlgili teknolojiye sahip klasöre giderek `README.md` dosyasındaki talimatları izleyebilirsiniz:

- **.NET Projesi İçin:** [dotnet-paytr/README.md](./dotnet-paytr/README.md)
- **Classic ASP Projesi İçin:** [classic-asp-paytr/README.md](./classic-asp-paytr/README.md)

## ⚠️ Güvenlik Uyarısı

- `Merchant ID`, `Merchant Key` ve `Merchant Salt` gibi hassas bilgileri asla kod içinde sabit değer olarak tutmayınız.
- Production ortamında bu bilgileri `appsettings.json`, `.env` dosyaları veya ortam değişkenleri (Environment Variables) üzerinden yönetiniz.
- Classic ASP projelerinde sunucu tarafı gizliliğine dikkat ediniz.

## 📄 Lisans
Bu proje örnek amaçlı hazırlanmıştır.
