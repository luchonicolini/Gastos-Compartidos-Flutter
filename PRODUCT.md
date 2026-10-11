# Gastos Compartidos

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Personas que viajan o comparten gastos con amigos, familia o compañeros y quieren saber quién pagó, cuánto corresponde a cada uno y cómo saldar las cuentas.

## Product Purpose

Registrar gastos compartidos durante un viaje y llegar a un balance final claro con una cantidad razonable de transferencias.

## Operating Context

Grupos locales en el dispositivo, integrantes, gastos con uno o varios pagadores, distintas divisiones, moneda original y moneda de referencia, balances y pagos confirmados. La aplicación funciona sin conexión.

## Capabilities and Constraints

- Flutter con publicación inicial en Android y arquitectura preparada para iOS.
- Persistencia local aislada detrás de repositorios; sin backend, cuenta ni anuncios en la primera versión.
- ARS como moneda inicial; BRL y otras monedas previstas en el modelo.
- Los importes conservan la moneda y tasa aplicadas; las reglas financieras usan centavos y redondeo determinista.
- Los miembros con historial se archivan y pueden reactivarse.
- El onboarding se muestra solo la primera vez; completarlo o saltarlo guarda la elección localmente.

## Brand Commitments

Nombre: Gastos Compartidos. El usuario entregó cuatro diseños claros para el onboarding y el diseño `Mis grupos · vacío (claro)@1x.png` para el primer Home sin datos. Estas referencias gobiernan la reconstrucción visual de ese recorrido.

## Product Principles

- Guiar sin hacer que la persona adivine el siguiente paso.
- Mostrar juntas las decisiones y cifras relacionadas.
- Explicar las reglas de gastos y monedas con ejemplos concretos.
- Conservar datos y cálculos al renovar la interfaz.

## Accessibility & Inclusion

Soporte para tamaños de texto ampliados, áreas táctiles cómodas, contraste suficiente, modo oscuro y reducción de movimiento.
