/// Alamat berkas `latest.json` yang diterbitkan bersama setiap rilis (GitHub Releases). Alamat ini tetap,
/// selalu menunjuk rilis terbaru, dan gratis. Dapat diganti saat build: --dart-define=UPDATE_MANIFEST_URL=...
const manifestUrlBawaan =
    'https://github.com/Sadamdi/smart/releases/latest/download/latest.json';

const manifestUrl = String.fromEnvironment(
  'UPDATE_MANIFEST_URL',
  defaultValue: manifestUrlBawaan,
);

/// Pembaruan hanya boleh diunduh lewat HTTPS dari GitHub. Alamat lain ditolak walaupun tercantum di manifest.
bool hostPembaruanDiizinkan(Uri uri) {
  if (uri.scheme != 'https') return false;
  final h = uri.host.toLowerCase();
  return h == 'github.com' ||
      h.endsWith('.github.com') ||
      h.endsWith('.githubusercontent.com');
}
