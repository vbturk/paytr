using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace PayTrIntegration
{
    /// <summary>
    /// PayTR Direkt API Entegrasyonu - 1. Adım ve 2. Adım
    /// </summary>
    public class PayTrService
    {
        private readonly string _merchantId;
        private readonly string _merchantKey;
        private readonly string _baseUrl;
        private readonly HttpClient _httpClient;

        public PayTrService(string merchantId, string merchantKey, bool useTestEnvironment = true)
        {
            _merchantId = merchantId;
            _merchantKey = merchantKey;
            _baseUrl = useTestEnvironment 
                ? "https://test.paytr.com" 
                : "https://www.paytr.com";
            _httpClient = new HttpClient();
        }

        /// <summary>
        /// 1. ADIM: Token Oluşturma
        /// PayTR API'den ödeme token'ı alır
        /// </summary>
        public async Task<PayTrTokenResponse> GetPaymentTokenAsync(PaymentRequest request)
        {
            // Token oluşturmak için gerekli verileri hazırla
            var tokenData = CreateTokenData(request);
            
            // Hash oluştur
            var hash = GenerateHash(tokenData.no, _merchantId, tokenData.price, 
                request.BuyerName, request.BuyerEmail, tokenData.userIp);

            // API isteği için payload oluştur
            var payload = new Dictionary<string, string>
            {
                ["merchant_id"] = _merchantId,
                ["user_ip"] = tokenData.userIp,
                ["merchant_oid"] = tokenData.no,
                ["user_name"] = request.BuyerName,
                ["user_email"] = request.BuyerEmail,
                ["payment_amount"] = tokenData.price,
                ["paytr_token"] = hash,
                ["debug_on"] = request.DebugMode ? "1" : "0",
                ["no_installment"] = request.NoInstallment ? "1" : "0",
                ["timeout_limit"] = request.TimeoutLimit.ToString(),
                ["currency"] = request.Currency,
                ["test_mode"] = request.TestMode ? "1" : "0",
                ["lang"] = request.Language ?? "tr"
            };

            // Ürün bilgileri varsa ekle
            if (request.Products != null && request.Products.Count > 0)
            {
                payload["basket"] = JsonSerializer.Serialize(request.Products);
            }

            // API'ye istek gönder
            var content = new FormUrlEncodedContent(payload);
            var response = await _httpClient.PostAsync($"{_baseUrl}/payment", content);
            var responseString = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"PayTR API Hatası: {response.StatusCode} - {responseString}");
            }

            // Yanıtı parse et
            var result = JsonSerializer.Deserialize<PayTrTokenResponse>(responseString, 
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (result == null || result.Status != "success")
            {
                throw new Exception($"Token oluşturma başarısız: {result?.Reason ?? "Bilinmeyen hata"}");
            }

            return result;
        }

        /// <summary>
        /// 2. ADIM: Ödeme Formu URL'i Oluşturma
        /// Müşteriyi yönlendireceğiniz 3D Secure ödeme sayfasının URL'ini döner
        /// </summary>
        public string GetPaymentFormUrl(string token)
        {
            return $"{_baseUrl}/form/{token}";
        }

        /// <summary>
        /// Hash değeri oluşturur (SHA256 + Base64)
        /// </summary>
        private string GenerateHash(string merchantOid, string merchantId, string price, 
            string buyerName, string buyerEmail, string userIp)
        {
            // Hash formatı: merchant_oid + merchant_id + price + buyer_name + buyer_email + user_ip + merchant_key
            var hashData = $"{merchantOid}{_merchantId}{price}{buyerName}{buyerEmail}{userIp}{_merchantKey}";
            
            using var sha256 = SHA256.Create();
            var hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(hashData));
            
            return Convert.ToBase64String(hashBytes);
        }

        /// <summary>
        /// Token verilerini oluşturur
        /// </summary>
        private TokenData CreateTokenData(PaymentRequest request)
        {
            return new TokenData
            {
                no = request.OrderId ?? Guid.NewGuid().ToString("N")[..20],
                price = request.Amount.ToString("F2").Replace(",", "."),
                userIp = request.UserIp
            };
        }
    }

    /// <summary>
    /// Ödeme İsteği Modeli
    /// </summary>
    public class PaymentRequest
    {
        /// <summary>
        /// Sipariş Numarası (Opsiyonel, boşsa otomatik oluşturulur)
        /// </summary>
        public string OrderId { get; set; }

        /// <summary>
        /// Ödeme Tutarı (TL cinsinden)
        /// </summary>
        public decimal Amount { get; set; }

        /// <summary>
        /// Alıcı Adı Soyadı
        /// </summary>
        public string BuyerName { get; set; }

        /// <summary>
        /// Alıcı E-posta Adresi
        /// </summary>
        public string BuyerEmail { get; set; }

        /// <summary>
        /// Kullanıcı IP Adresi
        /// </summary>
        public string UserIp { get; set; }

        /// <summary>
        /// Debug Modu (true: test modunda detaylı hata mesajları)
        /// </summary>
        public bool DebugMode { get; set; } = false;

        /// <summary>
        /// Taksit Yapılmasın (true: taksit yok)
        /// </summary>
        public bool NoInstallment { get; set; } = false;

        /// <summary>
        /// Zaman Aşımı Süresi (dakika)
        /// </summary>
        public int TimeoutLimit { get; set; } = 30;

        /// <summary>
        /// Para Birimi (varsayılan: TRY)
        /// </summary>
        public string Currency { get; set; } = "TRY";

        /// <summary>
        /// Test Modu
        /// </summary>
        public bool TestMode { get; set; } = true;

        /// <summary>
        /// Dil (tr/en)
        /// </summary>
        public string Language { get; set; } = "tr";

        /// <summary>
        /// Ürün Listesi (Opsiyonel)
        /// </summary>
        public List<Product> Products { get; set; }
    }

    /// <summary>
    /// Ürün Modeli
    /// </summary>
    public class Product
    {
        public string Name { get; set; }
        public decimal Price { get; set; }
        public int Quantity { get; set; }
    }

    /// <summary>
    /// Token Yanıt Modeli
    /// </summary>
    public class PayTrTokenResponse
    {
        public string Status { get; set; }
        public string Reason { get; set; }
        public string MerchantOid { get; set; }
        public string Token { get; set; }
        public int ErrorNo { get; set; }
    }

    /// <summary>
    /// Internal Token Data
    /// </summary>
    internal class TokenData
    {
        public string no { get; set; }
        public string price { get; set; }
        public string userIp { get; set; }
    }
}
