#!/usr/bin/zsh

test-dotnet() {
    PASSWORD_TESTER="W&H3Ms65u8n%v" 
    MDC_E2E_INSTANCE=dev.dev 
    dotnet test --logger "html;logfilename=testResults.html" --filter Category="$1"
}