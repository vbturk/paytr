<%
'=========================================================
' PayTR Direkt API - Classic ASP Entegrasyonu
' 1. Adım: Token Oluşturma
' 2. Adım: Ödeme Formu URL'i ve Iframe Kodu
'=========================================================

Option Explicit
Response.CodePage = 65001
Response.CharSet = "UTF-8"

'---------------------------------------------------------
' AYARLAR - Production ortamında bu değerleri config dosyasından okuyun!
'---------------------------------------------------------
Const MERCHANT_ID = "test_merchant_id"     ' PayTR'den aldığınız Merchant ID
Const MERCHANT_KEY = "test_merchant_key"   ' PayTR'den aldığınız Merchant Key
Const TEST_MODE = True                     ' True: Test ortamı, False: Canlı ortam

'---------------------------------------------------------
' API ENDPOINT'LERİ
'---------------------------------------------------------
Dim API_URL_1_ADIM, API_URL_2_ADIM
If TEST_MODE Then
    API_URL_1_ADIM = "https://test.paytr.com/token"
    API_URL_2_ADIM = "https://test.paytr.com/buyoff/iframe"
Else
    API_URL_1_ADIM = "https://www.paytr.com/token"
    API_URL_2_ADIM = "https://www.paytr.com/buyoff/iframe"
End If

'---------------------------------------------------------
' SHA256 ve Yardımcı Fonksiyonlar (Güvenli .NET CryptoAPI)
'---------------------------------------------------------

Function sha256hashBytes(aBytes)
    Dim sha256
    Set sha256 = CreateObject("System.Security.Cryptography.SHA256Managed")
    sha256.Initialize()
    sha256hashBytes = sha256.ComputeHash_2((aBytes))
End Function

Function stringToUTFBytes(aString)
    Dim UTF8
    Set UTF8 = CreateObject("System.Text.UTF8Encoding")
    stringToUTFBytes = UTF8.GetBytes_4(aString)
End Function

Function bytesToHex(aBytes)
    Dim hexStr, x
    For x = 1 To LenB(aBytes)
        hexStr = Hex(AscB(MidB((aBytes), x, 1)))
        If Len(hexStr) = 1 Then hexStr = "0" & hexStr
        bytesToHex = bytesToHex & hexStr
    Next
End Function

Function BytesToBase64(varBytes)
    With CreateObject("MSXML2.DomDocument").CreateElement("b64")
        .dataType = "bin.base64"
        .nodeTypedValue = varBytes
        BytesToBase64 = .Text
    End With
End Function

' Ana SHA256 Fonksiyonu - String input alır, HEX output verir
Function SHA256(inputString)
    Dim utfBytes, hashBytes
    utfBytes = stringToUTFBytes(inputString)
    hashBytes = sha256hashBytes(utfBytes)
    SHA256 = UCase(bytesToHex(hashBytes))
End Function

' Base64 olarak SHA256 hash üretmek isterseniz:
Function SHA256_Base64(inputString)
    Dim utfBytes, hashBytes
    utfBytes = stringToUTFBytes(inputString)
    hashBytes = sha256hashBytes(utfBytes)
    SHA256_Base64 = BytesToBase64(hashBytes)
End Function

'---------------------------------------------------------
' ÖRNEK SİPARİŞ BİLGİLERİ
' Gerçek uygulamada bu verileri veritabanından veya form'dan alın
'---------------------------------------------------------
Dim orderId, amount, basketInfo, buyerName, buyerEmail, buyerPhone, userIp
Dim successUrl, failUrl, merchantOkUrl, merchantFailUrl
Dim hashAlgorithm, hashVersion, paymentExpireInMinute, installments

orderId = "ORDER-" & Year(Now) & Month(Now) & Day(Now) & Hour(Now) & Minute(Now) & Second(Now)
amount = 10000  ' Kuruş cinsinden (100.00 TL = 10000)
basketInfo = "Ürün 1,Ürün 2,Ürün 3"
buyerName = "Ahmet Yılmaz"
buyerEmail = "ahmet@example.com"
buyerPhone = "5551234567"
userIp = Request.ServerVariables("REMOTE_ADDR")
If userIp = "" Then userIp = "127.0.0.1"

