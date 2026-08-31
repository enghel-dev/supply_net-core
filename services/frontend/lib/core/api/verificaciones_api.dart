import 'api_client.dart';

class VerificacionesApi {
  VerificacionesApi(this._client);
  final ApiClient _client;

  /// RF-07 (could-have): solo registra la solicitud de revisión con el tipo
  /// de documento declarado — la subida real del archivo todavía no existe
  /// en el backend (ver TODO en `verificaciones/router.py`), así que la
  /// pantalla de verificación se muestra como "próximamente".
  Future<void> solicitar(String tipoDocumento) => _client.dio.post('/verificaciones', data: {
        'tipo_documento': tipoDocumento,
      });
}
