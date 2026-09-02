# Sueldos: análisis de diseño y smells de modelado

Este apunte acompaña a [`solucion.pl`](./solucion.pl) y al enunciado
[2025 - Sueldos unificado](./2025%20-%20Sueldos%20unificado.md). La idea no es
mostrar "la" solución, sino explicar por qué está diseñada así y compararla,
punto por punto, con otras formas de resolver lo mismo que también pasan los
tests pero que arrastran problemas de diseño. Cada alternativa está corrida en
SWI-Prolog contra la misma base de conocimientos; las salidas que aparecen son
reales, no inventadas. Hay además una
[`solucionAlternativa.pl`](./solucionAlternativa.pl) que toma dos decisiones
distintas (junta puesto y sueldo en `trabaja/3`, y resuelve el bonus del punto
4); se la menciona donde corresponde.

Para leerlo conviene tener a mano los módulos de la materia, porque cada
decisión se justifica desde alguno de ellos:

| Módulo | Tema | Dónde aparece acá |
|---|---|---|
| 1 | Individuos, predicados, universo cerrado | Punto 1 (rob, ginger, gus), debate de departamentos vacíos |
| 2 | Variables, existenciales, inversibilidad | Puntos 2 y 3 (generadores, orden de los literales) |
| 3 | Individuos compuestos | Punto 1 (functores por puesto) |
| 4 | Orden superior | `forall`, `findall`, `not` en los puntos 2, 3 y 4 |
| 5 | Recursividad | Punto 4 (generador de equipos con poda) |
| 6 | Diseño, delegación, acoplamiento, smells | Todo el apunte |
| 7 | Explosión combinatoria | Punto 4 (podar en la recursión en vez de generar y descartar) |

---

## Catálogo de smells que vamos a usar

Los nombres son los que usamos al corregir. No son "errores" en el sentido de
que el programa dé mal: casi todas las alternativas de este apunte pasan los
tests. Son señales de que el modelo está peleado con el paradigma.

- **Tipo como dato / falta de polimorfismo.** Guardar el "tipo" de algo como un
  átomo suelto (`tipo(kyle, asalariado)`) en vez de derivarlo del functor. Obliga
  a preguntar de qué tipo es antes de saber qué hacer: el if de tipo de siempre,
  disfrazado.
- **Ausencia modelada con centinela.** Escribir `subordinados(kyle, [])` o
  `oficio(kyle, ninguno)` para decir "no aplica". En universo cerrado lo que no
  es cierto no se escribe.
- **Listas donde va una relación.** Meter en una lista lo que son varios hechos
  (`departamento(ventas, [kyle, trisha, joshua])`). Se pierde el backtracking
  gratis y todo termina en `member`.
- **`findall` + `member`, `findall` + `length`.** Armar una lista para después
  recorrerla o contarla, cuando el motor ya sabe recorrer y "hay al menos uno"
  o "no hay ninguno" se preguntan directo.
- **Doble negación evitable.** `not((..., not(...)))` cuando hay un `forall` que
  dice lo mismo en positivo.
- **`not` con variables libres.** Negar antes de que un generador ligue la
  variable. No tira error: pierde soluciones en silencio.
- **`forall` sin generador previo.** Con la variable libre, el `forall` deja de
  cuantificar "las personas de este departamento" y pasa a cuantificar todos los
  pares de la base. Cambia el dominio sin que el código lo diga.
- **Verdad vacía.** Un `forall` sobre un conjunto vacío es verdadero. A veces es
  lo que el dominio quiere y a veces no; hay que decidirlo, no dejar que pase.
- **Hardcodeo de regla de negocio.** Un número del enunciado metido dentro de
  la regla en vez de reificado como hecho.
- **Duplicidad no abstraída.** Las mismas tres líneas repetidas en cada cláusula.
- **Generador sin controlar.** Un predicado que responde la misma solución
  varias veces porque el generador tiene repetidos o porque dos cláusulas no
  son disjuntas.
- **Generate-and-test con basura.** Generar cosas que después se descartan
  siempre (subconjuntos vacíos, permutaciones del mismo equipo).
- **Inversibilidad rota.** Variables de menos (no liga) o de más (liga pero
  con el dominio equivocado).
- **Menores.** Nombres de una letra, incógnitas innecesarias, predicados que no
  llama nadie, comentarios informales que no aportan.

---

## Punto 1: el modelado

### Lo que hace la solución

```prolog
trabajaEn(ventas, kyle).          % relación departamento-persona, un hecho por par
sueldo(kyle, 50).                 % el sueldo es un atributo aparte
puesto(kyle, asalariado(6)).      % el puesto es un individuo compuesto
puesto(ian, jefe([kyle, rob, ginger])).
puesto(joshua, independiente(arquitecto)).
sueldoPromedio(6, 45).            % regla de negocio del punto 2, reificada
```

Tres decisiones sostienen todo lo que viene después:

