# Especificación inicial: Gastos Compartidos en Flutter

## Objetivo

Adaptar la aplicación iOS original `Gastos-Compartidos` —desarrollada en SwiftUI y SwiftData— a Flutter, conservando sus reglas de negocio, flujos principales y personalidad visual inspirada en iOS.

La aplicación permitirá organizar viajes, administrar integrantes, registrar gastos en distintas monedas, dividirlos de distintas maneras y calcular cómo saldar las cuentas entre los miembros.

El diferencial del producto es la combinación de viajes, multidivisa y liquidación inteligente:
el usuario carga los gastos durante el viaje y al final recibe una solución clara para que nadie le deba dinero a nadie.

La primera versión será local-first: los datos se guardarán en el dispositivo y la app debe funcionar sin conexión. La arquitectura debe dejar aislada la persistencia para poder agregar sincronización en una etapa futura sin rehacer la UI.

## Usuario y resultado esperado

El usuario principal es una persona que comparte gastos con amigos, familia, pareja o compañeros de viaje.

El resultado esperado es que pueda pasar de un grupo vacío a una cuenta saldada con el menor número de pasos posible, entendiendo siempre quién pagó, quién participa, cuánto debe cada persona y qué pagos faltan.

## Mapa de capacidades

| Módulo | Responsabilidad | Depende de |
|---|---|---|
| grupos | Crear, listar, editar y eliminar grupos | persistencia, diseño base |
| miembros | Agregar, editar y quitar integrantes | grupos, persistencia |
| gastos | Registrar, editar y eliminar gastos | grupos, miembros, validaciones |
| balances | Calcular saldos individuales según los gastos | gastos, miembros |
| liquidaciones | Sugerir, confirmar y eliminar pagos | balances, miembros, persistencia |
| monedas | Moneda de referencia, importe original, conversión y tipo de cambio | gastos, persistencia |
| viajes | Datos de destino, fechas, presupuesto y configuración del viaje | grupos, monedas |
| experiencia-ios | Navegación, componentes, accesibilidad y estética Apple | todos los módulos de interfaz |

Orden recomendado: grupos → miembros → gastos → balances → liquidaciones → experiencia-ios/pulido.

## Flujo principal de usuario

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
  ├─ Agregar miembro
  ├─ Editar/eliminar miembro
  ├─ Agregar gasto
  │    ├─ Descripción, monto y fecha
  │    ├─ Seleccionar moneda original y tipo de cambio
  │    ├─ Seleccionar uno o varios pagadores
  │    ├─ Seleccionar participantes
  │    └─ Elegir tipo de división
  ├─ Editar/eliminar gasto
  ├─ Ver balances
  └─ Ver liquidaciones
       ├─ Confirmar pago
       └─ Eliminar pago confirmado
