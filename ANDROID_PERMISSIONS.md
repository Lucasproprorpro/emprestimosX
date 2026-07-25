# Permissões Android (mesclar após `flutter create .`)

Depois de gerar a pasta `android/` (veja o README), abra o arquivo
`android/app/src/main/AndroidManifest.xml` e adicione as permissões abaixo
**logo acima** da tag `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

Essas permissões cobrem:

- **INTERNET** — futura sincronização com Firebase.
- **CAMERA** — foto do cliente / fachada do comércio (`image_picker`).
- **ACCESS_FINE/COARSE_LOCATION** — captura de GPS do cliente (`geolocator`).
- **READ_EXTERNAL_STORAGE** — seleção do arquivo de backup (`file_picker`).

## minSdkVersion

O `image_picker`, `geolocator` e `file_picker` exigem `minSdkVersion` **21** ou
superior. O padrão do Flutter já atende, mas confirme em
`android/app/build.gradle`:

```gradle
defaultConfig {
    minSdkVersion 21
    targetSdkVersion flutter.targetSdkVersion
}
```