1. **El puesto es un functor distinto por tipo.** `asalariado/1`, `jefe/1` e
   `independiente/1` llevan adentro exactamente el dato que el enunciado asocia
   a cada tipo (horas, subordinados, oficio) y nada más. No existe un campo que
   "no aplica". El tipo no se guarda: se deriva por pattern matching, y eso es
   lo que en el punto 2 permite escribir una cláusula por tipo sin preguntar
   nada.
2. **El sueldo va aparte.** Cuánto gana alguien es ortogonal a qué puesto tiene.
   Si lo metiéramos dentro del functor, en el punto 4 habría que desarmar tres
   functores distintos para descontar cada sueldo del presupuesto.
3. **Universo cerrado, en serio.** Rob y Ginger aparecen como subordinados de
   Ian pero no tienen sueldo ni puesto: el enunciado no lo dice, así que no se
   escribe. Gus tiene sueldo y puesto pero no trabaja en ningún departamento,
   por la misma razón. Ninguno de los dos casos necesita un hecho especial.

Sobre la **lista de subordinados**: normalmente diríamos que "a cargo de"
es una relación, no una lista, y que iría `subordinado(ian, kyle)`. Acá la
lista está justificada porque el enunciado dice que los subordinados están
"ordenados por importancia": el orden es un dato del dominio, y una relación lo
pierde. Es una decisión, no un descuido, y vale la pena decirlo en voz alta. Si
el enunciado no mencionara el orden, la relación sería mejor: se puede preguntar
"¿de quién es subordinado Kyle?" sin `member`, y "cuántos tiene a cargo" se
resuelve con `aggregate_all(count, ...)` en vez de `length`.

### Alternativas peores

**A. El hecho ancho.** Todo en un solo predicado, con el tipo como átomo y
centinelas para lo que no aplica.

```prolog
persona(kyle,   ventas,    50, asalariado,    6,  [],           ninguno).
persona(ian,    logistica, 40, jefe,          0,  [kyle, rob, ginger], ninguno).
persona(joshua, ventas,    55, independiente, 0,  [],           arquitecto).
persona(gus,    ninguno,   60, asalariado,    8,  [],           ninguno).
```

Tres smells de una vez: **tipo como dato** (el átomo `asalariado`), **ausencia
con centinela** (`0`, `[]`, `ninguno`, y peor todavía `ninguno` como
departamento de Gus) y hechos de siete argumentos donde nadie recuerda cuál es
cuál. Además habilita estados inconsistentes: nada impide un `jefe` con horas
distintas de cero o un `asalariado` con subordinados. En la solución eso es
imposible por construcción.

**B. El tipo como predicado suelto.** Parece más prolijo pero desacopla el tipo
de su atributo.

```prolog
esAsalariado(kyle).     horas(kyle, 6).
esJefe(ian).            subordinados(ian, [kyle, rob, ginger]).
esIndependiente(joshua). oficio(joshua, arquitecto).
```

Puede existir `esAsalariado(gus)` sin `horas(gus, _)`, o `horas(trisha, 4)`
sin que Trisha sea asalariada. Y en el punto 2 la regla de "gana bien" queda
obligada a preguntar `esAsalariado(P)` antes de buscar las horas: el if de tipo
vuelve por la ventana.

**C. El sueldo adentro del puesto.**

```prolog
puesto(kyle,   asalariado(6, 50)).
puesto(ian,    jefe([kyle, rob, ginger], 40)).
puesto(joshua, independiente(arquitecto, 55)).
```

Mezcla dos conceptos que el enunciado presenta separados. La consecuencia se ve
recién en el punto 4: para descontar el sueldo de cada persona hay que escribir
un `sueldoDe/2` con tres cláusulas que desarman cada functor, cuando `sueldo/2`
como hecho aparte ya era eso.

Distinto es juntar puesto y sueldo como argumentos hermanos de un mismo hecho,
`trabaja(kyle, asalariado(6), 50)`, que es lo que hace `solucionAlternativa.pl`.
Ahí el sueldo sigue afuera del functor y se saca con una variable anónima sin
saber el tipo, y se gana que no pueda existir una persona con puesto y sin
sueldo. Es una variante igual de válida; la diferencia es que la solución
principal trata sueldo y puesto como dos relaciones independientes y la
alternativa como una sola.

**D. El departamento como lista.**

```prolog
departamento(ventas, [kyle, trisha, joshua]).
departamento(logistica, [ian, sherri]).
```

**Lista donde va una relación.** Desde acá, "las personas de un departamento"
ya no se recorren con backtracking sino con `member`, y "en qué departamento
trabaja Kyle" necesita `departamento(D, Personas), member(kyle, Personas)`. El
punto 3 termina en `findall` + `member` casi seguro. La relación `trabajaEn/2`
responde las dos preguntas con el mismo hecho y sin lista.

---

## Punto 2: Paganini

### Lo que hace la solución

