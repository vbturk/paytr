# PayTR Direkt API - Classic ASP Entegrasyonu

Bu klasör, PayTR Direkt API entegrasyonu için **Classic ASP** ile hazırlanmış örnek kodları içerir.

## 📁 Dosyalar

- `paytr_odeme.asp` - Tek dosyada 1. ve 2. adım işlemlerini yapan tam örnek

## 🔧 Kurulum

### 1. Gereksinimler
- Windows Server + IIS
- Classic ASP desteği aktif olmalı
- MSXML2.ServerXMLHTTP.6.0 komponenti yüklü olmalı
- CAPICOM (SHA256 hash için) veya alternatif hash yöntemi

### 2. Ayarlar

`paytr_odeme.asp` dosyasının başındaki sabitleri kendi bilgilerinizle güncelleyin:

```asp
Const MERCHANT_ID = "sizin_merchant_id"     ' PayTR'den aldığınız Merchant ID
Const MERCHANT_KEY = "sizin_merchant_key"   ' PayTR'den aldığınız Merchant Key
Const TEST_MODE = True                      ' Test ortamı için True, canlı için False
```

### 3. IIS Ayarları

1. IIS Manager'ı açın
2. Site'nize gidin
3. "ASP" özelliğini bulun
4. "Enable Parent Paths" = **True** yapın
5. Application Pool'unuzun .NET Framework versiyonu Classic ASP için önemli değil (Classic ASP .NET'ten bağımsızdır)

## 📖 Kullanım

### Temel Kullanım

Dosyayı IIS üzerinde çalıştırın:
```
http://siteniz.com/classic-asp-paytr/paytr_odeme.asp
```

### Kod Akışı

#### 1. Adım: Token Oluşturma
```asp
Function CreatePayTrToken()
    ' Hash oluşturma: SHA256(MerchantID + orderId + amount + ... + MerchantKey)
    ' HTTP POST ile PayTR API'ye istek gönderme
    ' Token döndürme
End Function
```

#### 2. Adım: Ödeme Formu URL'i
```asp
Function GetPaymentIframeUrl(token)
    ' Hash oluşturma: SHA256(token + MerchantKey)
    ' HTTP POST ile PayTR API'ye istek gönderme
    ' Iframe URL'i döndürme
End Function
```

## 🔐 Güvenlik Önerileri

### ⚠️ ÖNEMLİ: Production Ortamı İçin

1. **Merchant bilgilerini kod içinde saklamayın!**
   ```asp
   ' Bunun yerine:
   Const MERCHANT_ID = "test_merchant_id"
   
   ' Şunu kullanın:
   Dim MERCHANT_ID
   MERCHANT_ID = Request.ServerVariables("PAYTR_MERCHANT_ID")
   ' veya database/config dosyasından okuyun
   ```

2. **HTTPS kullanın** - Tüm ödeme sayfalarınız HTTPS üzerinden çalışmalı

3. **IP Whitelist** - PayTR callback'leri için firewall kuralları oluşturun

4. **Loglama** - Tüm ödeme işlemlerini loglayın

5. **Input Validation** - Kullanıcıdan gelen tüm verileri doğrulayın

## 🛠️ SHA256 Hash Problemi

Classic ASP'de SHA256 hash hesaplamak için birkaç yöntem:

### Yöntem 1: CAPICOM (Önerilen)
```asp
Set oHasher = Server.CreateObject("CAPICOM.HashedData")
oHasher.Algorithm = 4 ' CAPICOM_HASH_ALGORITHM_SHA_256
oHasher.Hash inputString
hashValue = LCase(oHasher.Value)
```

### Yöntem 2: .NET Assembly Çağırma
```asp
Set objHash = Server.CreateObject("System.Security.Cryptography.SHA256Managed")
' .NET assembly'yi GAC'e yüklemeniz gerekir
```

### Yöntem 3: Third-Party Komponent
- AspCrypt
- PureASP
- Gibi komponentler kullanılabilir

## 📝 Örnek Senaryolar

### Sepet Bilgileri ile Token Oluşturma
```asp
Dim basketItems(2)
basketItems(0) = "Ürün 1|Elektronik|2|5000"
basketItems(1) = "Ürün 2|Kitap|1|2500"
basketItems(2) = "Ürün 3|Giyim|3|1500"

' Her ürün: ad|kategori|miktar|fiyat (kuruş)
```

### Taksit Seçenekleri
```asp
installments = "0"    ' Tek çekim
installments = "2"    ' 2 taksit
installments = "3,6,9,12"  ' Çoklu taksit
```

### Callback (Bildirim) Sayfası Örneği
```asp
' merchant-callback.asp
<%
Dim postData, hash, expectedHash
postData = Request.Form("merchant_oid") & Request.Form("total_amount") & MERCHANT_KEY

Set oHasher = Server.CreateObject("CAPICOM.HashedData")
oHasher.Algorithm = 4
oHasher.Hash postData
expectedHash = LCase(oHasher.Value)
Set oHasher = Nothing

hash = Request.Form("hash")

If hash = expectedHash Then
    ' Ödeme başarılı - Veritabanını güncelle
    Response.Write "OK"
Else
    ' Hash uyuşmazlığı
    Response.Write "FAIL"
End If
%>
```

## 🐛 Sorun Giderme

### "MSXML2.ServerXMLHTTP.6.0 hatası"
- Çözüm: IIS'de MSXML komponentlerinin yüklü olduğundan emin olun

### "CAPICOM.HashedData hatası"
- Çözüm: CAPICOM'u yükleyin veya alternatif hash yöntemi kullanın

### "Access denied" hatası
- Çözüm: IIS uygulama havuzunun kimliğine dosya sistemi erişim izni verin

### SSL/TLS hatası
- Çözüm: TLS 1.2'yi etkinleştirin:
  ```
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /t REG_DWORD /d 1 /f
  ```

## 📞 PayTR Destek

- Dokümantasyon: https://dev.paytr.com/
- Test ortamı: https://test.paytr.com/
- Canlı ortam: https://www.paytr.com/

## ⚠️ Yasal Uyarı

Bu kod örnekleri eğitim amaçlıdır. Production ortamında kullanmadan önce:
1. Kendi güvenlik testlerinizi yapın
2. PCI DSS gereksinimlerini karşıladığınızdan emin olun
3. PayTR'nin güncel dokümantasyonunu kontrol edin
