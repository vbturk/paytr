# PayTR Direkt API Entegrasyonu (.NET)

Bu proje, PayTR Direkt API kullanarak kredi kartı tahsilatı yapmak için basit ve güvenli bir .NET çözümüdür.

## 📋 Özellikler

- ✅ **1. Adım**: Token oluşturma (PayTR API'den ödeme token'ı alma)
- ✅ **2. Adım**: Ödeme formu URL'i oluşturma (3D Secure ödeme sayfasına yönlendirme)
- 🔒 SHA256 + Base64 hash algoritması ile güvenli iletişim
- 🧪 Test ve canlı ortam desteği
- 📦 Ürün/sepet bilgisi desteği
- 💳 Taksit seçenekleri kontrolü
- 🌐 Çoklu dil desteği (TR/EN)

## 🚀 Kurulum

### 1. Projeyi Oluşturun

```bash
dotnet new console -n PayTrIntegration
cd PayTrIntegration
```

### 2. Dosyaları Kopyalayın

Aşağıdaki dosyaları proje klasörünüze kopyalayın:
- `PayTrService.cs` - Ana servis sınıfı
- `Program.cs` - Kullanım örneği

### 3. Mağaza Bilgilerinizi Girin

`Program.cs` dosyasında kendi PayTR mağaza bilgilerinizi girin:

```csharp
string merchantId = "YOUR_MERCHANT_ID";    // PayTR panelinden aldığınız Merchant ID
string merchantKey = "YOUR_MERCHANT_KEY";  // PayTR panelinden aldığınız Merchant Key
```

⚠️ **GÜVENLİK UYARISI**: Gerçek projelerinizde bu bilgileri asla kod içinde sabit değer olarak tutmayın! 
- `appsettings.json` dosyasından okuyun
- Environment variables kullanın
- Azure Key Vault veya benzeri güvenli depolama çözümleri kullanın

## 📖 Kullanım

### Temel Kullanım

```csharp
// Servisi başlat
var payTrService = new PayTrService(merchantId, merchantKey, useTestEnvironment: true);

// Ödeme isteği oluştur
var paymentRequest = new PaymentRequest
{
    OrderId = "ORDER-123456",
    Amount = 100.50m,
    BuyerName = "Ahmet Yılmaz",
    BuyerEmail = "ahmet@email.com",
    UserIp = "192.168.1.100"
};

// 1. ADIM: Token al
var tokenResponse = await payTrService.GetPaymentTokenAsync(paymentRequest);

// 2. ADIM: Ödeme formu URL'ini oluştur
var paymentFormUrl = payTrService.GetPaymentFormUrl(tokenResponse.Token);

// Müşteriyi ödeme sayfasına yönlendir
return Redirect(paymentFormUrl);
```

### ASP.NET MVC / Core MVC Örneği

```csharp
[HttpPost]
public async Task<IActionResult> Checkout(PaymentViewModel model)
{
    var merchantId = _config["PayTr:MerchantId"];
    var merchantKey = _config["PayTr:MerchantKey"];
    
    var payTrService = new PayTrService(merchantId, merchantKey, useTestEnvironment: true);
    
    var paymentRequest = new PaymentRequest
    {
        OrderId = model.OrderId,
        Amount = model.Amount,
        BuyerName = model.BuyerName,
        BuyerEmail = model.BuyerEmail,
        UserIp = GetClientIpAddress(), // Client IP'yi alın
        TestMode = true
    };
    
    var tokenResponse = await payTrService.GetPaymentTokenAsync(paymentRequest);
    var paymentUrl = payTrService.GetPaymentFormUrl(tokenResponse.Token);
    
    return Redirect(paymentUrl);
}

private string GetClientIpAddress()
{
    return Request.HttpContext.Connection.RemoteIpAddress?.ToString();
}
```

### Web API Örneği