```prolog
departamento(Departamento) :-
  distinct(Departamento, trabajaEn(Departamento, _)).

esPaganini(Departamento) :-
  departamento(Departamento),
  forall(trabajaEn(Departamento, Persona), ganaBien(Persona)).

ganaBien(Persona) :-
  sueldo(Persona, Sueldo),
  puesto(Persona, Puesto),
  ganaBienSegunPuesto(Puesto, Sueldo).

ganaBienSegunPuesto(asalariado(Horas), Sueldo) :-
  sueldoPromedio(Horas, Promedio),
  Sueldo > Promedio.
ganaBienSegunPuesto(jefe(Subordinados), Sueldo) :-
  length(Subordinados, CantidadACargo),
  Sueldo > 20 * CantidadACargo.
ganaBienSegunPuesto(independiente(arquitecto), _).
ganaBienSegunPuesto(independiente(Oficio), Sueldo) :-
  Oficio \= arquitecto,
  Sueldo > 70.
```

Lo importante está en la delegación. `esPaganini` sólo sabe que "todas las
personas del departamento ganan bien". `ganaBien` sólo sabe que hay que buscar
sueldo y puesto y preguntarle al puesto. Y `ganaBienSegunPuesto` es el
polimorfismo del paradigma: **una cláusula por functor, sin preguntar el tipo**.
Cuando aparece un puesto nuevo se agrega una cláusula y nadie más se entera.

Fijate que `sueldoPromedio/2` es un hecho. El enunciado dice "el promedio de 6
horas es 45"; eso es un dato, y como dato se modela.

### Alternativas peores

**A. `forall` sin generador.** La versión que casi todos escriben primero.

```prolog
esPaganini(Departamento) :-
  forall(trabajaEn(Departamento, Persona), ganaBien(Persona)).
```

Con el departamento ligado funciona: `esPaganini(ventas)` es verdadero. Con la
variable libre, el `forall` ya no cuantifica sobre "las personas de este
departamento" sino sobre **todos los pares** `(Departamento, Persona)` de la
base. Como Ian y Sherri no ganan bien, responde `false` y no liga nada.

```
?- esPaganini(ventas).
true.
?- esPaganini(Departamento).
false.
```

No es inversible, y el enunciado lo pide. Peor: no tira `instantiation_error`,
así que un test con el departamento fijo no lo detecta. El generador
`departamento(Departamento)` adelante es lo que arregla el dominio de
cuantificación.

**B. Generador sin controlar.** Usar `trabajaEn` directo como generador.

```prolog
esPaganini(Departamento) :-
  trabajaEn(Departamento, _),
  forall(trabajaEn(Departamento, Persona), ganaBien(Persona)).
```

Ahora es inversible, pero ventas tiene tres empleados y aparece tres veces:

```
?- esPaganini(Departamento).
Departamento = ventas ;
Departamento = ventas ;
Departamento = ventas.
```

Por eso `departamento/1` usa `distinct/2`. Sobre si eso también es un parche,
ver la autocrítica al final de este punto.

**C. If de tipo con duplicidad.** Tres cláusulas de `ganaBien` que repiten la
búsqueda y preguntan el functor con una unificación explícita.

```prolog
ganaBien(Persona) :-
  sueldo(Persona, Sueldo), puesto(Persona, Puesto),
  Puesto = asalariado(Horas), sueldoPromedio(Horas, Promedio), Sueldo > Promedio.
ganaBien(Persona) :-
  sueldo(Persona, Sueldo), puesto(Persona, Puesto),
  Puesto = jefe(Subordinados), length(Subordinados, Cantidad), Sueldo > 20 * Cantidad.
ganaBien(Persona) :-
  sueldo(Persona, Sueldo), puesto(Persona, Puesto),
  Puesto = independiente(Oficio), (Oficio = arquitecto ; Sueldo > 70).
```

Da los mismos resultados (`kyle`, `trisha`, `joshua`). Pero `sueldo(...),
puesto(...)` está tres veces, y el `Puesto = asalariado(Horas)` en el cuerpo es
un if de tipo escrito con `=`. La solución hace exactamente lo mismo pero
poniendo el functor en la **cabeza** de un predicado aparte: el matching lo
hace el motor, la búsqueda está una sola vez, y cada cláusula tiene una sola
responsabilidad.

**D. Doble negación.** "Todas ganan bien" escrito como "no hay ninguna que no
gane bien".

```prolog
esPaganini(Departamento) :-
  departamento(Departamento),
  not((trabajaEn(Departamento, Persona), not(ganaBien(Persona)))).
```

Es lógicamente equivalente y responde `ventas`. De hecho `forall/2` está
implementado así por debajo. Pero el enunciado dice "todas", y `forall` es la
palabra "todas". Obligar al lector a hacer la doble negación mentalmente es un
costo que no compra nada.

**E. `findall` + `length`.** Contar las que ganan bien y compararlo con el total.

```prolog
esPaganini(Departamento) :-
  departamento(Departamento),
  findall(Persona, trabajaEn(Departamento, Persona), Todas),
  findall(Persona, (trabajaEn(Departamento, Persona), ganaBien(Persona)), GananBien),
  length(Todas, Cantidad),
  length(GananBien, Cantidad).
```

Responde `ventas`, y es la forma más procedural posible de decir "todas". Arma
dos listas para después compararlas por tamaño, que es una manera muy indirecta
de expresar una cuantificación universal. Es el smell que más marcamos en las
correcciones: si vas a recorrer o contar lo que acabás de juntar, casi seguro
no hacía falta juntarlo.

