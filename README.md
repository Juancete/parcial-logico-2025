# Sueldos

[![CI](https://github.com/Juancete/parcial-logico-2025/actions/workflows/ci.yml/badge.svg)](https://github.com/Juancete/parcial-logico-2025/actions/workflows/ci.yml)

Resolución de un parcial de la materia Paradigmas de Programación (Paradigma Lógico), escrita en SWI-Prolog. El enunciado completo está en [2025 - Sueldos unificado.md](./2025%20-%20Sueldos%20unificado.md).

## Cómo correr los tests

```
swipl -g run_tests -t halt solucion.pl
swipl -g run_tests -t halt solucionAlternativa.pl
```

Requiere tener instalado SWI-Prolog (probado con la versión 9.2.x).

## Estructura

El modelo resuelve los cuatro puntos del enunciado:

1. **Por la plata baila el mono** (`trabajaEn/2`, `sueldo/2`, `puesto/2` y `sueldoPromedio/2`): registra en qué departamento trabaja cada persona, cuánto gana y qué puesto tiene. El puesto se modela con un functor por tipo: `asalariado(Horas)`, `jefe(Subordinados)` e `independiente(Oficio)`.
2. **Paganini** (`esPaganini/1` y `ganaBien/1`): un departamento es paganini si todas las personas que trabajan en él ganan bien. El criterio de "ganar bien" depende del puesto y se resuelve con una cláusula por tipo en `ganaBienSegunPuesto/2`. El predicado es inversible.
3. **Houston...** (`estaEnProblemas/1` y `leGustaTrabajarEn/2`): un departamento está en problemas si ninguna persona que trabaja en él quiere trabajar ahí. El predicado es inversible.
4. **El juego de las sillas** (`reorganizacion/2` y `equipoAcotado/3`): relaciona un presupuesto con cada equipo de al menos dos personas que se puede armar sin superarlo. El generador descuenta el sueldo de cada persona del presupuesto a medida que la incorpora y corta la rama apenas queda negativo, y arranca directamente con dos personas. Así nunca produce equipos vacíos, unitarios ni que se pasen del presupuesto.

## Solución alternativa

[solucionAlternativa.pl](./solucionAlternativa.pl) resuelve los mismos cuatro puntos con dos decisiones distintas:

- **Punto 1**: el puesto y el sueldo van juntos en `trabaja(Persona, Puesto, Sueldo)` en vez de repartirse en `puesto/2` y `sueldo/2`. Así no puede existir una persona con puesto y sin sueldo, y `trabaja/3` es el generador explícito de personas que usa el punto 4.
- **Punto 4**: usa un generador general de subconjuntos que poda por presupuesto y deja afuera la condición de cantidad: `reorganizacion/3` aplica `length/2` para exigir al menos dos personas. También resuelve el bonus devolviendo cuánta plata sobra; `equipoAcotado/4` calcula ese sobrante en la misma recursión.
