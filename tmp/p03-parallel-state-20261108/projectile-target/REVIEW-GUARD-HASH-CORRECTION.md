# guard 심사 runner SHA 정정

REVIEW-GUARD-REVISION.md의 runner SHA 표기는 끝에 `2`가 하나 더 붙은 65자리 오기다. SHA256의 정확한 64자리 값은 `fba74d68ee04ee73427ca72c01b8145e4859467dd2b17daa2e3e250cb9d11d22`이다. GUARD-REVISION-PROPOSAL.md에 적힌 runner SHA와 현재 `projectile_target.gd`에 대해 별도 계산한 SHA가 이 값으로 일치하고 attempt-03 manifest의 runner 항목도 일치한다. 제안 문서 자체 SHA `425c835c6acfc99a61d5f6a8ea9b87f5d991c3ca2306a90014b4fb75ded3f1c9`은 정확하다.

이 정정은 이전 심사 기록을 보존하고 그 오기를 명시하는 것이다. attempt-02의 정식 제외와 attempt-03의 별도 5b 조건은 변하지 않는다.