**F. Hardcodear el promedio.**

```prolog
ganaBienSegunPuesto(asalariado(6), Sueldo) :- Sueldo > 45.
ganaBienSegunPuesto(asalariado(7), Sueldo) :- Sueldo > 60.
ganaBienSegunPuesto(asalariado(8), Sueldo) :- Sueldo > 80.
```

Funciona y hasta parece más corto. Pero mezcló un dato del negocio con la
regla: si aparece un asalariado de 5 horas hay que tocar la regla en vez de
agregar un hecho, y no se puede preguntar "¿cuál es el promedio de 7 horas?"
porque el promedio ya no existe como concepto. `sueldoPromedio/2` lo reifica.

**G. El independiente sin la guarda.** Este es sutil y vale la pena correrlo en
clase.

```prolog
ganaBienSegunPuesto(independiente(arquitecto), _).
ganaBienSegunPuesto(independiente(_), Sueldo) :- Sueldo > 70.
```

Un arquitecto que gana 80 satisface las dos cláusulas y el predicado responde
dos veces. Con la guarda `Oficio \= arquitecto` las cláusulas son disjuntas.

```
?- ganaBienSegunPuesto(independiente(arquitecto), 80).   % sin guarda
true ;
true.
```

La tentación es "arreglarlo" con un `;` en una sola cláusula:

```prolog
ganaBienSegunPuesto(independiente(Oficio), Sueldo) :-
  (Oficio = arquitecto ; Sueldo > 70).
```

Y **también duplica**: el `;` deja un punto de elección, y si las dos ramas son
verdaderas, responde dos veces. Verificado: `independiente(arquitecto), 80`
da dos soluciones con esta versión. La conclusión para la clase es que el
problema no es la sintaxis sino que las dos condiciones se solapan, y la única
forma limpia de resolverlo es hacerlas disjuntas.

En este parcial no se nota porque Joshua gana 55, pero en el punto 4 o en un
`findall` sobre `ganaBien` los duplicados se cuelan y desde ahí todo lo que
cuente da mal.

**H. `>=` en vez de `>`.** No es un smell, es leer mal. Sherri gana 60 y el
promedio de 7 horas es 60: "gana más que el promedio" es estrictamente más.
Con `>=` Sherri ganaría bien. Logística seguiría sin ser paganini por Ian, así
que el ejemplo del enunciado no lo detecta. Por eso hay un test específico
para Sherri.

### Autocrítica: el `distinct` en `departamento/1`

La solución deriva los departamentos de `trabajaEn/2` y usa `distinct/2` para
no repetirlos. Es la misma construcción que en otros TPs marcamos como parche:
el `distinct` está ahí para tapar que el generador tiene repetidos, no porque
el dominio lo pida. La alternativa es modelar los departamentos como
individuos de primera clase:

```prolog
departamento(ventas).
departamento(logistica).
departamento(contabilidad).
departamento(facturacion).
departamento(cobranzas).
```

Sin `distinct`, sin regla, y los tres departamentos que aparecen en
`leGustaTrabajarEn/2` pasan a existir. Pero eso tiene una consecuencia que hay
que mirar de frente: contabilidad no tiene empleados, y un `forall` sobre un
conjunto vacío es verdadero.

```
?- esPaganini(Departamento).      % con departamentos por hechos
Departamento = ventas ;
Departamento = contabilidad.
```

¿Un departamento sin gente es paganini? "Todas las personas que trabajan en
él ganan bien" es vacuamente cierto. Si el dominio no quiere eso, hay que
agregar `trabajaEn(Departamento, _)` antes del `forall` como guarda de
no-vacuidad. La solución esquiva el problema porque su generador sólo produce
departamentos con gente, pero lo esquiva por accidente, no por decisión. Las
dos formas son defendibles; lo que no es defendible es no haber pensado en el
caso. Esto reaparece en el punto 3.

---

## Punto 3: Houston...

### Lo que hace la solución

```prolog
estaEnProblemas(Departamento) :-
  departamento(Departamento),
  not(alguienQuiereTrabajarAhi(Departamento)).

alguienQuiereTrabajarAhi(Departamento) :-
  trabajaEn(Departamento, Persona),
  leGustaTrabajarEn(Persona, Departamento).
```

"Ninguna persona quiere trabajar ahí" es la negación de un existencial:
"no es cierto que alguien quiera". La solución lo escribe exactamente así, y
le pone nombre al existencial. Eso **no** es doble negación: hay un solo `not`,
y adentro hay una conjunción positiva. El generador va antes del `not`, como
siempre.

### Alternativas peores

**A. El `not` antes del generador.** El error más caro de este punto, porque no
avisa.

```prolog
estaEnProblemas(Departamento) :-
  not(alguienQuiereTrabajarAhi(Departamento)),
  departamento(Departamento).
```

