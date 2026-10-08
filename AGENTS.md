# Instrucciones del proyecto: Gastos Compartidos Flutter

## Contexto

Este proyecto es la adaptación Flutter de una aplicación original desarrollada en SwiftUI para iOS.

Fuente funcional y visual de referencia:

`/Users/lucianonicolini/Downloads/Gastos-Compartidos-main/`

La aplicación permite administrar grupos, miembros, gastos compartidos, balances y pagos de liquidación.

La visión de producto es organizar gastos de viajes entre amigos, especialmente viajes
multidivisa. El objetivo final es que, al terminar un viaje, todas las cuentas queden
equilibradas con la menor cantidad razonable de transferencias.

## Objetivo del proyecto

Construir una aplicación Flutter funcional, local-first y preparada inicialmente para Android/Google Play Store, conservando las reglas de negocio del proyecto SwiftUI y adaptando su experiencia visual a Flutter con una estética inspirada en iOS/Apple.

No traducir SwiftUI línea por línea. Reutilizar conceptos, flujos y reglas de negocio, implementándolos con patrones idiomáticos de Flutter.

## Decisiones aprobadas

- Primera versión únicamente local, sin backend ni sincronización.
- La arquitectura debe aislar la persistencia para permitir sincronización futura sin rehacer la UI.
- Prioridad de publicación: Android/Google Play Store.
- La app debe quedar preparada para iOS, aunque la validación inicial se hará en Android.
- Sin anuncios en la primera versión.
- Moneda inicial: pesos argentinos (ARS).
- El modelo de moneda debe permitir agregar reales brasileños (BRL) y otras monedas más adelante.
- Los miembros con historial no se eliminan físicamente: se archivan.
- Los miembros archivados no aparecen entre los miembros activos, pero conservan su identidad en gastos y balances históricos.
- Debe ser posible reactivar un miembro archivado.
- No cambiar reglas de negocio sin actualizar la especificación y los tests correspondientes.
- La entidad principal debe poder evolucionar de grupo a viaje, con moneda de referencia,
  presupuesto, categorías, tipos de cambio, actividad y liquidaciones.
- Un gasto debe conservar siempre el importe original, la moneda original, el tipo de cambio
  aplicado, el importe convertido y la moneda de referencia.
- El modelo debe soportar múltiples pagadores para un mismo gasto; no dividirlos artificialmente
  en gastos separados.
- Los cálculos financieros no deben depender de `double` como representación definitiva:
  priorizar unidades mínimas (centavos) o un value object de dinero, con redondeo determinista.
- Un cambio de cotización no modifica retroactivamente gastos existentes.

## Flujo principal

```text
Inicio
  ├─ Sin grupos → Estado vacío → Crear grupo
  └─ Con grupos → Lista de grupos
                    ├─ Abrir grupo
                    │    ├─ Resumen de balances
                    │    ├─ Lista de gastos
                    │    ├─ Lista de miembros
                    │    └─ Pagos sugeridos
                    ├─ Editar grupo
                    └─ Eliminar grupo → Confirmación

Detalle del grupo
  ├─ Agregar/editar/archivar/reactivar miembro
  ├─ Agregar gasto
  │    ├─ Descripción, importe original, moneda y fecha
  │    ├─ Seleccionar uno o varios pagadores
  │    ├─ Seleccionar participantes
  │    └─ Elegir división: equitativa, monto, porcentaje o partes
  ├─ Editar/eliminar gasto
  ├─ Ver balances
  └─ Ver liquidaciones
       ├─ Confirmar pago
       └─ Eliminar pago confirmado
```

## Arquitectura obligatoria

Mantener separación entre UI, estado de presentación, dominio y datos.

```text
lib/
├── core/                 # tema, navegación, errores y utilidades
├── domain/               # entidades y reglas puras del negocio
├── data/                 # persistencia local y repositorios
├── features/
│   ├── groups/
│   ├── members/
│   ├── expenses/
│   ├── balances/
│   └── settlements/
└── shared/               # widgets, formatos y componentes comunes
```

Reglas:

