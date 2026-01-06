import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'MAPBOX_PUBLIC_TOKEN', obfuscate: true)
  static String MAPBOX_PUBLIC_TOKEN = _Env.MAPBOX_PUBLIC_TOKEN;

  @EnviedField(varName: 'MAPBOX_SECRET_TOKEN', obfuscate: true)
  static String MAPBOX_SECRET_TOKEN = _Env.MAPBOX_SECRET_TOKEN;
}
