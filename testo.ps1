$headers = @{
    "x-api-key"   = "8r7ngDW81q3qCNFVk59KB4bnazimt6TfpDOF4mB5"
    "Origin"      = "https://traininfo.odakyu-rt.jp"
    "Referer"     = "https://traininfo.odakyu-rt.jp/"
    "User-Agent"  = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/147.0.0.0 Safari/537.36"
    "Accept"      = "application/json, text/plain, */*"
}

# $result = Invoke-RestMethod `
#     -Uri "https://d6oynijiy33tb.cloudfront.net/service/status/1" `
#     -Headers $headers `
#     -Method Get
# $result | ConvertTo-Json -Depth 10

$data = Invoke-RestMethod `
 -Uri "https://d6oynijiy33tb.cloudfront.net/service/status/1" `
 -Headers $headers

if ($data.status.Count -eq 0) {
    Write-Output "小田急線は平常運転です"
}
else {
    Write-Output "運行情報あり"
    $data.status | ConvertTo-Json -Depth 10
}


# ==========================================================
# 小田急線 運行情報 自動追従スクレイパーAPIキー変更対応版
# ==========================================================

$basePage = "https://traininfo.odakyu-rt.jp/"
$apiUrl   = "https://d6oynijiy33tb.cloudfront.net/service/status/1"

# -------------------------------
# メール通知先
# -------------------------------
$MailTo = ""

# ----------------------------------------------------------
# 共通ブラウザヘッダー
# ----------------------------------------------------------
$browserHeaders = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36"
    "Accept"     = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
}

# ----------------------------------------------------------
# 最新JS取得関数
# ----------------------------------------------------------
function Get-LatestJsUrl {
    $html = Invoke-WebRequest `
        -Uri "https://traininfo.odakyu-rt.jp/train_status" `
        -UseBasicParsing `
        -Headers $browserHeaders
    $matches = [regex]::Matches(
        $html.Content,
        'src="([^"]*index-[^"]+\.js)"'
    )

    foreach ($m in $matches) { 

        $path = $m.Groups[1].Value

        if ($path.StartsWith("/")) {
            return $basePage.TrimEnd("/") + $path
        }
        else {
            return $basePage + $path
        }
    }

    throw "最新JSファイルが見つかりません"
}

# ----------------------------------------------------------
# APIキー取得関数
# ----------------------------------------------------------
function Get-OdakyuApiKey {
    try {
        $jsUrl = Get-LatestJsUrl
        $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/147.0 Safari/537.36"

        $js = Invoke-WebRequest `
            -Uri $jsUrl -UseBasicParsing `
            -Headers @{ "User-Agent" = $ua }

        $content = $js.Content

        # x-api-key 周辺検索
        $patterns = @(
            'x-api-key["'': ]+([A-Za-z0-9]+)',
            'x-api-key.{0,100}?([A-Za-z0-9]{20,})',
            'api[_-]?key["'': ]+([A-Za-z0-9]+)'
        )

        foreach ($p in $patterns) {

            $m = [regex]::Match($content, $p)

            if ($m.Success) {
                # Write-Host "API KEY FOUND:", $m.Groups[1].Value
                return $m.Groups[1].Value
            }
        }
    }
    catch {
        Write-Host "JS取得失敗: $jsUrl"
    }

    throw "APIキーが見つかりませんでした"
}

# ----------------------------------------------------------
# 運行情報取得
# ----------------------------------------------------------
function Get-OdakyuTrainStatus {

    $apiKey = Get-OdakyuApiKey
    $headers = @{
        "x-api-key"  = $apiKey
        "Origin"     = "https://traininfo.odakyu-rt.jp"
        "Referer"    = "https://traininfo.odakyu-rt.jp/"
        "User-Agent" = $browserHeaders["User-Agent"]
        "Accept"     = "application/json, text/plain, */*"
    }

    $result = Invoke-RestMethod `
        -Uri $apiUrl `
        -Headers $headers `
        -Method Get

    return $result
}


# ==========================================================
# Outlookメール送信
# ==========================================================
function Send-OutlookMail($subject, $body) {

    $outlook = New-Object -ComObject Outlook.Application
    $mail = $outlook.CreateItem(0)

    $mail.To = $MailTo
    $mail.Subject = $subject
    $mail.Body = $body
    $mail.Send()
}


# ----------------------------------------------------------
# メイン処理
# ----------------------------------------------------------
try {

    $data = Get-OdakyuTrainStatus

    Write-Host "取得時刻: $($data.server_time)"

    if ($data.status.Count -eq 0) {
        Write-Host "小田急線は平常運転です"
    }
    else {
        Write-Host "遅延・障害あり"
        $body = @"
小田急線に運行情報があります。

取得時刻:
$($data.server_time)

内容:
$( $data.status | ConvertTo-Json -Depth 10 )

確認ページ:
https://traininfo.odakyu-rt.jp/
"@

        Send-OutlookMail `
            -subject "【小田急線】運行情報あり" `
            -body $body

        Write-Host "Outlookメール送信完了"
    }
}
catch {
    Write-Host "エラー発生:"
    Write-Host $_
}
