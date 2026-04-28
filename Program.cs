using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace PayTrIntegration
{
    /// <summary>
    /// Kullanım Örneği - Program.cs
    /// Bu dosyayı .NET projenizde Program.cs olarak kullanabilirsiniz
    /// </summary>
    class Program
    {
        static async Task Main(string[] args)
        {
            Console.WriteLine("=== PayTR Direkt API Entegrasyon Örneği ===\n");

            // PayTR Mağaza Bilgilerinizi Buraya Girin
            // NOT: Gerçek projelerinizde bu bilgileri appsettings.json veya environment variables'dan okuyun!
            string merchantId = "YOUR_MERCHANT_ID";      // PayTR panelinden aldığınız Merchant ID
            string merchantKey = "YOUR_MERCHANT_KEY";    // PayTR panelinden aldığınız Merchant Key

            // PayTR servisini başlat (test modu)
            var payTrService = new PayTrService(merchantId, merchantKey, useTestEnvironment: true);

            try
            {
                // Ödeme isteği oluştur
                var paymentRequest = new PaymentRequest
                {
                    OrderId = "ORDER-" + DateTime.Now.ToString("yyyyMMddHHmmss"), // Sipariş numarası
                    Amount = 100.50m,                                              // Ödeme tutarı (TL)
                    BuyerName = "Ahmet Yılmaz",                                    // Müşteri adı
                    BuyerEmail = "ahmet.yilmaz@email.com",                         // Müşteri e-posta
                    UserIp = "192.168.1.100",                                      // Müşteri IP adresi
                    
                    // Opsiyonel ayarlar
                    DebugMode = true,           // Test modunda detaylı hata mesajları
                    NoInstallment = false,      // Taksit yapılabilir
                    TimeoutLimit = 30,          // 30 dakika zaman aşımı
                    Currency = "TRY",           // Para birimi
                    TestMode = true,            // Test modu
                    Language = "tr",            // Dil
                    
                    // Ürün bilgileri (opsiyonel)
                    Products = new List<Product>
                    {
                        new Product { Name = "Ürün 1", Price = 50.25m, Quantity = 1 },
                        new Product { Name = "Ürün 2", Price = 50.25m, Quantity = 1 }
                    }
                };

                Console.WriteLine("1. ADIM: Token alınıyor...");
                Console.WriteLine($"Sipariş No: {paymentRequest.OrderId}");
                Console.WriteLine($"Tutar: {paymentRequest.Amount} TL");
                Console.WriteLine($"Müşteri: {paymentRequest.BuyerName}");
                Console.WriteLine();

                // 1. ADIM: Token al
                var tokenResponse = await payTrService.GetPaymentTokenAsync(paymentRequest);

                Console.WriteLine("✓ Token başarıyla alındı!");
                Console.WriteLine($"Token: {tokenResponse.Token}");
                Console.WriteLine($"Merchant OID: {tokenResponse.MerchantOid}");
                Console.WriteLine();

                // 2. ADIM: Ödeme formu URL'ini oluştur
                Console.WriteLine("2. ADIM: Ödeme formu URL'i oluşturuluyor...");
                var paymentFormUrl = payTrService.GetPaymentFormUrl(tokenResponse.Token);

                Console.WriteLine();
                Console.WriteLine("===========================================");
                Console.WriteLine("ÖDEME SAYFASI URL'si:");
                Console.WriteLine(paymentFormUrl);
                Console.WriteLine("===========================================");
                Console.WriteLine();
                Console.WriteLine("Bu URL'yi müşterinizin tarayıcısında açarak ödeme yapmasını sağlayabilirsiniz.");
                Console.WriteLine();
                Console.WriteLine("NOT: Gerçek uygulamada bu URL'e yönlendirme işlemi yapılır:");
                Console.WriteLine("   return Redirect(paymentFormUrl);  // ASP.NET MVC örneği");
            }
            catch (Exception ex)
            {
                Console.WriteLine();
                Console.WriteLine("HATA OLUŞTU!");
                Console.WriteLine($"Hata Mesajı: {ex.Message}");
                
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"İç Hata: {ex.InnerException.Message}");
                }
            }

            Console.WriteLine();
            Console.WriteLine("Program sonlandırıldı. Devam etmek için bir tuşa basın...");
            Console.ReadKey();
        }
    }
}
