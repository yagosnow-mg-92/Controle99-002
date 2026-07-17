"""
Injeta as permissões necessárias para rastreamento de GPS em segundo
plano (feature "Corrida") no android/app/src/main/AndroidManifest.xml
gerado automaticamente pelo `flutter create` no CI.

Roda apenas dentro do GitHub Actions, logo depois de `flutter create` e
antes de `configurar_assinatura.py`.
"""

import pathlib
import re
import sys

MANIFEST = pathlib.Path("android/app/src/main/AndroidManifest.xml")

PERMISSOES = """    <!-- Permissões para rastreamento de GPS da funcionalidade "Corrida" -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
"""


def main() -> None:
    if not MANIFEST.exists():
        print(f"ERRO: {MANIFEST} não encontrado.", file=sys.stderr)
        sys.exit(1)

    conteudo = MANIFEST.read_text(encoding="utf-8")

    if "ACCESS_BACKGROUND_LOCATION" in conteudo:
        print("Permissões já configuradas, nada a fazer.")
        return

    # Insere o bloco de permissões logo depois da linha de abertura
    # `<manifest ...>`, antes de `<application`.
    padrao_manifest = re.compile(r"(<manifest[^>]*>\n)")
    match = padrao_manifest.search(conteudo)

    if not match:
        print("ERRO: não encontrei a tag <manifest> no AndroidManifest.xml.", file=sys.stderr)
        sys.exit(1)

    conteudo = conteudo[: match.end()] + PERMISSOES + conteudo[match.end():]

    MANIFEST.write_text(conteudo, encoding="utf-8")
    print("Permissões de GPS/serviço em primeiro plano configuradas com sucesso.")


if __name__ == "__main__":
    main()
