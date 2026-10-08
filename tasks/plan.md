# Plan de implementación: Gastos Compartidos Flutter

## Resumen

Migrar progresivamente la aplicación SwiftUI original a Flutter, conservando las reglas de negocio y una experiencia visual inspirada en iOS, con una primera entrega local para Android y Google Play Store.

## Decisiones aprobadas

- Persistencia local en la primera versión.
- Arquitectura preparada para una futura sincronización mediante repositorios aislados.
- Publicación inicial enfocada en Android/Google Play Store.
- Sin anuncios en la primera versión.
- ARS como moneda inicial; modelo extensible para BRL y otras monedas.
- Los miembros con historial se archivan, no se eliminan físicamente.
- Separación estricta entre UI, ViewModels, dominio y datos.

## Arquitectura objetivo

```text
UI/features → ViewModels → Repositories → Local data source
                  ↓
             Domain services
```

La persistencia local será una decisión de implementación de la Fase 1. El resto de la app dependerá de interfaces de repositorio, no de una base de datos concreta.

## Orden de implementación

### Fase 1: Fundaciones y persistencia local

- Definir entidades inmutables y estados de archivado.
- Separar la lógica de cálculo del estado de la UI.
- Elegir e integrar la solución de persistencia local.
- Crear repositorios para grupos, miembros, gastos y liquidaciones.
- Añadir configuración de moneda con ARS.
- Cubrir modelos, repositorios y cálculos con tests.

Checkpoint: la app inicia, carga datos locales y `flutter test` pasa.

### Fase 2: Grupos y miembros

- Implementar lista de grupos y estado vacío.
- Crear, editar y archivar/eliminar grupos.
- Implementar detalle de grupo.
- Agregar, editar, archivar y reactivar miembros.
- Conservar referencias históricas de miembros archivados.

Checkpoint: crear grupo → agregar miembros → cerrar y volver a abrir la app → recuperar los datos.

### Fase 3: Gastos

- Implementar formulario de gasto.
- Agregar selección de pagador y participantes.
- Implementar las cuatro modalidades de división.
- Implementar validaciones y mensajes de error.
- Editar y eliminar gastos.

Checkpoint: crear gasto en cada modalidad y comprobar que la suma de participaciones sea correcta.

### Fase 4: Balances y liquidaciones

- Mostrar balances por miembro.
- Mostrar sugerencias de liquidación.
- Confirmar pagos.
- Eliminar pagos confirmados y recalcular.
- Mostrar estados sin deudas.

Checkpoint: flujo completo grupo → miembros → gasto → balance → liquidación confirmada.

### Fase 5: Experiencia iOS y publicación Android

- Implementar tokens visuales Apple-inspired.
- Adaptar navegación, sheets, gestos y componentes a Flutter.
- Revisar modo oscuro, accesibilidad, safe areas y Reduce Motion.
- Adaptar iPhone/iPad sin bloquear la entrega Android.
- Configurar icono, nombre, versión, firma y permisos Android.
- Generar build de prueba y checklist de Play Store.

Checkpoint: build Android release verificable y flujo principal probado en dispositivo/emulador.

## Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Elegir una base local difícil de migrar | Alto | Aislarla detrás de repositorios desde el inicio |
| Borrar miembros rompe historial | Alto | Archivado lógico y referencias estables |
| Diferencias de redondeo entre Swift y Dart | Alto | Tests de equivalencia y redondeo centralizado |
| Traducir SwiftUI literalmente | Medio | Reutilizar flujos y reglas, no estructura de widgets |
| Priorizar estética antes que flujo | Medio | Completar cada fase vertical antes del pulido visual |
| No poder probar iOS ahora | Medio | Priorizar Android y mantener patrones compatibles con iOS |

## Criterio de finalización de la primera versión

- El usuario puede crear un grupo y persistirlo localmente.
- Puede administrar miembros activos y archivados.
- Puede registrar gastos con las cuatro modalidades de división.
- Puede consultar balances y confirmar liquidaciones.
- La app funciona sin conexión.
- Hay tests unitarios, widget tests y un flujo de integración básico.
- Existe un build Android release listo para validación previa a Play Store.
