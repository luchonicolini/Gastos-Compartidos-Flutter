# Dirección visual: Apple / iOS first

## Objetivo

La app debe sentirse como una aplicación nativa moderna de iPhone, aunque la
arquitectura y la implementación sean Flutter. Se conserva la lógica de negocio
multiplataforma, pero la jerarquía visual prioriza los patrones de iOS.

## Contrato visual

- Contenido primero: espacio en blanco, jerarquía clara y controles discretos.
- Una sola acción principal visible por superficie.
- Los importes y balances tienen más peso visual que sus etiquetas.
- Cards simples, con superficies diferenciadas y profundidad sutil.
- Menos bordes, colores y acciones simultáneas; no agregar componentes sin una
  función de producto comprobable.
- Sheets para tareas breves y focalizadas, especialmente crear o editar gastos.
- No agregar tab bar hasta que existan secciones de navegación de primer nivel.
- En iPad/tablet se puede ampliar a split view o sidebar cuando la información lo
  justifique; no estirar una pantalla de teléfono sin límite.

## Tokens y componentes

Los colores, radios, spacing y motion viven en `AppTokens`, montado como
`ThemeExtension`. Los gestos principales usan `AppPressable`, que reemplaza el
ripple Material por una respuesta de escala sutil y respeta Reduce Motion.

Los componentes de producto previstos son `TripCard`, `ExpenseCard`,
`BalanceCard`, `SettlementCard`, `MemberCard` y `CurrencyCard`. Se crearán solo
cuando exista una superficie que los necesite, no como una biblioteca aislada.

## Comparación antes de editar una pantalla

Para cada pantalla se revisan primero:

1. estado actual y contenido real;
2. referencias oficiales de Apple HIG para navegación, sheets, layout y
   materiales;
3. spacing, tipografía, jerarquía, cards, estados y comportamiento responsive;
4. elementos que deben eliminarse por ruido o duplicación;
5. criterios de accesibilidad y validación.

La referencia informa decisiones de estructura y comportamiento, no se copia la
marca ni el layout exacto de otra aplicación.

## Orden de superficies

1. Inicio y lista de viajes.
2. Detalle del viaje y balances.
3. Sheets de grupo, miembro y gasto.
4. Liquidaciones y estados saldados.
5. Accesibilidad, Reduce Motion, dark mode y publicación Android.
