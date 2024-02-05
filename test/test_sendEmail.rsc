:global sendEmail

$sendEmail body=("test") subj="test" isDebug=true


$sendEmail body=("test") subj="tes tls=yes" isDebug=true pTLS=yes pPORT=465
$sendEmail body=("test") subj="tes tls=starttls" isDebug=true pTLS=starttls pPORT=465
