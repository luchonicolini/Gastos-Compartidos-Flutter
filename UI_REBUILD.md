# Reconstrucción de la interfaz

El 10/10/2026 se retiraron las pantallas existentes porque cada una había
adquirido un lenguaje visual distinto. La aplicación muestra un onboarding nuevo
solo la primera vez y luego el Home nuevo. El Home guía a quien todavía no tiene
grupos y conserva una vista temporal de los grupos locales existentes. Durante
esta etapa no permite crear ni editar datos desde la interfaz.

## Conservado y activo

- Modelos de grupos, miembros, gastos, monedas y liquidaciones.
- Cálculos de balances, división y pagos sugeridos.
- Validaciones de gastos y representación exacta del dinero.
- Base Drift, repositorio local y datos guardados en el dispositivo.
- `GroupOperations`, que reúne las acciones de grupos, miembros, gastos y pagos
  para conectarlas con las nuevas pantallas.

## Retirado

Home, detalle de grupo, formularios, onboarding y componentes visuales
anteriores, junto a sus pruebas de widgets. Están respaldados en
`legacy-ui-2026-10-10.zip` para consulta o recuperación. El respaldo contiene
12 archivos y fue verificado antes de retirar los originales.

## Orden de reconstrucción

1. Onboarding según las referencias visuales entregadas (implementado).
2. Home: estado vacío guiado y entrada funcional a crear grupo (implementados);
   queda pendiente la lista de grupos.
3. Editar grupo, con nombre, color e icono.
4. Alta inicial de integrantes (implementada); detalle y administración de miembros.
5. Gastos, balances y liquidaciones.
6. Revisión integral de accesibilidad y dispositivos.

Cada etapa debe restaurar pruebas de la experiencia que vuelve a estar activa.