Con el departamento ligado funciona: `estaEnProblemas(logistica)` da `true`.
Con la variable libre, el `not` pregunta "¿existe *algún* departamento donde
alguien quiera trabajar?", la respuesta es sí (ventas), y el `not` falla para
toda la consulta.

```
?- estaEnProblemas(logistica).
true.
?- estaEnProblemas(Departamento).
false.
```

`not/1` nunca liga variables y nunca tira error por variables libres. Un test
con el departamento fijo pasa; sólo se ve consultando con la variable libre.
Por eso los tests de inversibilidad usan `set(Departamento == [...])`.

**B. `forall` con negación adentro.**

```prolog
estaEnProblemas(Departamento) :-
  departamento(Departamento),
  forall(trabajaEn(Departamento, Persona), not(leGustaTrabajarEn(Persona, Departamento))).
```

Responde `logistica` y es correcta. Es "para toda persona del departamento, no
le gusta trabajar ahí", que es equivalente a "no existe persona a la que le
guste". Acá la comparación es de lectura, no de correctitud: el enunciado dice
"ninguna", y "ninguna" es `not(existe)`. Además `forall` es `not(not())` por
debajo, así que esta versión tiene una negación más de las que se ven. Ninguna
de las dos es un smell; la solución elige la que se lee como el enunciado.

**C. `findall` + `length(_, 0)`.**

```prolog
estaEnProblemas(Departamento) :-
  departamento(Departamento),
  findall(Persona, (trabajaEn(Departamento, Persona), leGustaTrabajarEn(Persona, Departamento)), Contentas),
  length(Contentas, 0).
```

Responde `logistica`. Junta en una lista a las personas contentas para
preguntar si la lista está vacía. "No hay ninguna" es `not(...)`; armar la
lista es dar la vuelta a la manzana. Mismo smell que en el punto 2.

**D. El `not` inline, sin auxiliar.**

```prolog
estaEnProblemas(Departamento) :-
  departamento(Departamento),
  not((trabajaEn(Departamento, Persona), leGustaTrabajarEn(Persona, Departamento))).
```

Funciona igual. La diferencia con la solución es que "alguien quiere trabajar
ahí" no tiene nombre. El auxiliar `alguienQuiereTrabajarAhi/1` es un concepto
del dominio que se puede consultar solo, testear solo y reusar. Es el comentario
clásico de corrección: "podrías ganar cohesión con un predicado auxiliar". No
baja la nota por sí solo, pero es la diferencia entre código que se lee y
código que se descifra.

### El debate de los departamentos vacíos

Con `departamento/1` modelado por hechos (ver la autocrítica del punto 2),
contabilidad queda en problemas:

```
?- estaEnProblemas(Departamento).      % con departamentos por hechos
Departamento = logistica ;
Departamento = contabilidad.
```

Nadie que trabaje en contabilidad quiere trabajar ahí, porque nadie trabaja en
contabilidad. ¿Está en problemas? Es una pregunta del dominio, no del código, y
es una buena discusión para tener en clase: la respuesta cambia según si el
enunciado se lee como "hay gente y ninguna quiere estar" o como "no hay nadie
que quiera estar". Lo que sí es un error de diseño es no darse cuenta de que el
generador decide la respuesta.

---

## Punto 4: el juego de las sillas

### Lo que hace la solución

```prolog
reorganizacion(Presupuesto, Equipo) :-
  findall(Persona, sueldo(Persona, _), Personas),
  equipoAcotado(Personas, Presupuesto, Equipo).

equipoAcotado([Primero | Resto], Presupuesto, [Primero, Segundo]) :-
  descontarSueldo(Primero, Presupuesto, Queda),
  member(Segundo, Resto),
  descontarSueldo(Segundo, Queda, _).
equipoAcotado([Primero | Resto], Presupuesto, [Primero | Equipo]) :-
  descontarSueldo(Primero, Presupuesto, Queda),
  equipoAcotado(Resto, Queda, Equipo).
equipoAcotado([_ | Resto], Presupuesto, Equipo) :-
  equipoAcotado(Resto, Presupuesto, Equipo).

descontarSueldo(Persona, Presupuesto, Queda) :-
  sueldo(Persona, Sueldo),
  Queda is Presupuesto - Sueldo,
  Queda >= 0.
```

Cuatro cosas para señalar:

1. **La responsabilidad está en la recursión.** `equipoAcotado/3` no genera
   "subconjuntos" para que alguien después decida cuáles sirven: genera
   equipos que entran en el presupuesto. Descontar el sueldo de cada persona
   es parte de armar el equipo, no un chequeo posterior. Por eso el
   presupuesto viaja como argumento y baja en cada paso.
2. **La poda es un predicado con nombre.** `descontarSueldo/3` hace una sola
   cosa: resta el sueldo y falla si no entra. Es el punto exacto donde una
   rama se corta, y tiene nombre para que se lea como una regla del dominio
   ("esta persona ya no entra") y no como aritmética suelta en medio del
   generador.