```csharp
[ApiController]
[Route("api/[controller]")]
public class PaymentController : ControllerBase
{
    private readonly IConfiguration _config;
    
    public PaymentController(IConfiguration config)
    {
        _config = config;
    }
    
    [HttpPost("initiate")]
    public async Task<ActionResult<PaymentInitResponse>> InitiatePayment(
        [FromBody] PaymentRequest request)
    {
        var merchantId = _config["PayTr:MerchantId"];
        var merchantKey = _config["PayTr:MerchantKey"];
        
        var payTrService = new PayTrService(merchantId, merchantKey, useTestEnvironment: true);
        
        // IP adresini ekle
        request.UserIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        
        var tokenResponse = await payTrService.GetPaymentTokenAsync(request);
        
        return Ok(new PaymentInitResponse
        {
            PaymentUrl = payTrService.GetPaymentFormUrl(tokenResponse.Token),
            OrderId = tokenResponse.MerchantOid
        });
    }
}

public class PaymentInitResponse
{
    public string PaymentUrl { get; set; }
    public string OrderId { get; set; }
}
```

## 🔧 Yapılandırma Seçenekleri

| Parametre | Açıklama | Varsayılan | Zorunlu |
|-----------|----------|------------|---------|
| `OrderId` | Sipariş numarası | Otomatik oluşturulur | Hayır |
| `Amount` | Ödeme tutarı (TL) | - | **Evet** |
| `BuyerName` | Alıcı adı soyadı | - | **Evet** |
| `BuyerEmail` | Alıcı e-posta | - | **Evet** |
| `UserIp` | Kullanıcı IP adresi | - | **Evet** |
| `DebugMode` | Debug modu | false | Hayır |
| `NoInstallment` | Taksit yok | false | Hayır |
| `TimeoutLimit` | Zaman aşımı (dakika) | 30 | Hayır |
| `Currency` | Para birimi | TRY | Hayır |
| `TestMode` | Test modu | true | Hayır |
| `Language` | Dil (tr/en) | tr | Hayır |
| `Products` | Ürün listesi | null | Hayır |

## 🔐 Güvenlik Önerileri

1. **Merchant Key'i Asla Paylaşmayın**: Bu bilgiyi kaynak kodunda saklamayın.
2. **HTTPS Kullanın**: Tüm ödeme işlemlerinde HTTPS kullanın.
3. **IP Doğrulaması**: Kullanıcı IP adresini doğru şekilde alın ve gönderin.
4. **Sipariş Kontrolü**: Ödeme sonrası sipariş durumunu mutlaka kontrol edin.
5. **Log Tutma**: Tüm ödeme işlemlerini loglayın (hassas bilgileri maskeleyerek).

## 📝 Ödeme Sonrası İşlemler

Ödeme tamamlandıktan sonra PayTR şu URL'lere bildirim gönderir:

- **Başarılı Ödeme**: `merchant_ok_url`
- **Başarısız Ödeme**: `merchant_fail_url`

Bu endpoint'lerde sipariş durumunu güncellemeyi unutmayın.

## 🧪 Test Ortamı

Test ortamı için:
- `useTestEnvironment: true` parametresini kullanın
- Test kredi kartlarını kullanın (PayTR dokümantasyonundan alabilirsiniz)
- Test işlemleri gerçek para çekmez

## 📚 Referanslar

- [PayTR Direkt API 1. Adım](https://dev.paytr.com/direkt-api/direkt-api-1-adim)
- [PayTR Direkt API 2. Adım](https://dev.paytr.com/direkt-api/direkt-api-2-adim)
- [PayTR Dokümantasyon](https://dev.paytr.com/)

## ⚠️ Sorumluluk Reddi

Bu kod örnek amaçlıdır. Canlı ortama geçmeden önce:
- Kendi güvenlik testlerinizi yapın
- PayTR'nin güncel dokümantasyonunu kontrol edin
- PCI DSS uyumluluğunu sağlayın
- Hukuki gereklilikleri yerine getirin

## 📄 Lisans

MIT License
