# Gastos Compartidos · Flutter

> **English:** A local-first expense-sharing app for group trips. It preserves original currencies, tracks balances in integer cents and suggests settlement payments. Android is the initial distribution target.

[![Flutter quality](https://github.com/luchonicolini/Gastos-Compartidos-Flutter/actions/workflows/flutter.yml/badge.svg?branch=main)](https://github.com/luchonicolini/Gastos-Compartidos-Flutter/actions/workflows/flutter.yml)

Durante un viaje compartido, los gastos pueden tener varias monedas, pagadores y formas de división.
La app conserva cada aporte, convierte a la moneda de referencia del grupo y muestra quién debe pagarle a quién, con datos guardados en el dispositivo.

**Estado:** en desarrollo, con Android como objetivo inicial. Adaptación de [la versión nativa iOS](https://github.com/luchonicolini/Gastos-Compartidos).
La existencia de carpetas iOS, web y desktop no implica validación funcional en todas esas plataformas.

## Vista previa

[COMPLETAR: capturas de grupos, carga multidivisa y liquidaciones de la versión Flutter]

## Funcionalidades

- Grupos e integrantes con archivado y reactivación para preservar el historial.
- Gastos con uno o varios pagadores; edición, eliminación y fecha de consumo.
- División equitativa, por monto, porcentaje o partes.
- Moneda de referencia por grupo; importes originales, tasa aplicada e importe convertido por gasto.
- Dinero representado en centavos y reparto determinista de diferencias de redondeo.
- Balances, sugerencias de liquidación y registro o eliminación de pagos.
- Respaldo manual en JSON y restauración con confirmación.
- Onboarding y preferencias locales.

La primera versión funciona sin cuenta, backend, sincronización ni anuncios.
Las tasas se registran con cada gasto; no hay cotizaciones automáticas.
La interfaz actual usa tema claro; el modo oscuro queda pendiente.

## Stack y decisiones técnicas

| Área | Implementación |
| --- | --- |
| Framework | Flutter y Dart; SDK Dart requerido: `^3.12.0` |
| Persistencia | Drift sobre SQLite y repositorios |
| Dinero | Value object `Money` en centavos; moneda original y de referencia separadas |
| Reglas de negocio | Calculadores y validadores independientes de los widgets |
| Preferencias | shared_preferences |
| Interfaz | Módulos por funcionalidad; Figtree incluida con licencia SIL OFL |
| Pruebas | flutter_test: dominio, repositorios y widgets |

La UI delega la persistencia en repositorios y los cálculos en `lib/logic/`.
Esta separación permite comprobar reglas financieras sin renderizar pantallas.
La estrategia de liquidación es una heurística que reduce transferencias; no se afirma optimalidad matemática para todos los grupos.

| Directorio | Responsabilidad |
| --- | --- |
| `lib/domain/models/` | Entidades, monedas y dinero |
| `lib/logic/` | Balances, divisiones, validaciones y sugerencias de pago |
| `lib/data/` | Esquema Drift, repositorios y respaldo |
| `lib/features/` | Pantallas y estado de cada funcionalidad |
| `lib/core/`, `lib/shared/` | Tema, utilidades y componentes comunes |
| `test/` | Pruebas unitarias, de datos y widgets |

## Cómo ejecutarlo

1. Instalá Flutter con Dart 3.12 o superior. El workflow utiliza Flutter **3.44.0**.
2. Prepará Android Studio o el SDK de Android y un emulador/dispositivo.
3. Cloná el proyecto:

   ```bash
   git clone https://github.com/luchonicolini/Gastos-Compartidos-Flutter.git
   cd Gastos-Compartidos-Flutter
   flutter doctor
   flutter pub get --enforce-lockfile
   flutter devices
   flutter run
   ```

4. Si hay varios dispositivos, seleccioná uno con `flutter run -d <ID>`.

El código generado de Drift ya está versionado. Después de modificar el esquema, regeneralo con:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Tests y CI

```bash
# Verificación focalizada del ciclo de liquidación
flutter test test/settlement_round_trip_test.dart

# Suite completa y análisis
flutter test --coverage
flutter analyze

# Compilación Android para desarrollo, sin credenciales de publicación
flutter build apk --debug
```

Los tests existentes cubren dinero, divisiones, validaciones, multimoneda, respaldo, repositorios y pantallas.
Los [tests de liquidación](test/settlement_round_trip_test.dart) comprueban que aplicar los pagos sugeridos deja los saldos en cero,
que retirar esos pagos recupera la deuda y que nombres iguales o integrantes archivados conservan su identidad e historial.

El [workflow](.github/workflows/flutter.yml) instala dependencias desde el lockfile, analiza, ejecuta toda la suite y compila un APK debug.
Corre en Ubuntu con Java 17; no requiere secretos ni firma de distribución.
Para los plugins del build incluido de Flutter, instala un script de repositorios
en un directorio Gradle temporal de CI. No modifica la configuración local del proyecto.
La compilación no reemplaza pruebas en dispositivos físicos.
El badge refleja `main`; mientras el workflow esté en un PR, sus checks son la referencia.

## Documentación

- [Producto](PRODUCT.md) y [reglas de negocio](SPEC.md).
- [Diseño](DESIGN.md) y [reconstrucción de UI](UI_REBUILD.md).
- [Plan](tasks/plan.md) y [tareas](tasks/todo.md).

## Próximos pasos

- Completar el pulido visual, la accesibilidad y las adaptaciones de pantalla.
- Validar el flujo completo en dispositivos Android e iOS.
- Revisar casos límite de liquidación y conservación de centavos.
- Preparar firma de distribución y publicación en Google Play.

## Pendientes de presentación

- [COMPLETAR: capturas de grupos, carga multidivisa y liquidaciones de la versión Flutter]
- [COMPLETAR: enlace a Google Play o programa de pruebas si existe una publicación]

## Autor

[Luciano Nicolini](https://github.com/luchonicolini) · iOS Developer (Swift, SwiftUI), con desarrollo multiplataforma en Flutter.
