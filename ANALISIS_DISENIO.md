# Sueldos: análisis de diseño y smells de modelado

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

- **Tipo como dato / falta de polimorfismo.** Modelar el _"tipo"_ de algo como un
  átomo suelto (`tipo(kyle, asalariado)`) en vez de derivarlo del functor. Obliga
  a preguntar de qué tipo es antes de saber qué hacer: el if de tipo de siempre,
  disfrazado.
- **Ausencia modelada con átomo.** Escribir `subordinados(kyle, [])` o
  `oficio(kyle, ninguno)` para decir "no aplica". En modelos de universo cerrado, lo que no es cierto, no se escribe.
- **Listas donde va una relación.** Meter en una lista lo que son varios hechos
  (`departamento(ventas, [kyle, trisha, joshua])`). Se pierde el backtracking
  gratis y todo termina en `member`.
- **`findall` + `member`, `findall` + `length`.** Armar una lista para después recorrerla o contarla, cuando el motor ya sabe recorrer y "hay al menos uno" o "no hay ninguno" se preguntan directo.
- **Doble negación evitable.** `not((..., not(...)))` cuando hay un `forall` que dice lo mismo en positivo.
- **`not` con variables libres.** Negar antes de que un generador ligue la
  variable. No tira error: pierde soluciones en silencio.
- **`forall` sin generador previo.** Con la variable libre, el `forall` deja de cuantificar "las personas de este departamento" y pasa a cuantificar todos los pares de la base. Cambia el dominio sin que el código lo diga.
- **Verdad vacía.** Un `forall` sobre un conjunto vacío es verdadero. A veces es lo que el dominio quiere y a veces no; hay que decidirlo, no dejar que pase.
- **Hardcodeo de regla de negocio.** Un número del enunciado metido dentro de
  la regla en vez de reificado como hecho.
- **Lógica repetida.** Las mismas líneas copiadas en varias cláusulas en vez
  de delegar el comportamiento común.
- **Inversibilidad rota.** Variables de menos (no liga) o de más (liga pero
  con el dominio equivocado).
- **Menores.** Nombres de una letra, incógnitas innecesarias, predicados que no llama nadie, comentarios informales que no aportan.

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
   `independiente/1` llevan adentro exactamente el dato que el enunciado asocia a cada tipo (horas, subordinados, oficio) y nada más. No existe un campo que "no aplica". El tipo no se guarda: se deriva por pattern matching, y eso es lo que en el punto 2 permite escribir una cláusula por tipo sin preguntar nada.
1. **El sueldo va aparte.** Cuánto gana alguien es ortogonal a qué puesto tiene.
   Si lo metiéramos dentro del functor, en el punto 4 habría que desarmar tres functores distintos para descontar cada sueldo del presupuesto.
2. **Universo cerrado, en serio.** Rob y Ginger aparecen como subordinados de
   Ian pero no tienen sueldo ni puesto: el enunciado no lo dice, así que no se escribe. Gus tiene sueldo y puesto pero no trabaja en ningún departamento, por la misma razón. Ninguno de los dos casos necesita un hecho especial.

Sobre la **lista de subordinados**: normalmente diríamos que "a cargo de"
es una relación, no una lista, y que iría `subordinado(ian, kyle)`. Acá la
lista está justificada porque el enunciado dice que los subordinados están
"ordenados por importancia": el orden es un dato del dominio, y una relación lo pierde. Es una decisión, no un descuido, y vale la pena decirlo en voz alta. Si el enunciado no mencionara el orden, la relación sería mejor: se puede preguntar "¿de quién es subordinado Kyle?" sin `member`, y "cuántos tiene a cargo" se resuelve con `aggregate_all(count, ...)` en vez de `length`.

### Alternativas y discusiones

**A. El hecho ancho.** Todo en un solo predicado, con el tipo como átomo y
centinelas para lo que no aplica.

```prolog
persona(kyle,   ventas,    50, asalariado,    6,  [],           ninguno).
persona(ian,    logistica, 40, jefe,          0,  [kyle, rob, ginger], ninguno).
persona(joshua, ventas,    55, independiente, 0,  [],           arquitecto).
persona(gus,    ninguno,   60, asalariado,    8,  [],           ninguno).
```

Tres smells de una vez: **tipo como dato** (el átomo `asalariado`), **ausencia con valor nulo** (`0`, `[]`, `ninguno`, y peor todavía `ninguno` como departamento de Gus) y hechos de siete argumentos donde nadie recuerda cuál es cuál. Además habilita estados inconsistentes: nada impide un `jefe` con horas distintas de cero o un `asalariado` con subordinados. En la solución eso es imposible por construcción.

**B. El tipo como predicado suelto.** Parece más prolijo pero desacopla el tipo de su atributo.

```prolog
esAsalariado(kyle).     horas(kyle, 6).
esJefe(ian).            subordinados(ian, [kyle, rob, ginger]).
esIndependiente(joshua). oficio(joshua, arquitecto).
```

