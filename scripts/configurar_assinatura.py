"""
Injeta a leitura do key.properties e a signingConfig de release no
android/app/build.gradle gerado automaticamente pelo `flutter create`
no CI. Isso garante que TODAS as builds usem a mesma assinatura,
permitindo atualizar o APK no celular sem precisar desinstalar
(o Android recusa updates cuja assinatura mudou).

Roda apenas dentro do GitHub Actions, depois de `flutter create`.
"""

import pathlib
import re
import sys

BUILD_GRADLE = pathlib.Path("android/app/build.gradle")

KEYSTORE_PROPERTIES_BLOCK = """
def keystorePropertiesFile = rootProject.file('key.properties')
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
"""

SIGNING_CONFIGS_BLOCK = """
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
"""

# Casa tanto "signingConfig signingConfigs.debug" (sintaxe antiga do Groovy)
# quanto "signingConfig = signingConfigs.debug" (sintaxe nova, com "=",
# usada pelos templates mais recentes do Flutter). É essa variação que
# causava o bug: o script antigo só reconhecia a forma sem "=", então
# inseria uma linha NOVA em vez de substituir a original — e a original
# (por vir depois) sempre vencia, mantendo a assinatura de debug.
PADRAO_SIGNING_DEBUG = re.compile(r"signingConfig\s*=?\s*signingConfigs\.debug")


def main() -> None:
    if not BUILD_GRADLE.exists():
        print(f"ERRO: {BUILD_GRADLE} não encontrado.", file=sys.stderr)
        sys.exit(1)

    conteudo = BUILD_GRADLE.read_text(encoding="utf-8")

    if "keystoreProperties" in conteudo:
        print("Assinatura já configurada, nada a fazer.")
        return

    # 1) Insere o carregamento do key.properties logo antes de `android {`
    marcador_android = "\nandroid {"
    if marcador_android not in conteudo:
        print("ERRO: não encontrei o bloco `android {` no build.gradle.", file=sys.stderr)
        sys.exit(1)

    conteudo = conteudo.replace(
        marcador_android,
        KEYSTORE_PROPERTIES_BLOCK + marcador_android,
        1,
    )

    # 2) Insere o signingConfigs logo após a abertura do bloco `android {`
    conteudo = conteudo.replace(
        "android {",
        "android {" + SIGNING_CONFIGS_BLOCK,
        1,
    )

    # 3) SUBSTITUI (nunca duplica) a linha que aponta para a debug key,
    # seja qual for a sintaxe usada pelo template do Flutter.
    conteudo, quantidade = PADRAO_SIGNING_DEBUG.subn(
        "signingConfig = signingConfigs.release",
        conteudo,
        count=1,
    )

    if quantidade == 0:
        print(
            "ERRO: não encontrei a linha 'signingConfig ... signingConfigs.debug' "
            "para substituir. O template do build.gradle mudou de novo — "
            "avise para ajustar o script.",
            file=sys.stderr,
        )
        sys.exit(1)

    BUILD_GRADLE.write_text(conteudo, encoding="utf-8")
    print("Assinatura de release configurada com sucesso em build.gradle.")


if __name__ == "__main__":
    main()