successUrl = "https://siteniz.com/payment-success.asp"
failUrl = "https://siteniz.com/payment-fail.asp"
merchantOkUrl = "https://siteniz.com/merchant-success.asp"
merchantFailUrl = "https://siteniz.com/merchant-fail.asp"

hashAlgorithm = "SHA256"
hashVersion = "v1"
paymentExpireInMinute = 30
installments = "0"  ' 0 = taksit yok, diğer değerler taksit sayısı

'---------------------------------------------------------
' 1. ADIM: TOKEN OLUŞTURMA
'---------------------------------------------------------
Function CreatePayTrToken()
    Dim postData, xmlHttp, responseText, tokenResult
    
    ' Hash oluşturma: SHA256(MerchantID + orderId + amount + successUrl + failUrl + basketInfo + buyerName + buyerEmail + buyerPhone + userIp + MerchantKey)
    Dim hashString, hashValue
    hashString = MERCHANT_ID & orderId & CStr(amount) & successUrl & failUrl & basketInfo & buyerName & buyerEmail & buyerPhone & userIp & MERCHANT_KEY
    hashValue = SHA256(hashString)
    
    ' JSON POST verisi hazırlama
    postData = "{"
    postData = postData & """merchantId"":""" & MERCHANT_ID & ""","
    postData = postData & """merchantKey"":""" & MERCHANT_KEY & ""","
    postData = postData & """merchantSalt"":""" & MERCHANT_KEY & ""","
    postData = postData & """"email"":""" & buyerEmail & ""","
    postData = postData & """"paymentAmount"":""" & CStr(amount) & ""","
    postData = postData & """"paymentSalt"":""" & GenerateRandomSalt() & ""","
    postData = postData & """"buyerName"":""" & EscapeJson(buyerName) & ""","
    postData = postData & """"buyerSurname"":"""",
    postData = postData & """"buyerPhone"":""" & buyerPhone & ""","
    postData = postData & """"buyerAddress"":"""",
    postData = postData & """"buyerCity"":"""",
    postData = postData & """"buyerZip"":"""",
    postData = postData & """"orderNo"":""" & orderId & ""","
    postData = postData & """"shopName"":""" & EscapeJson("Mağaza Adı") & ""","
    postData = postData & """"shopUrl"":""" & "https://siteniz.com" & ""","
    postData = postData & """"shopCategory"":""" & "Genel" & ""","
    postData = postData & """"shopStock"":""" & "var" & ""","
    postData = postData & """"basket"":["
    
    ' Basket bilgilerini ekleme (basitleştirilmiş)
    Dim basketItems
    basketItems = Split(basketInfo, ",")
    Dim i
    For i = 0 To UBound(basketItems)
        If i > 0 Then postData = postData & ","
        postData = postData & "{"
        postData = postData & """"name"":""" & EscapeJson(Trim(basketItems(i))) & ""","
        postData = postData & """"category"":""" & "Genel" & ""","
        postData = postData & """"quantity"":1,"
        postData = postData & """"price"":""" & CStr(amount \ (UBound(basketItems) + 1)) & """"
        postData = postData & "}"
    Next
    
    postData = postData & "],"
    postData = postData & """"buyerIp"":""" & userIp & ""","
    postData = postData & """"merchantOrderId"":""" & orderId & ""","
    postData = postData & """"merchantCallbackUrl"":""" & merchantOkUrl & ""","
    postData = postData & """"merchantFailedUrl"":""" & merchantFailUrl & ""","
    postData = postData & """"token_expire_in_minute"":""" & CStr(paymentExpireInMinute) & ""","
    postData = postData & """"hashAlgorithm"":""" & hashAlgorithm & ""","
    postData = postData & """"hashVersion"":""" & hashVersion & ""","
    postData = postData & """"hash"":""" & hashValue & """"
    postData = postData & "}"
    
    ' HTTP POST isteği gönderme
    Set xmlHttp = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")
    xmlHttp.Open "POST", API_URL_1_ADIM, False
    xmlHttp.setRequestHeader "Content-Type", "application/json"
    xmlHttp.setRequestHeader "Accept", "application/json"
    xmlHttp.send postData
    
    responseText = xmlHttp.responseText
    Set xmlHttp = Nothing
    
    ' Response'u parse etme (basit JSON parsing)
    If InStr(responseText, """status"":""success""") > 0 Then
        tokenResult = ExtractJsonValue(responseText, "token")
        CreatePayTrToken = tokenResult
    Else
        CreatePayTrToken = ""
        Response.Write "<div style='color:red; padding:10px; border:1px solid red; margin:10px;'>Token oluşturma hatası: " & responseText & "</div>"
    End If
End Function

'---------------------------------------------------------
' 2. ADIM: ÖDEME FORMU URL'İ VE IFRAME KODU
'---------------------------------------------------------
Function GetPaymentIframeUrl(token)
    Dim postData, xmlHttp, responseText, iframeUrl
    
    ' Hash oluşturma: SHA256(token + MerchantKey)
    Dim hashString, hashValue
    hashString = token & MERCHANT_KEY
    hashValue = SHA256(hashString)
    
    ' JSON POST verisi hazırlama
    postData = "{"
    postData = postData & """token"":""" & token & ""","
    postData = postData & """"hash"":""" & hashValue & ""","
    postData = postData & """"hashAlgorithm"":""" & hashAlgorithm & ""","
    postData = postData & """"hashVersion"":""" & hashVersion & ""","
    postData = postData & """"nojs"":false"
    postData = postData & "}"
    
    ' HTTP POST isteği gönderme
    Set xmlHttp = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")
    xmlHttp.Open "POST", API_URL_2_ADIM, False
    xmlHttp.setRequestHeader "Content-Type", "application/json"
    xmlHttp.setRequestHeader "Accept", "application/json"
    xmlHttp.send postData
    
    responseText = xmlHttp.responseText
    Set xmlHttp = Nothing
    
    ' Response'u parse etme
    If InStr(responseText, """status"":""success""") > 0 Then
        iframeUrl = ExtractJsonValue(responseText, "url")
        GetPaymentIframeUrl = iframeUrl
    Else
        GetPaymentIframeUrl = ""
        Response.Write "<div style='color:red; padding:10px; border:1px solid red; margin:10px;'>Ödeme URL oluşturma hatası: " & responseText & "</div>"
    End If