Puede existir `esAsalariado(gus)` sin `horas(gus, _)`, o `horas(trisha, 4)`
sin que Trisha sea asalariada. Y en el punto 2 la regla de "gana bien" queda
obligada a preguntar `esAsalariado(P)` antes de buscar las horas: el cuco del if de tipo vuelve en forma de fichas.

**C. El sueldo adentro del puesto.**

```prolog
puesto(kyle,   asalariado(6, 50)).
puesto(ian,    jefe([kyle, rob, ginger], 40)).
puesto(joshua, independiente(arquitecto, 55)).
```

Mezcla dos conceptos que el enunciado presenta separados. La consecuencia se ve recién en el punto 4: para descontar el sueldo de cada persona hay que escribir un `sueldoDe/2` con tres cláusulas que desarman cada functor, cuando `sueldo/2` como hecho aparte ya era eso. El modelado del functor es poco cohesivo.

Distinto es juntar puesto y sueldo como argumentos hermanos de un mismo hecho, `trabaja(kyle, asalariado(6), 50)`, que es lo que hace `solucionAlternativa.pl`.
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
trabaja Kyle" necesita `departamento(D, Personas), member(kyle, Personas)`. El punto 3 termina en `findall` + `member` casi seguro. La relación `trabajaEn/2` responde las dos preguntas con el mismo hecho y sin lista.

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

### Alternativas y discusiones

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

**B. Usar `trabajaEn` directamente como generador puede alterar tu TOC.**

```prolog
esPaganini(Departamento) :-
  trabajaEn(Departamento, _),
  forall(trabajaEn(Departamento, Persona), ganaBien(Persona)).
```

Ahora es inversible y ventas aparece una vez por cada empleado:

```
?- esPaganini(Departamento).
Departamento = ventas ;
Departamento = ventas ;
Departamento = ventas.
```

Esto no vuelve incorrecta la consulta: las tres respuestas son tres pruebas de
la misma relación. `departamento/1` usa `distinct/2` para ofrecer una salida
canónica, pero el enunciado no exige una única prueba por departamento. La
diferencia importa si después se hace un `findall` o un conteo sin normalizar. De lo contrario es solo para satisfacer tu TOC que aparezca una sola respuesta.

**C. If de tipo con lógica repetida.** Tres cláusulas de `ganaBien` que repiten la
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
palabra "todas". Obligar al usuario a hacer la doble negación mentalmente es un costo que no compra nada. De hecho lo aleja del lenguaje del requerimiento.

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
correcciones: Esto denota un desconocimiento fuerte de los conceptos del paradigma lógico.

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

**G. El independiente sin la guarda.**

```prolog
ganaBienSegunPuesto(independiente(arquitecto), _).
ganaBienSegunPuesto(independiente(_), Sueldo) :- Sueldo > 70.
```

Un arquitecto que gana más de 70 satisface las dos cláusulas, por lo que la
consulta puede responder `true` dos veces. Para lo que pide el parcial esto es
aceptable: en ambos casos la conclusión es la misma, que gana bien, y no se
realiza ninguna operación posterior que dependa de la cantidad de pruebas.

La guarda `Oficio \= arquitecto` no corrige un error grave, sino que mejora el
modelado: hace explícito que la segunda cláusula describe únicamente a los
independientes que no son arquitectos. Así, ambas cláusulas representan casos
excluyentes: los arquitectos ganan bien por su oficio y los demás independientes
ganan bien sólo si su sueldo supera 70.

**H. `>=` en vez de `>`.** No es un smell, es leer mal. Sherri gana 60 y el
promedio de 7 horas es 60: "gana más que el promedio" es estrictamente más.
Con `>=` Sherri ganaría bien. Logística seguiría sin ser paganini por Ian, así
que el ejemplo del enunciado no lo detecta. Por eso hay un test específico
para Sherri.

### Autocrítica: el `distinct` en `departamento/1`

Las dos soluciones derivan los departamentos de `trabajaEn/2` y usan
`distinct/2` para devolver cada nombre una sola vez. Es una comodidad de la
interfaz, no una condición de correctitud para este enunciado: sin `distinct/2`,
`esPaganini/1` seguiría siendo inversible aunque pudiera demostrar `ventas`
varias veces. Una alternativa de modelado es declarar los departamentos como
individuos de primera clase:

```prolog
departamento(ventas).
departamento(logistica).
departamento(contabilidad).
departamento(facturacion).
departamento(cobranzas).
```

Sin `distinct`, sin regla, y los tres departamentos que aparecen en
`leGustaTrabajarEn/2` pasan a existir. Pero eso tiene una consecuencia que hay que mirar de frente: contabilidad no tiene empleados, y un `forall` sobre un conjunto vacío es verdadero.

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

### Alternativas y discusiones

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

### Dos soluciones válidas