3. **El generador arranca en dos.** La primera cláusula produce exactamente
   los pares que incluyen a la cabeza; la segunda, los equipos de tres o más
   que la incluyen; la tercera, los que no la incluyen. Son disjuntas, así
   que no hay soluciones repetidas, y nunca se produce un equipo vacío ni
   unitario. Las dos restricciones del enunciado, "al menos dos" y "sin
   superar el presupuesto", viven en el mismo lugar: la definición del
   generador.
4. **El único `findall` es legítimo.** Se necesita la lista completa de
   personas para recorrerla con la recursión; no se está juntando nada para
   después preguntar con `member` lo que el backtracking ya respondía. No hay
   `findall` de sueldos porque nadie suma nada: el presupuesto restante ya
   es la cuenta.

Todo lo que el generador produce es solución. Con seis personas hay 57
equipos de al menos dos, y `equipoAcotado/3` sólo recorre los que entran:

| Presupuesto | Candidatos generados | Soluciones |
|---|---|---|
| 60 | 0 | 0 |
| 100 | 4 | 4 |
| 150 | 18 | 18 |
| 400 | 57 | 57 |

### Alternativas peores

**A. Generar todo y después descartar.** La versión anterior de esta misma
solución, que vale la pena mirar porque pasa todos los tests y aun así está
peleada con el diseño.

```prolog
reorganizacion(Presupuesto, Equipo) :-
  findall(Persona, sueldo(Persona, _), Personas),
  subconjuntoDeAlMenosDos(Personas, Equipo),
  costoDelEquipo(Equipo, Costo),
  Costo =< Presupuesto.

costoDelEquipo(Equipo, Costo) :-
  findall(Sueldo, (member(Persona, Equipo), sueldo(Persona, Sueldo)), Sueldos),
  sum_list(Sueldos, Costo).

subconjuntoDeAlMenosDos([Primero | Resto], [Primero, Segundo]) :-
  member(Segundo, Resto).
subconjuntoDeAlMenosDos([Primero | Resto], [Primero | Subconjunto]) :-
  subconjuntoDeAlMenosDos(Resto, Subconjunto).
subconjuntoDeAlMenosDos([_ | Resto], Subconjunto) :-
  subconjuntoDeAlMenosDos(Resto, Subconjunto).
```

Da los mismos 18 equipos con 150. El problema es dónde está puesta cada
responsabilidad. El generador ya recorrió a cada persona del equipo una por
una y en ese momento tenía el sueldo a mano; sin embargo entrega el equipo
armado y recién entonces `costoDelEquipo/2` vuelve a recorrerlo con un
`findall` para juntar los sueldos, sumarlos y comparar. Es **`findall` para
calcular lo que la recursión ya sabía**. Y es incoherente consigo misma: la
restricción "al menos dos" sí está adentro del generador, pero la del
presupuesto quedó afuera como filtro, sin ninguna razón para tratarlas
distinto. La consecuencia medible es que genera los 57 equipos para
quedarse con 18, y con presupuesto 60 genera los 57 para quedarse con
ninguno. **Generate-and-test con basura**, aunque la basura dependa del
presupuesto y no sea fija.

**B. Subconjunto genérico más filtro de longitud.** Un paso más atrás que A.

```prolog
subconjunto([], []).
subconjunto([Primero | Resto], [Primero | Subconjunto]) :- subconjunto(Resto, Subconjunto).
subconjunto([_ | Resto], Subconjunto) :- subconjunto(Resto, Subconjunto).

reorganizacion(Presupuesto, Equipo) :-
  findall(Persona, sueldo(Persona, _), Personas),
  subconjunto(Personas, Equipo),
  length(Equipo, Cantidad), Cantidad >= 2,
  costoDelEquipo(Equipo, Costo),
  Costo =< Presupuesto.
```

Genera 64 candidatos, de los cuales 7 (el vacío y los seis unitarios) se
descartan *siempre*, sin importar el presupuesto. Las dos restricciones del
enunciado quedaron afuera del generador. Es el mismo smell que A, llevado
hasta el final.

**C. Podar el presupuesto, pero dejar "al menos dos" afuera.** La versión
que aparece cuando se entiende la poda pero no se la combina con el mínimo.

```prolog
equipoAcotado([], _, []).
equipoAcotado([Persona | Resto], Presupuesto, [Persona | Equipo]) :-
  descontarSueldo(Persona, Presupuesto, Queda),
  equipoAcotado(Resto, Queda, Equipo).
equipoAcotado([_ | Resto], Presupuesto, Equipo) :-
  equipoAcotado(Resto, Presupuesto, Equipo).

reorganizacion(Presupuesto, Equipo) :-
  findall(Persona, sueldo(Persona, _), Personas),
  equipoAcotado(Personas, Presupuesto, Equipo),
  length(Equipo, Cantidad), Cantidad >= 2.
```

Con 150 genera 25 candidatos y se queda con los 18: el vacío y los seis
unitarios vuelven a aparecer y a descartarse por `length`. Es mejor que A,
pero muestra que el caso base `[]` es el que produce la basura. Reemplazarlo
por la cláusula que arranca en dos personas, como hace la solución, elimina
el filtro y deja las dos restricciones en el generador.

**D. Acumular el costo en la recursión en vez de descontar el presupuesto.**
Parece lo mismo pero no lo es.

