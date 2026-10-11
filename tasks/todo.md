# Tareas: Gastos Compartidos Flutter

> Estado al 10/10/2026: la interfaz anterior fue retirada para reconstruirla
> pantalla por pantalla. Su código está respaldado en `legacy-ui-2026-10-10.zip`.
> Las tareas de interfaz marcadas como pendientes abajo ya no están disponibles
> en la aplicación actual. Los modelos, cálculos y datos locales se conservaron.

## Fase 1 — Fundaciones

- [x] Definir contrato de persistencia local y comparar opciones compatibles con Flutter.
- [ ] Reorganizar el proyecto en capas `domain`, `data`, `features` y `shared`.
- [x] Agregar estado de miembro archivado y reglas de conservación histórica.
- [x] Extraer validaciones y cálculos de dominio en servicios testeables.
- [x] Crear configuración de moneda con ARS y extensión prevista para BRL.
- [x] Agregar repositorios locales para grupos, miembros, gastos y liquidaciones.
- [x] Crear value object de dinero exacto en unidades mínimas.
- [x] Crear modelo de moneda, moneda de referencia y tipo de cambio.
- [x] Adaptar gastos para múltiples pagadores sin perder el importe original.
- [x] Agregar tests exhaustivos de redondeo y suma exacta.

## Checkpoint — Fundaciones

- [ ] La app inicia sin datos corruptos.
- [ ] Los datos sobreviven al reinicio.
- [x] `flutter test` pasa.
- [x] `flutter build web --release` pasa.

## Fase 2 — Grupos y miembros

- [x] Reconstruir el estado vacío de grupos.
- [x] Reconstruir la lista persistente de grupos con contenido.
- [x] Reconstruir crear grupo con nombre, icono y color.
- [ ] Reconstruir editar grupo.
- [ ] Reconstruir eliminar grupo con confirmación.
- [x] Reconstruir el detalle de grupo.
- [x] Reconstruir el alta inicial de integrantes.
- [x] Implementar editar miembros.
- [x] Reconstruir la interfaz para archivar y reactivar miembros.

## Fase 3 — Gastos

- [x] Reconstruir el formulario base de gasto.
- [x] Reconstruir la selección de pagadores y participantes.
- [x] Reconstruir la interfaz de división equitativa.
- [x] Reconstruir la interfaz de división por monto.
- [x] Reconstruir la interfaz de división por porcentaje.
- [x] Reconstruir la interfaz de división por partes.
- [x] Reconstruir la edición y eliminación de gastos.

## Fase 4 — Balances y liquidaciones

- [x] Reconstruir el resumen de balances.
- [x] Reconstruir la presentación de sugerencias de pagos.
- [x] Reconstruir la confirmación de liquidación.
- [x] Reconstruir la eliminación de liquidación.
- [x] Reconstruir el estado de cuentas saldadas.
- [x] Verificar generación Drift y registro persistente de `Settlements`.
- [x] Unificar `SettlementPayment` y Repository con importes exactos en centavos.
- [x] Usar siempre `referenceCurrency` del grupo en balances y liquidaciones.
- [x] Cubrir balances, liquidaciones y persistencia multidivisa.
- [x] Ejecutar `flutter test`, `dart analyze` y build release.

## Fase 5 — Diseño y publicación

- [x] Reconstruir el onboarding de cuatro pasos con referencias visuales del usuario.
- [x] Mostrar el onboarding solo la primera vez y recordar «Saltar» o «Comenzar».
- [ ] Definir el nuevo sistema visual coherente para todas las pantallas.
- [ ] Definir tokens de aplicación compartidos.
- [ ] Reconstruir navegación, sheets y safe areas.
- [ ] Implementar contraste y modo oscuro en las nuevas pantallas.
- [ ] Adaptar las nuevas pantallas a teléfonos y tablets.
- [ ] Revisar accesibilidad completa y Reduce Motion.
- [ ] Configurar identidad Android y firma de release.
- [ ] Generar build de prueba para Google Play Store.
- [ ] Ejecutar checklist de publicación.