La solución principal integra las dos restricciones en el generador:
descuenta el sueldo mientras arma el equipo y el primer caso que produce ya
tiene dos integrantes.

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
```

`solucionAlternativa.pl` separa la restricción de cantidad. Su
`equipoAcotado/4` es un generador general de subconjuntos que ya poda por
presupuesto; `reorganizacion/3` verifica afuera que haya por lo menos dos
personas y además expone el sobrante pedido por el bonus.

```prolog
reorganizacion(Presupuesto, Equipo, Sobrante) :-
  findall(Persona, trabaja(Persona, _, _), Personas),
  equipoAcotado(Personas, Presupuesto, Equipo, Sobrante),
  length(Equipo, CantidadDePersonas),
  CantidadDePersonas >= 2.

equipoAcotado([], Presupuesto, [], Presupuesto).
equipoAcotado([Persona | Resto], Presupuesto, [Persona | Equipo], Sobrante) :-
  presupuestoRestante(Persona, Presupuesto, Queda),
  equipoAcotado(Resto, Queda, Equipo, Sobrante).
equipoAcotado([_ | Resto], Presupuesto, Equipo, Sobrante) :-
  equipoAcotado(Resto, Presupuesto, Equipo, Sobrante).
```

Las dos decisiones son defendibles:

- La principal especializa la recursión para que `equipoAcotado/3` sólo
  produzca equipos de al menos dos integrantes.
- La alternativa tiene un caso base más general y deja que `length/2` exprese
  directamente la regla "por lo menos dos". El auxiliar también puede producir
  el vacío y los unitarios, pero `reorganizacion/3` no los ofrece como
  respuesta y el enunciado no pide contabilizar candidatos intermedios.

En ambas, la decisión importante para el presupuesto está dentro de la
recursión. `descontarSueldo/3` y `presupuestoRestante/3` restan el sueldo y
fallan cuando una persona ya no entra. Así la rama se corta en ese momento y
no hace falta reconstruir el costo del equipo al final.

El `findall` que obtiene las personas tiene otra responsabilidad: convertir
el generador del dominio en la lista que la recursión necesita recorrer. No se
usa para reemplazar una consulta existencial ni universal.

### Respuestas repetidas y conteos

El enunciado pregunta qué equipos se pueden armar. Si un equipo tuviera más de
una prueba, seguiría siendo una respuesta válida; Prolog no exige que una
relación tenga una única demostración. La multiplicidad recién debe tratarse si
otra regla quiere contar equipos, sumar valores por solución o construir una
colección sin repeticiones. Ninguno de los puntos pide eso.

Las implementaciones actuales recorren la lista de candidatos en un orden
fijo, por lo que naturalmente representan cada subconjunto con ese orden. Es
una propiedad conveniente, no el criterio que determina si la solución es
correcta.

### Otras alternativas

**Generar el equipo y calcular el costo después.** También puede responder
correctamente, pero vuelve a recorrer el equipo para juntar y sumar sueldos.
Llevar el presupuesto restante durante la recursión expresa la restricción en
el momento en que se decide incorporar a cada persona y permite podar antes.

**Acumular el costo al volver de la recursión.** Es correcto, aunque el costo
se conoce recién cuando el equipo ya fue armado. Descontar el presupuesto al
bajar hace que el dato disponible coincida con la decisión "esta persona
entra o no" y, en la alternativa, deja listo el sobrante del bonus.

**Agregar `permutation/2`.** Produce otros órdenes de las mismas personas. No
cambia la verdad de las consultas del parcial y las respuestas repetidas no
son por sí mismas un error. Sin embargo, agrega una exploración factorial que
no aporta información si el orden dentro de un equipo no tiene significado; y
debería normalizarse si alguna extensión futura quisiera contabilizar equipos.

**Elegir dos personas con dos `member`.** Puede resolver los ejemplos de dos
integrantes, incluso si encuentra cada par en más de un orden. El problema real
no es esa multiplicidad, sino que no generaliza: el enunciado permite equipos
de tres o más personas y exigiría agregar una cláusula por cada tamaño. La
recursión resuelve todos los tamaños con la misma definición.

### El generador de personas

Usar `trabajaEn/2` dejaría afuera a Gus porque no figura en ningún
departamento. La solución principal usa `sueldo/2`, que contiene a todas las
personas consideradas para la reorganización. La alternativa junta puesto y
sueldo en `trabaja/3`, que pasa a ser su generador explícito de personas. Esta
es una diferencia de modelado entre ambas soluciones, independiente de la
cantidad de pruebas que produzcan.

### El bonus

El presupuesto restante es exactamente la plata que sobra. La solución
principal lo usa internamente y lo descarta porque resuelve el punto
obligatorio. La alternativa lo conserva como cuarto argumento de
`equipoAcotado/4` y lo devuelve mediante `reorganizacion/3`, sin volver a
recorrer ni sumar el equipo.
