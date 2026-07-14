"""
Injeta a leitura do key.properties e a signingConfig de release no
android/app/build.gradle gerado automaticamente pelo `flutter create`
no CI. Isso garante que TODAS as builds usem a mesma assinatura,
permitindo atualizar o APK no celular sem precisar desinstalar
(o Android recusa updates cuja assinatura mudou).

Roda apenas dentro do GitHub Actions, depois de `flutter create`.
"""

import pathlib
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

    # 3) Aponta o buildType de release para a signingConfig de release
    if "signingConfig signingConfigs.debug" in conteudo:
        conteudo = conteudo.replace(
            "signingConfig signingConfigs.debug",
            "signingConfig signingConfigs.release",
        )
    else:
        # Fallback: garante que exista uma signingConfig explícita mesmo
        # que o template padrão não tenha a linha esperada.
        conteudo = conteudo.replace(
            "buildTypes {\n        release {",
            "buildTypes {\n        release {\n            signingConfig signingConfigs.release",
            1,
        )

    BUILD_GRADLE.write_text(conteudo, encoding="utf-8")
    print("Assinatura de release configurada com sucesso em build.gradle.")


if __name__ == "__main__":
    main()