```prolog
equipoConCosto([Primero | Resto], [Primero, Segundo], Costo) :-
  member(Segundo, Resto),
  sueldo(Primero, SueldoPrimero),
  sueldo(Segundo, SueldoSegundo),
  Costo is SueldoPrimero + SueldoSegundo.
equipoConCosto([Primero | Resto], [Primero | Equipo], Costo) :-
  equipoConCosto(Resto, Equipo, CostoResto),
  sueldo(Primero, Sueldo),
  Costo is CostoResto + Sueldo.
equipoConCosto([_ | Resto], Equipo, Costo) :-
  equipoConCosto(Resto, Equipo, Costo).

reorganizacion(Presupuesto, Equipo) :-
  findall(Persona, sueldo(Persona, _), Personas),
  equipoConCosto(Personas, Equipo, Costo),
  Costo =< Presupuesto.
```

Mismas 18 soluciones, pero genera los 57 candidatos igual que A. El costo se
arma *subiendo*, al volver de la recursión, y en ese momento ya es tarde para
cortar la rama: el equipo ya está armado. Para podar habría que llevar el
presupuesto como cuarto argumento y comparar en cada paso, con lo que se
termina escribiendo la solución con un argumento de más. El presupuesto
restante se calcula *bajando*, persona por persona, que es el mismo sentido
en que se arma el equipo y se decide si seguir. Por eso lo que viaja en la
recursión es lo que queda, no lo que se gastó.

**E. Permutaciones.** Aparece cuando se busca "todas las combinaciones" en la
biblioteca sin pensar si el orden importa.

```prolog
reorganizacion(Presupuesto, Equipo) :-
  findall(Persona, sueldo(Persona, _), Personas),
  equipoAcotado(Personas, Presupuesto, Subconjunto),
  permutation(Subconjunto, Equipo).
```

Con 150 responde **48** veces para los mismos 18 equipos: `[kyle, trisha]` y
`[trisha, kyle]` son el mismo equipo y aparecen como dos soluciones.
**Generador sin controlar**, y encima con costo factorial.

**F. El `member` doble.** La versión que resuelve el ejemplo del enunciado y
nada más.

```prolog
reorganizacion(Presupuesto, [Una, Otra]) :-
  sueldo(Una, SueldoUna), sueldo(Otra, SueldoOtra), Una \= Otra,
  Presupuesto - SueldoUna - SueldoOtra >= 0.
```

Dos problemas. Sólo genera pares, y el enunciado dice "por lo menos dos". Y cada
par sale dos veces (`[kyle, sherri]` y `[sherri, kyle]`): 30 soluciones para 15
equipos. Para extenderlo a tres personas habría que escribir otra cláusula con
tres `sueldo`, y así. Es el momento en que la recursión deja de ser opcional.

**G. `trabajaEn` como generador de personas.** ¿Quiénes son las personas
candidatas al equipo?

```prolog
  findall(Persona, distinct(Persona, trabajaEn(_, Persona)), Personas),
```

Con esto Gus desaparece (no trabaja en ningún departamento) y con 150 salen 12
equipos en vez de 18. `reorganizacion(150, [kyle, gus])` pasa de verdadero a
`false`. ¿Cuál es correcta? El enunciado dice "rearmar un departamento", no "con
las personas que ya tienen departamento", y el ejemplo del enunciado no incluye
a Gus en ningún equipo, así que las dos son defendibles. Lo que muestra este
caso es otra cosa: **no existe `persona/1`**. La solución usa `sueldo/2` como
generador porque es el predicado que tiene a todos, pero eso es un accidente
de la base: si mañana Rob tiene sueldo, aparece; si tiene puesto pero no
sueldo, no. Es la misma crítica que `departamento/1`: los individuos
principales del dominio merecen un predicado propio. Con `persona(kyle).` etc.,
la pregunta "quién puede entrar al equipo" tiene una respuesta explícita.
[`solucionAlternativa.pl`](./solucionAlternativa.pl) cierra este agujero de
otra forma: junta puesto y sueldo en `trabaja/3`, y ese predicado pasa a ser
el generador explícito de personas.

### El bonus

El enunciado pide como bonus cuánta plata sobra. La solución no lo resuelve,
pero el diseño ya lo tiene: el presupuesto restante es exactamente lo que
`descontarSueldo/3` va calculando en cada paso. Exponerlo es agregar un
argumento a `equipoAcotado/3` y dejar de descartar el `Queda` de la última
persona. Es lo que hace `solucionAlternativa.pl` con `reorganizacion/3` y
`equipoAcotado/4`. Que el bonus salga gratis de la recursión es la mejor
evidencia de que la responsabilidad estaba bien puesta: en la versión A,
en cambio, había que calcular el sobrante afuera, después de volver a sumar.

### Una observación menor