- La UI no calcula balances.
- La UI no escribe directamente en la base local.
- Los ViewModels/controladores coordinan estado y acciones del usuario.
- Los repositorios aíslan la tecnología de persistencia.
- La lógica de dominio debe poder probarse sin renderizar Flutter.
- No agregar abstracciones innecesarias: crear casos de uso solo cuando la lógica sea compleja o reutilizada.

## Reglas funcionales críticas

- Los nombres de grupos y miembros son obligatorios y se limpian de espacios innecesarios.
- Un gasto requiere descripción, monto positivo, pagador y al menos un participante.
- Un gasto puede tener uno o varios pagadores y debe conservar el importe original.
- Cada viaje/grupo debe poder definir una moneda de referencia; ARS es la primera prioridad,
  seguida por BRL y otras monedas sudamericanas.
- Los tipos de cambio pueden ser automáticos, manuales o fijados para el viaje en el futuro,
  pero cada gasto conserva la tasa concreta que utilizó.
- Los montos usan dos decimales.
- La división por monto debe sumar el total.
- La división por porcentaje debe sumar 100%.
- La división por partes debe tener una suma mayor que cero.
- Las diferencias de redondeo deben resolverse de forma determinista.
- El balance positivo representa dinero a favor.
- El balance negativo representa dinero adeudado.
- Las liquidaciones deben reducir la deuda con la menor cantidad razonable de transferencias.

## Dirección visual

Usar una estética Apple-inspired, no una copia literal de SwiftUI:

- navegación, sheets, confirmaciones y gestos familiares de iOS;
- safe areas y tamaños táctiles correctos;
- colores semánticos y tokens centralizados;
- soporte para modo oscuro;
- soporte para escalado de texto y accesibilidad;
- animaciones sutiles y respeto por Reduce Motion;
- layouts adaptables para teléfono y tablet;
- prioridad a claridad, contenido y consistencia sobre efectos decorativos.

## Proceso de trabajo

1. Leer `SPEC.md`, `tasks/plan.md` y `tasks/todo.md` antes de comenzar una fase.
2. Trabajar por fases verticales y verificables.
3. Antes de cambios de comportamiento, escribir o actualizar tests.
4. Ejecutar tests focalizados durante el desarrollo.
5. Ejecutar la suite completa al terminar cada tarea.
6. No avanzar a la siguiente fase con tests o builds fallando.
7. Marcar una tarea en `tasks/todo.md` solo cuando esté implementada y verificada.
8. Actualizar `SPEC.md` si cambia una decisión funcional o de alcance.

## Fases

### Fase 1 — Fundaciones

- reorganizar capas del proyecto;
- elegir e integrar persistencia local;
- definir repositorios;
- agregar archivado de miembros;
- centralizar validaciones y cálculos;
- agregar configuración de moneda con ARS y extensión futura para BRL;
- cubrir modelos, repositorios y dominio con tests.

### Fase 2 — Grupos y miembros

Lista persistente, estado vacío, CRUD de grupos, detalle, miembros activos y archivados.

### Fase 3 — Gastos

Formulario, pagador, participantes, cuatro modalidades de división, validaciones y edición.

### Fase 4 — Balances y liquidaciones

Balances, sugerencias, confirmación y eliminación de pagos, estados saldados.

### Fase 5 — Diseño y publicación

Sistema visual, experiencia iOS, accesibilidad, responsive, configuración Android y preparación para Google Play Store.

## Verificación

Usar estos comandos cuando correspondan:

```bash
flutter pub get
flutter test
flutter analyze
flutter build web --release
flutter build apk --release
```

La validación móvil debe ejecutarse cuando haya un emulador o dispositivo disponible.

## Archivos de referencia

- Especificación: `SPEC.md`
- Plan: `tasks/plan.md`
- Tareas: `tasks/todo.md`
- Proyecto SwiftUI de referencia: `/Users/lucianonicolini/Downloads/Gastos-Compartidos-main/`

## No hacer

- No agregar backend, login, sincronización ni anuncios sin aprobación explícita.
- No eliminar miembros con historial de forma destructiva.
- No copiar componentes SwiftUI literalmente.
- No esconder errores desactivando el análisis estático.
- No eliminar ni saltear tests para conseguir una suite verde.