```

## Reglas funcionales

### Grupos

- El nombre es obligatorio y se guarda sin espacios innecesarios.
- Un grupo puede tener nombre, icono, color y fecha de creación.
- Eliminar un grupo requiere confirmación explícita.
- Al eliminar un grupo se eliminan sus gastos y liquidaciones asociadas.

### Miembros

- El nombre es obligatorio.
- No se puede agregar dos veces la misma persona al mismo grupo.
- Un miembro puede editarse o eliminarse desde el detalle del grupo.
- Un miembro no se elimina físicamente si tiene historial: se archiva y deja de aparecer entre los miembros activos.
- Los miembros archivados se conservan para identificar gastos y balances históricos.
- La UI debe distinguir miembros activos de miembros archivados y permitir recuperar un miembro archivado si fuera necesario.

### Gastos

- La descripción es obligatoria.
- El monto debe ser numérico y mayor que cero.
- Debe existir un pagador.
- Un gasto puede tener uno o varios pagadores con importes parciales que sumen el importe original.
- Debe existir al menos un participante.
- Tipos de división soportados:
  - equitativa;
  - monto fijo;
  - porcentaje;
  - partes/proporciones.
- Los importes se redondean a dos decimales.
- Las diferencias de redondeo se asignan de forma determinista para que la suma coincida con el total.
- Para monto fijo, la suma debe coincidir con el total.
- Para porcentaje, la suma debe ser 100%.
- Para partes, la suma debe ser mayor que cero.
- Nunca se reemplaza el importe original por el convertido.
- Un gasto multidivisa conserva importe original, moneda original, tipo de cambio, importe convertido y moneda de referencia.
- Los cálculos financieros deben utilizar una representación exacta en unidades mínimas o un value object equivalente; `double` no es la representación final del dinero.

### Viajes y monedas

- Un grupo debe poder evolucionar a un viaje sin romper sus referencias históricas.
- La moneda de referencia se configura por viaje/grupo.
- La primera prioridad de monedas es ARS y BRL; el modelo debe aceptar cualquier código ISO válido.
- Las tasas pueden ser manuales o automáticas en el futuro.
- Modificar la cotización actual no modifica gastos ya registrados.

### Balances y liquidaciones

- El balance positivo representa dinero a favor.
- El balance negativo representa dinero que la persona debe.
- Las liquidaciones deben minimizar la cantidad de transferencias necesarias.
- Confirmar una liquidación modifica los balances.
- Las liquidaciones confirmadas pueden eliminarse y deben recalcular los balances.
- Cuando no hay deudas, se muestra un estado de cuentas saldadas.

## Dirección visual iOS/Apple

La interfaz debe sentirse nativa de iOS sin copiar código SwiftUI literalmente.

- Usar navegación, sheets, confirmaciones y gestos familiares de iOS.
- Respetar safe areas, tamaños táctiles, Dynamic Type y modo oscuro.
- Preferir colores semánticos y tokens de diseño en lugar de colores hardcodeados dispersos.
- Mantener una jerarquía visual clara, sobria y orientada al contenido.
- Usar materiales, superficies elevadas y animaciones sutiles únicamente cuando ayuden a comprender la jerarquía.
- Respetar Reduce Motion y accesibilidad.
- El diseño debe adaptarse como mínimo a iPhone pequeño, iPhone grande y tablet.
- En Flutter se conservará la lógica de dominio, pero la interfaz se implementará con widgets Flutter apropiados; no se hará una traducción literal de cada `View` de SwiftUI.

## Arquitectura objetivo

```text
lib/
├── core/                 # tema, navegación, errores y utilidades comunes
├── domain/               # entidades y reglas puras del negocio
├── data/                 # persistencia local y repositorios
├── features/
│   ├── groups/
│   ├── members/
│   ├── expenses/
│   ├── balances/
│   └── settlements/
└── shared/               # widgets, formatos y componentes reutilizables
```

La UI no debe calcular balances ni escribir directamente en la persistencia. Las reglas de negocio deben poder probarse sin levantar Flutter.

## Estrategia de pruebas

- Tests unitarios para división de gastos, redondeos, balances, validaciones y liquidaciones.
- Widget tests para estados vacíos, formularios, selección de participantes, errores y confirmaciones.
- Tests de integración para el flujo completo: crear grupo → agregar miembros → cargar gasto → consultar balance → confirmar liquidación.
- Cada fase debe dejar `flutter test` funcionando.
- Las pruebas deben cubrir también casos límite: un solo participante, centavos impares, porcentajes inválidos, grupo sin gastos y eliminación de datos.

## Comandos de verificación

```bash
flutter pub get
flutter test
flutter analyze
flutter build web --release
```

La validación móvil se agregará cuando haya un simulador o dispositivo iOS/Android configurado.

## Fases propuestas

### Fase 1 — Fundaciones

- Aprobar este flujo y las reglas.
- Reorganizar la estructura Flutter por funcionalidades.
- Separar modelos, servicios y estado de la UI.
- Elegir e implementar persistencia local.
- Mantener todos los cálculos actuales cubiertos por tests.
- Preparar configuración de moneda con ARS como valor inicial y BRL como segunda prioridad.
- Reemplazar el uso financiero definitivo de `double` por dinero exacto en unidades mínimas/value objects.
- Diseñar el gasto para múltiples pagadores y conservar datos originales de conversión.

### Fase 2 — Grupos y miembros

- Lista persistente de grupos.
- Estado vacío.
- Crear, editar y eliminar grupo.
- Agregar, editar y eliminar miembros.
- Navegación iOS entre lista y detalle.

### Fase 3 — Gastos

- Formulario de gasto.
- Uno o varios pagadores y participantes.
- Las cuatro formas de división.
- Importe original, moneda y conversión a moneda de referencia.
- Edición, eliminación y validaciones.

### Fase 4 — Balances y liquidaciones

- Resumen por miembro.
- Sugerencias de pagos.
- Confirmación y eliminación de pagos.
- Estados saldados y errores.

### Fase 5 — Diseño iOS y calidad

- Sistema visual Apple-inspired.
- Dark Mode, Dynamic Type y accesibilidad.
- Responsive para iPhone/iPad.
- Animaciones y Reduce Motion.
- Tests de integración y revisión final.
- Preparar build y checklist de publicación para Google Play Store.

## Límites de la primera versión

- Sin sincronización entre dispositivos.
- Sin autenticación.
- Sin backend.
- Sin anuncios en la primera versión.
- Objetivo de distribución inicial: Android/Google Play Store.
- Primera moneda prioritaria: pesos argentinos (ARS), con BRL y otras monedas previstas desde el modelo inicial.
- Las funciones avanzadas de tasas automáticas, tickets, QR, mapas, estadísticas e invitaciones quedan para etapas posteriores.
- Sin cambiar las reglas de negocio sin actualizar primero esta especificación y sus tests.

## Preguntas abiertas

1. ¿La futura sincronización deberá ser entre dispositivos del mismo usuario, entre miembros del grupo o ambas?
2. ¿La moneda debe configurarse por grupo cuando incorporemos BRL y otras monedas?

## Criterio de aprobación

Esta especificación queda aprobada cuando se confirme:

- el flujo principal;
- las reglas de gastos y liquidaciones;
- la estrategia de persistencia;
- el alcance de iPhone/Android;
- el comportamiento de archivado de miembros;
- el alcance de anuncios;
- la prioridad inicial de publicación en Google Play Store.

Después de esa aprobación se creará el plan técnico en `tasks/plan.md` y la lista de tareas en `tasks/todo.md`.
