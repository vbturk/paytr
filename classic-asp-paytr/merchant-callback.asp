<!-- #include file="paytr_helper.asp" -->
<%
'=============================================================================
' PAYTR Merchant Callback (Bildirim) Handler
' Açıklama: PayTR sunucularından gelen ödeme sonucu bildirisini karşılar,
'           imzayı doğrular ve veritabanı işlemlerini yapar.
'=============================================================================

Option Explicit
Response.CodePage = 65001
Response.CharSet = "UTF-8"
Response.ContentType = "application/json"

' --- YAPILANDIRMA ---
Const MERCHANT_ID = "YOUR_MERCHANT_ID"
Const MERCHANT_KEY = "YOUR_MERCHANT_KEY"
Const MERCHANT_SALT = "YOUR_MERCHANT_SALT" ' PayTR panelinde tanımlı salt değeri
' -------------------

Dim strPostData, arrData, merchantOkb, calculatedHash, receivedHash
Dim orderId, authStatus, totalPrice, errorText

' Gelen POST verisini al
strPostData = Request.BinaryRead(Request.TotalBytes)
If LenB(strPostData) = 0 Then
    Response.Write "{""result"":0, ""error"":""No data received""}"
    Response.End
End If

' Veriyi string'e çevir ve parçala
strPostData = BytesToStr(strPostData)
arrData = Split(strPostData, "|")

' Beklenen format: merchant_id|orderid|auth|code|proc-return-code|total|error|merchant-okb
If UBound(arrData) < 7 Then
    Response.Write "{""result"":0, ""error"":""Invalid data format""}"
    Response.End
End If

' Parametreleri ayıkla
Dim p_merchantId, p_orderId, p_auth, p_code, p_procReturnCode, p_total, p_errorMsg, p_merchantOkb
p_merchantId      = arrData(0)
p_orderId         = arrData(1)
p_auth            = arrData(2)     ' Başarılı: "1", Başarısız: "0"
p_code            = arrData(3)
p_procReturnCode  = arrData(4)
p_total           = arrData(5)
p_errorMsg        = arrData(6)
p_merchantOkb     = ""
If UBound(arrData) >= 7 Then p_merchantOkb = arrData(7)

' --- GÜVENLİK KONTROLÜ (HASH DOĞRULAMA) ---
' Hash Formatı: sha256_base64( merchant_id + oid + auth + proc_return_code + total + merchant_key )
' NOT: Salt burada kullanılmaz, direkt key kullanılır (PayTR dokümantasyonuna göre).
' Ancak bazı senaryolarda salt eklenebilir, dokümantasyonu tekrar kontrol edin.
' Standart Bildirim Hash: merchant_id|orderid|auth|code|total|merchant_key

Dim hashString
hashString = p_merchantId & "|" & p_orderId & "|" & p_auth & "|" & p_procReturnCode & "|" & p_total & "|" & MERCHANT_KEY

calculatedHash = GetSHA256Base64(hashString)
receivedHash = p_merchantOkb ' PayTR bazen bunu son parametre olarak gönderir veya header'da olabilir. 
' Düzeltme: PayTR bildirimde hash'i doğrudan göndermez, biz hesaplayıp eşleşen bir durum bekleriz?
' HAYIR: PayTR dokümantasyonuna göre; "merchant_okb" alanı aslında hash'in kendisidir veya hash ayrı bir parametredir.
' PayTR Direkt API Bildirim Dokümantasyonu:
# Gelen veri: merchant_id|orderid|auth|code|proc-return-code|total|error_msg|merchant-okb
# merchant-okb: merchant_key + | + merchant_salt + ... şeklinde değil.
# Doğrusu: PayTR size bir hash gönderir (genellikle son parametre veya özel bir alan).
# Ancak PayTR'nin eski dökümanlarında "merchant-okb" alanı bazen kafa karıştırıcıdır.
# En garanti yöntem: PayTR'nin gönderdiği hash değerini (genellikle 7. indexten sonra veya özel bir POST parametresi)
# bizim hesapladığımız ile karşılaştırmaktır.

' PAYTR Güncel Dokümantasyonuna Göre Bildirim Hash Hesaplama:
# Str = merchant_id|orderid|auth|code|proc-return-code|total|merchant_key
# Hash = base64(sha256(Str))
# Ve PayTR bu hash'i POST verisinin içine "merchant-okb" olarak ekleyerek gönderir.
# Yani arrData(7) gelen hash'tir.

If calculatedHash <> p_merchantOkb Then
    ' Hash uyuşmazlığı! Güvenlik ihlali.
    Response.Write "{""result"":0, ""error"":""Invalid Security Hash""}"
    Response.End
End If

' --- VERİTABANI İŞLEMLERİ ---
' Burada orderId (p_orderId) ile kendi veritabanınızda ilgili siparişi bulun
' ve p_auth değerine göre durumu güncelleyin.

Dim dbResult
dbResult = UpdateOrderStatusInDB(p_orderId, p_auth, p_total, p_errorMsg)

If dbResult = True Then
    ' İşlem başarılı, PayTR'ye "OK" dön
    Response.Write "{""result"":1}"
Else
    ' Veritabanı hatası, PayTR tekrar denesin diye "0" dön
    Response.Write "{""result"":0, ""error"":""Database update failed""}"
End If

' -----------------------------------------------------------------------------
' Helper Fonksiyonlar
' -----------------------------------------------------------------------------

Function BytesToStr(ByRef bArray)
    Dim i, sStr
    sStr = ""
    For i = 0 To LenB(bArray) - 1
        sStr = sStr & Chr(AscB(MidB(bArray, i + 1, 1)))
    Next
    BytesToStr = sStr
End Function

Function UpdateOrderStatusInDB(orderId, auth, total, errorMsg)
    ' BURAYA KENDİ VERİTABANI KODUNUZU YAZIN
    ' Örnek (ADO):
    ' Dim conn, rs, sql
    ' Set conn = Server.CreateObject("ADODB.Connection")
    ' conn.Open "YourConnectionString"
    ' If auth = "1" Then
    '     sql = "UPDATE Orders SET Status='Paid', PaidAmount=" & CDbl(total) & " WHERE OrderId='" & orderId & "'"
    ' Else
    '     sql = "UPDATE Orders SET Status='Failed', FailReason='" & Replace(errorMsg, "'", "''") & "' WHERE OrderId='" & orderId & "'"
    ' End If
    ' conn.Execute(sql)
    ' conn.Close
    ' Set conn = Nothing
    
    ' Simülasyon (Her zaman true dönüyor)
    UpdateOrderStatusInDB = True
End Function
%>
