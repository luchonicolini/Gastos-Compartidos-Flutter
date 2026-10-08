# Tareas: Gastos Compartidos Flutter

## Fase 1 — Fundaciones

- [x] Definir contrato de persistencia local y comparar opciones compatibles con Flutter.
- [ ] Reorganizar el proyecto en capas `domain`, `data`, `features` y `shared`.
- [x] Agregar estado de miembro archivado y reglas de conservación histórica.
- [ ] Extraer validaciones y cálculos de dominio en servicios testeables.
- [ ] Crear configuración de moneda con ARS y extensión prevista para BRL.
- [ ] Agregar repositorios locales para grupos, miembros, gastos y liquidaciones.

## Checkpoint — Fundaciones

- [ ] La app inicia sin datos corruptos.
- [ ] Los datos sobreviven al reinicio.
- [x] `flutter test` pasa.
- [x] `flutter build web --release` pasa.

## Fase 2 — Grupos y miembros

- [x] Implementar lista persistente de grupos.
- [x] Implementar crear y editar grupo.
- [x] Implementar eliminar grupo con confirmación.
- [x] Implementar detalle de grupo.
- [ ] Implementar agregar y editar miembros.
- [x] Implementar archivar y reactivar miembros.

## Fase 3 — Gastos

- [ ] Implementar formulario base de gasto.
- [ ] Implementar pagador y participantes.
- [ ] Implementar división equitativa.
- [ ] Implementar división por monto.
- [ ] Implementar división por porcentaje.
- [ ] Implementar división por partes.
- [ ] Implementar edición y eliminación de gastos.

## Fase 4 — Balances y liquidaciones

- [ ] Implementar resumen de balances.
- [ ] Implementar sugerencias de pagos.
- [ ] Implementar confirmación de liquidación.
- [ ] Implementar eliminación de liquidación.
- [ ] Implementar estado de cuentas saldadas.

## Fase 5 — Diseño y publicación

- [ ] Aplicar sistema visual Apple-inspired.
- [ ] Revisar navegación, sheets, gestos y safe areas.
- [ ] Revisar modo oscuro, accesibilidad y Reduce Motion.
- [ ] Adaptar layouts para teléfonos y tablets.
- [ ] Configurar identidad Android y firma de release.
- [ ] Generar build de prueba para Google Play Store.
- [ ] Ejecutar checklist de publicación.
