# Sueldos

[![CI](https://github.com/Juancete/2026-logico-sueldos/actions/workflows/ci.yml/badge.svg)](https://github.com/Juancete/2026-logico-sueldos/actions/workflows/ci.yml)

Resolución de un parcial de la materia Paradigmas de Programación (Paradigma Lógico), escrita en SWI-Prolog. El enunciado completo está en [2025 - Sueldos unificado.md](./2025%20-%20Sueldos%20unificado.md).

## Cómo correr los tests

```
swipl -g run_tests -t halt solucion.pl
```

Requiere tener instalado SWI-Prolog (probado con la versión 9.2.x).

## Estructura

El modelo resuelve los cuatro puntos del enunciado:

1. **Por la plata baila el mono** (`trabajaEn/2`, `sueldo/2`, `puesto/2` y `sueldoPromedio/2`): registra en qué departamento trabaja cada persona, cuánto gana y qué puesto tiene. El puesto se modela con un functor por tipo: `asalariado(Horas)`, `jefe(Subordinados)` e `independiente(Oficio)`.
2. **Paganini** (`esPaganini/1` y `ganaBien/1`): un departamento es paganini si todas las personas que trabajan en él ganan bien. El criterio de "ganar bien" depende del puesto y se resuelve con una cláusula por tipo en `ganaBienSegunPuesto/2`. El predicado es inversible.
3. **Houston...** (`estaEnProblemas/1` y `leGustaTrabajarEn/2`): un departamento está en problemas si ninguna persona que trabaja en él quiere trabajar ahí. El predicado es inversible.
4. **El juego de las sillas** (`reorganizacion/3` y `subconjuntoDeAlMenosDos/2`): relaciona un presupuesto con cada equipo de al menos dos personas que se puede armar sin superarlo, y cuánta plata sobra (bonus). El generador de subconjuntos arranca directamente con dos elementos, así no produce equipos vacíos ni unitarios que después haya que descartar.