End Function

'---------------------------------------------------------
' YARDIMCI FONKSİYONLAR
'---------------------------------------------------------

' Rastgele salt oluşturma
Function GenerateRandomSalt()
    Randomize
    GenerateRandomSalt = CStr(Int(Rnd * 999999) + 100000)
End Function

' JSON string escape
Function EscapeJson(str)
    str = Replace(str, "\", "\\")
    str = Replace(str, """", "\""")
    str = Replace(str, vbCrLf, "\n")
    str = Replace(str, vbCr, "\r")
    str = Replace(str, vbTab, "\t")
    EscapeJson = str
End Function

' JSON'dan değer çıkarma (basit parser)
Function ExtractJsonValue(jsonString, keyName)
    Dim startPos, endPos, valueStart, valueEnd, char, inString, escapeNext
    Dim searchKey, result
    
    searchKey = """" & keyName & """:"
    startPos = InStr(jsonString, searchKey)
    
    If startPos = 0 Then
        ExtractJsonValue = ""
        Exit Function
    End If
    
    valueStart = startPos + Len(searchKey)
    
    ' Boşlukları atla
    Do While Mid(jsonString, valueStart, 1) = " " Or Mid(jsonString, valueStart, 1) = vbTab
        valueStart = valueStart + 1
    Loop
    
    char = Mid(jsonString, valueStart, 1)
    
    If char = """" Then
        ' String değeri
        valueStart = valueStart + 1
        result = ""
        escapeNext = False
        
        For valueEnd = valueStart To Len(jsonString)
            char = Mid(jsonString, valueEnd, 1)
            
            If escapeNext Then
                result = result & char
                escapeNext = False
            ElseIf char = "\" Then
                escapeNext = True
            ElseIf char = """" Then
                Exit For
            Else
                result = result & char
            End If
        Next
        
        ExtractJsonValue = result
    Else
        ' Numeric veya boolean değeri
        result = ""
        For valueEnd = valueStart To Len(jsonString)
            char = Mid(jsonString, valueEnd, 1)
            If char = "," Or char = "}" Or char = "]" Then Exit For
            result = result & char
        Next
        
        ExtractJsonValue = result
    End If
End Function

'---------------------------------------------------------
' ANA İŞLEM AKIŞI
'------------------------------------------------=========
Dim token, paymentUrl

Response.Write "<html><head><meta charset='UTF-8'><title>PayTR Ödeme</title>"
Response.Write "<style>body{font-family:Arial,sans-serif;margin:20px;} .box{border:1px solid #ddd;padding:20px;margin:10px 0;border-radius:5px;} .success{background:#d4edda;border-color:#c3e6cb;} .info{background:#d1ecf1;border-color:#bee5eb;}</style>"
Response.Write "</head><body>"

Response.Write "<h1>PayTR Direkt API - Classic ASP Örneği</h1>"

' Sipariş bilgilerini göster
Response.Write "<div class='box info'>"
Response.Write "<h3>Sipariş Bilgileri:</h3>"
Response.Write "<p><strong>Sipariş No:</strong> " & orderId & "</p>"
Response.Write "<p><strong>Tutar:</strong> " & FormatCurrency(amount / 100, 2) & " TL</p>"
Response.Write "<p><strong>Müşteri:</strong> " & buyerName & "</p>"
Response.Write "<p><strong>Email:</strong> " & buyerEmail & "</p>"
Response.Write "<p><strong>Telefon:</strong> " & buyerPhone & "</p>"
Response.Write "</div>"

' 1. ADIM: Token oluştur
Response.Write "<div class='box'>"
Response.Write "<h3>1. Adım: Token Oluşturma</h3>"
token = CreatePayTrToken()

If token <> "" Then
    Response.Write "<p style='color:green;'><strong>✓ Token Başarıyla Oluşturuldu:</strong></p>"
    Response.Write "<p style='background:#f8f9fa;padding:10px;border:1px solid #ddd;word-break:break-all;'><code>" & token & "</code></p>"
    
    ' 2. ADIM: Ödeme URL'i al
    Response.Write "</div><div class='box'>"
    Response.Write "<h3>2. Adım: Ödeme Formu URL'i</h3>"
    paymentUrl = GetPaymentIframeUrl(token)
    
    If paymentUrl <> "" Then
        Response.Write "<p style='color:green;'><strong>✓ Ödeme URL'i Başarıyla Oluşturuldu:</strong></p>"
        Response.Write "<p style='background:#f8f9fa;padding:10px;border:1px solid #ddd;word-break:break-all;'><code>" & paymentUrl & "</code></p>"
        
        ' Iframe ile ödeme formunu göster
        Response.Write "<h3>Ödeme Formu (Iframe):</h3>"
        Response.Write "<iframe src='" & paymentUrl & "' style='width:100%;height:600px;border:1px solid #ddd;border-radius:5px;' frameborder='0'></iframe>"
        
        ' Alternatif: Yeni pencerede açma linki
        Response.Write "<p style='margin-top:20px;'><a href='" & paymentUrl & "' target='_blank' style='display:inline-block;padding:10px 20px;background:#007bff;color:white;text-decoration:none;border-radius:5px;'>Ödemeyi Yeni Pencerede Aç</a></p>"
    Else
        Response.Write "<p style='color:red;'><strong>✗ Ödeme URL'i oluşturulamadı!</strong></p>"
    End If
Else
    Response.Write "<p style='color:red;'><strong>✗ Token oluşturulamadı!</strong></p>"
End If

Response.Write "</div>"
Response.Write "</body></html>"
%>