En la primera cláusula de `equipoAcotado/3`, el presupuesto que queda después
de la segunda persona se descarta con `descontarSueldo(Segundo, Queda, _)`.
Es el único lugar donde el resultado del descuento no se usa, porque ahí sólo
interesa saber si la segunda persona entra. Es aceptable, pero si molesta la
variable anónima se puede nombrar la pregunta: `entraEnPresupuesto(Persona,
Presupuesto) :- descontarSueldo(Persona, Presupuesto, _).` Es una cuestión de
gusto; lo que no conviene es repetir la resta y la comparación a mano.

---

## Los tests como evidencia de diseño

La batería de `solucion.pl` no sólo verifica resultados; cada opción de
PlUnit está diciendo algo sobre el diseño.

- **`set(Departamento == [ventas])`** en los tests de inversibilidad es la
  única forma de detectar los errores A del punto 2 y A del punto 3: los dos
  pasan con el departamento fijo y fallan sólo con la variable libre.
- **`fail`** en `ganaBien(sherri)` y en `reorganizacion(150, [kyle])` son
  tests de universo cerrado y de bordes: lo que no debe ser cierto tiene que
  fallar limpio, no dar error.
- **`nondet`** aparece donde quedan puntos de elección abiertos: en
  `esPaganini(ventas)` por el `distinct`, en `ganaBien(joshua)` porque después
  de la cláusula del arquitecto queda pendiente probar la del `Oficio \=
  arquitecto`. No son bugs, pero el `nondet` es una pista de que el predicado
  tiene más de un camino, y vale la pena saber cuál.
- **`equipo_acotado_no_repite_soluciones`** compara la cantidad cruda con la
  cantidad sin repetidos. Es exactamente el test que la alternativa E del
  punto 4 (permutaciones) no pasa, y el que habría que escribir siempre que
  un generador tenga más de una cláusula.
- **`equipo_acotado_corta_la_rama_apenas_se_pasa_del_presupuesto`** prueba el
  generador directo, con una lista chica y presupuesto 100, y verifica que
  sólo salen los equipos que entran. Es el test que distingue la solución de
  las alternativas A y D del punto 4: con generate-and-test el generador solo
  produce los 57 y el filtro está en otro lado, así que no hay forma de
  testear la poda por separado.

---

## Resumen

| Punto | Alternativa | Smell | Qué hace la solución en su lugar |
|---|---|---|---|
| 1 | Hecho ancho con `ninguno`, `0`, `[]` | Tipo como dato, centinelas | Functor por puesto con sólo su dato; universo cerrado |
| 1 | `esAsalariado/1` + `horas/2` | Tipo desacoplado del atributo, if de tipo | El functor es el tipo y contiene el atributo |
| 1 | `asalariado(6, 50)` | Mezcla de conceptos | `sueldo/2` aparte, ortogonal al puesto |
| 1 | `departamento(ventas, [...])` | Lista donde va relación | `trabajaEn/2`, un hecho por par |
| 2 | `forall` sin generador | No inversible, dominio de cuantificación cambiado | `departamento/1` antes del `forall` |
| 2 | `trabajaEn(D, _)` como generador | Generador sin controlar | `distinct` (o hechos `departamento/1`) |
| 2 | Tres cláusulas con `Puesto = asalariado(H)` | If de tipo, duplicidad | Functor en la cabeza de `ganaBienSegunPuesto/2` |
| 2 | `not((..., not(...)))` | Doble negación evitable | `forall` |
| 2 | Contar y comparar longitudes | `findall` + `length` | `forall` |
| 2 | `asalariado(6)` → `> 45` | Hardcodeo de regla de negocio | `sueldoPromedio/2` como hecho |
| 2 | Independiente sin guarda o con `;` | Cláusulas no disjuntas, soluciones repetidas | `Oficio \= arquitecto` |
| 3 | `not` antes del generador | `not` con variable libre, pierde soluciones | Generador primero |
| 3 | `findall` + `length(_, 0)` | `findall` + `length` | `not` de un existencial |
| 3 | `not` inline | Falta de cohesión | Auxiliar `alguienQuiereTrabajarAhi/1` |
| 4 | `subconjuntoDeAlMenosDos` + `costoDelEquipo` con `findall` + `sum_list` | Generate-and-test con basura, `findall` para calcular lo que la recursión ya sabía | Descontar el presupuesto en la recursión |
| 4 | Subconjunto genérico + `length >= 2` | Las dos restricciones afuera del generador | Generador que arranca en dos y poda |
| 4 | Poda con caso base `[]` + `length >= 2` | Basura fija (vacío y unitarios) | Cláusula base de dos personas |
| 4 | Acumular el costo subiendo | No se puede podar, argumento de más | Presupuesto restante bajando |
| 4 | `permutation` | Generador sin controlar, factorial | Subconjuntos, no permutaciones |
| 4 | `member` doble | No generaliza, repetidos | Recursión |

Y las dos cosas de la propia solución que conviene discutir en vez de defender:
`departamento/1` derivado con `distinct` en lugar de hechos, y la ausencia de
`persona/1` que hace que `sueldo/2` sea el generador de personas por accidente.
Las dos son decisiones válidas si se toman conscientemente; las dos abren el
tema de la verdad vacía, que es probablemente la discusión más rica que este
parcial permite dar.
