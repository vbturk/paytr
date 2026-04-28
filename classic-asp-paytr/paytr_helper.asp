'=============================================================================
' PAYTR Helper Functions (Classic ASP)
' Açıklama: .NET System.Security.Cryptography kütüphanelerini kullanarak
'           güvenli SHA256 hash işlemleri yapar. CAPICOM bağımlılığını ortadan kaldırır.
'=============================================================================

Option Explicit

' String veriyi UTF-8 byte dizisine çevirir
Function StringToUTFBytes(strInput)
    Dim objUTF8
    Set objUTF8 = CreateObject("System.Text.UTF8Encoding")
    StringToUTFBytes = objUTF8.GetBytes_4(strInput)
End Function

' Byte dizisini Base64 string'e çevirir
Function BytesToBase64(arrBytes)
    Dim objXML
    Set objXML = CreateObject("MSXML2.DomDocument").CreateElement("b64")
    objXML.dataType = "bin.base64"
    objXML.nodeTypedValue = arrBytes
    BytesToBase64 = objXML.Text
End Function

' SHA256 Hash hesaplar ve Base64 olarak döner (PayTR için ana fonksiyon)
Function GetSHA256Base64(strInput)
    Dim objSHA256, arrHashBytes
    Set objSHA256 = CreateObject("System.Security.Cryptography.SHA256Managed")
    objSHA256.Initialize()
    
    ' Hash'i hesapla
    arrHashBytes = objSHA256.ComputeHash_2((StringToUTFBytes(strInput)))
    
    ' Base64'e çevir
    GetSHA256Base64 = BytesToBase64(arrHashBytes)
    
    Set objSHA256 = Nothing
End Function

' İsteğe bağlı: SHA256 Hash'i HEX formatında döner (Debug için)
Function GetSHA256Hex(strInput)
    Dim objSHA256, arrHashBytes, x, strHex
    Set objSHA256 = CreateObject("System.Security.Cryptography.SHA256Managed")
    objSHA256.Initialize()
    
    arrHashBytes = objSHA256.ComputeHash_2((StringToUTFBytes(strInput)))
    
    strHex = ""
    For x = 1 To LenB(arrHashBytes)
        strHex = strHex & Right("0" & Hex(AscB(MidB(arrHashBytes, x, 1))), 2)
    Next
    
    GetSHA256Hex = UCase(strHex)
    Set objSHA256 = Nothing
End Function

' HMAC-SHA256 hesaplar (Gerekirse kullanılabilir)
Function GetHMACSHA256Base64(strInput, strKey)
    Dim objHMAC, arrKeyBytes, arrHashBytes
    Set objHMAC = CreateObject("System.Security.Cryptography.HMACSHA256")
    
    arrKeyBytes = StringToUTFBytes(strKey)
    objHMAC.Key = arrKeyBytes
    objHMAC.Initialize()
    
    arrHashBytes = objHMAC.ComputeHash_2((StringToUTFBytes(strInput)))
    
    GetHMACSHA256Base64 = BytesToBase64(arrHashBytes)
    
    Set objHMAC = Nothing
End Function
