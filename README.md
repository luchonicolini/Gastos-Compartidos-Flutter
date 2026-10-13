<div align="center">

# Gastos Compartidos

**Organizá los gastos de tu viaje en grupo y saldá las cuentas con la menor cantidad de transferencias.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Plataforma](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)
![Offline](https://img.shields.io/badge/local--first-sin%20conexi%C3%B3n-0D7E88)
![Estado](https://img.shields.io/badge/estado-en%20desarrollo-orange)

</div>

---

## Descripción

**Gastos Compartidos** es una aplicación móvil para quienes viajan o conviven con amigos, familia o compañeros y necesitan llevar la cuenta de quién pagó qué. Registrás los gastos a medida que ocurren y, al final, la app calcula cuánto le corresponde a cada persona y propone los pagos necesarios para dejar todo saldado.

Es la adaptación a Flutter de la app original para iOS (SwiftUI + SwiftData), conservando sus reglas de negocio y adaptando la experiencia a Android.

## Características

- **Grupos** con nombre, icono y color propios.
- **Integrantes** que se pueden agregar, editar, archivar y reactivar. Quienes tienen historial no se borran: se archivan para no perder la trazabilidad de gastos y balances.
- **Gastos con uno o varios pagadores**, sin tener que partirlos en gastos separados.
- **Cuatro formas de dividir un gasto:** en partes iguales, por monto fijo, por porcentaje o por partes.
- **Multimoneda:** cada gasto conserva su importe original, su moneda, el tipo de cambio aplicado y el importe convertido a la moneda de referencia del grupo. Cambiar la cotización no altera los gastos ya cargados.
- **Dinero exacto:** los cálculos se hacen en centavos, con redondeo determinista, para que las sumas siempre cierren.
- **Balances por persona** que muestran quién tiene saldo a favor y quién debe.
- **Liquidación inteligente:** sugiere pagos que reducen al mínimo razonable la cantidad de transferencias; los pagos se pueden confirmar y también eliminar, recalculando los balances.
- **Funciona sin conexión:** los datos viven en el dispositivo. Sin cuenta, sin backend y sin anuncios.
- **Onboarding** que se muestra solo la primera vez.
- **Ajustes:** tema (sistema, claro u oscuro), moneda predeterminada y borrado de todos los datos locales.
- **Accesibilidad:** modo oscuro, texto ampliado, áreas táctiles cómodas y reducción de movimiento.

### Monedas soportadas

| Código | Moneda |
|:------:|--------|
| `ARS` | Peso argentino (moneda inicial) |
| `BRL` | Real brasileño |
| `USD` | Dólar estadounidense |
| `EUR` | Euro |
| `UYU` | Peso uruguayo |

El modelo acepta cualquier código de moneda, por lo que sumar nuevas monedas es directo.

## Tecnologías

| Área | Herramienta |
|------|-------------|
| Framework | [Flutter](https://flutter.dev) (Dart `^3.12.0`) |
| Persistencia local | [Drift](https://drift.simonbinder.eu) + `drift_flutter` (SQLite) |
| Preferencias | `shared_preferences` |
| Formatos e internacionalización | `intl` |
| Identificadores | `uuid` |
| Gestos en listas | `flutter_slidable` |
| Tipografía | [Figtree](https://fonts.google.com/specimen/Figtree) (SIL OFL), incluida en `assets/fonts` |
| Generación de código | `build_runner` + `drift_dev` |
| Análisis estático | `flutter_lints` |

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) en canal `stable`, con Dart `3.12` o superior.
- Android Studio o el SDK de Android, y un emulador o dispositivo físico para correr la app.

Verificá tu entorno con:

```bash
flutter doctor
```

## Instalación y ejecución

```bash
# 1. Clonar el repositorio
git clone https://github.com/luchonicolini/Gastos-Compartidos-Flutter.git
cd Gastos-Compartidos-Flutter

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar la app
flutter run
```

### Generación de código (Drift)

El código generado de la base de datos (`app_database.g.dart`) ya está versionado. Solo necesitás regenerarlo si modificás las tablas en `lib/data/database/app_database.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Pruebas y calidad

```bash
flutter test       # suite de tests unitarios y de widgets
flutter analyze    # análisis estático
```

La suite cubre el dominio (dinero, validaciones, balances y liquidaciones), el repositorio local y las pantallas principales: onboarding, grupos, miembros, gastos y balances.

## Compilación

```bash
flutter build apk --release        # APK para Android
flutter build appbundle --release  # AAB para Google Play
flutter build web --release        # build web (verificación)
```

## Arquitectura

El proyecto separa la interfaz, el dominio y los datos. La UI no calcula balances ni escribe directamente en la base: las reglas de negocio viven en funciones puras que se pueden probar sin levantar Flutter, y la persistencia queda aislada detrás de repositorios para poder sumar sincronización más adelante sin rehacer la interfaz.

```text
lib/
├── core/            # Tema y utilidades comunes
├── data/
│   ├── database/    # Esquema Drift (grupos, personas, gastos, pagadores,
│   │                #   participantes, divisiones y liquidaciones)
│   └── repositories/# Acceso a datos local
├── domain/
│   └── models/      # Entidades y value objects (Money, Currency, Expense, ...)
├── logic/           # Reglas puras: validación de gastos, balances y liquidaciones
├── features/        # Una carpeta por funcionalidad
│   ├── onboarding/
│   ├── groups/
│   ├── members/
│   ├── expenses/
│   ├── balances/
│   └── settings/
├── shared/          # Componentes reutilizables
└── main.dart
```

## Documentación del proyecto

| Archivo | Contenido |
|---------|-----------|
| [`PRODUCT.md`](PRODUCT.md) | Propósito, usuarios y principios del producto |
| [`SPEC.md`](SPEC.md) | Especificación funcional y reglas de negocio |
| [`DESIGN.md`](DESIGN.md) | Sistema visual: colores, tipografía y componentes |
| [`UI_REBUILD.md`](UI_REBUILD.md) | Seguimiento de la reconstrucción de la interfaz |
| [`tasks/plan.md`](tasks/plan.md) · [`tasks/todo.md`](tasks/todo.md) | Plan técnico y lista de tareas |

## Estado del proyecto y hoja de ruta

El proyecto está **en desarrollo activo**. La interfaz se está reconstruyendo pantalla por pantalla; los modelos, cálculos y datos locales ya están implementados y cubiertos por tests.

- [x] Fundaciones: dinero exacto, monedas, tipo de cambio y persistencia local
- [x] Grupos y miembros (con archivado y reactivación)
- [x] Gastos con múltiples pagadores y las cuatro divisiones
- [x] Balances y liquidaciones
- [ ] Edición y eliminación de grupos desde la nueva interfaz
- [ ] Pulido de diseño, accesibilidad y responsive
- [ ] Publicación en Google Play Store

**Fuera del alcance de la primera versión:** sincronización entre dispositivos, autenticación, backend, anuncios, cotizaciones automáticas, tickets, QR, mapas y estadísticas.

## Contribuir

Las contribuciones son bienvenidas. Si querés colaborar:

1. Hacé un fork del repositorio.
2. Creá una rama para tu cambio: `git checkout -b feature/mi-mejora`.
3. Asegurate de que `flutter test` y `flutter analyze` pasen sin errores.
4. Abrí un Pull Request describiendo el cambio.

Si un cambio modifica una regla de negocio, actualizá primero `SPEC.md` y sus tests.

## Autor

**Luciano Nicolini** — [@luchonicolini](https://github.com/luchonicolini)
