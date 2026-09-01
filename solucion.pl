% ============================================================
% Parcial: Sueldos
% ============================================================

% ------------------------------------------------------------
% Punto 1: Por la plata baila el mono
% ------------------------------------------------------------

% trabajaEn(Departamento, Persona).
trabajaEn(ventas, kyle).
trabajaEn(ventas, trisha).
trabajaEn(ventas, joshua).
trabajaEn(logistica, ian).
trabajaEn(logistica, sherri).

% sueldo(Persona, Sueldo).
sueldo(kyle, 50).
sueldo(sherri, 60).
sueldo(gus, 60).
sueldo(ian, 40).
sueldo(trisha, 90).
sueldo(joshua, 55).

% puesto(Persona, Puesto).
%   asalariado(Horas)
%   jefe(ListaDeSubordinados)          
%   independiente(Oficio)
puesto(kyle, asalariado(6)).
puesto(sherri, asalariado(7)).
puesto(gus, asalariado(8)).
puesto(ian, jefe([kyle, rob, ginger])).
puesto(trisha, jefe([ian, gus])).
puesto(joshua, independiente(arquitecto)).

% sueldoPromedio(Horas, Promedio).
sueldoPromedio(6, 45).
sueldoPromedio(7, 60).
sueldoPromedio(8, 80).

% ------------------------------------------------------------
% Punto 2: Paganini
% ------------------------------------------------------------

departamento(Departamento) :-
  distinct(Departamento, trabajaEn(Departamento, _)).

esPaganini(Departamento) :-
  departamento(Departamento),
  forall(trabajaEn(Departamento, Persona), ganaBien(Persona)).

ganaBien(Persona) :-
  sueldo(Persona, Sueldo),
  puesto(Persona, Puesto),
  ganaBienSegunPuesto(Puesto, Sueldo).

% Polimorfismo para todysssss
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

% ------------------------------------------------------------
% Punto 3: Houston...
% ------------------------------------------------------------

% leGustaTrabajarEn(Persona, Departamento).
leGustaTrabajarEn(kyle, ventas).
leGustaTrabajarEn(kyle, logistica).
leGustaTrabajarEn(trisha, ventas).
leGustaTrabajarEn(joshua, ventas).
leGustaTrabajarEn(sherri, contabilidad).
leGustaTrabajarEn(sherri, facturacion).
leGustaTrabajarEn(sherri, cobranzas).

estaEnProblemas(Departamento) :-
  departamento(Departamento),
  not(alguienQuiereTrabajarAhi(Departamento)).

alguienQuiereTrabajarAhi(Departamento) :-
  trabajaEn(Departamento, Persona),
  leGustaTrabajarEn(Persona, Departamento).

% ------------------------------------------------------------
% Punto 4: El juego de las sillas
% ------------------------------------------------------------

% reorganizacion(+Presupuesto, -Equipo, -Sobrante)
% Equipo es un subconjunto de al menos 2 personas cuyos sueldos
% no superan el presupuesto. Sobrante es lo que queda (BONUS).

reorganizacion(Presupuesto, Equipo, Sobrante) :-
  findall(Persona, sueldo(Persona, _), Personas),
  subconjuntoDeAlMenosDos(Personas, Equipo),
  costoDelEquipo(Equipo, Costo),
  Sobrante is Presupuesto - Costo,
  Sobrante >= 0.

% Versión sin el bonus, por si sólo interesa el equipo.
reorganizacion(Presupuesto, Equipo) :-
  reorganizacion(Presupuesto, Equipo, _).

costoDelEquipo(Equipo, Costo) :-
  findall(Sueldo, (member(Persona, Equipo), sueldo(Persona, Sueldo)), Sueldos),
  sum_list(Sueldos, Costo).

% subconjuntoDeAlMenosDos(Lista, Subconjunto)
% Las tres cláusulas son disjuntas (no hay soluciones repetidas):
%   1) subconjuntos de exactamente 2 elementos que incluyen a la cabeza
%   2) subconjuntos de 3 o más elementos que incluyen a la cabeza
%   3) subconjuntos que no incluyen a la cabeza

subconjuntoDeAlMenosDos([Primero | Resto], [Primero, Segundo]) :-
  member(Segundo, Resto).
subconjuntoDeAlMenosDos([Primero | Resto], [Primero | Subconjunto]) :-
  subconjuntoDeAlMenosDos(Resto, Subconjunto).
subconjuntoDeAlMenosDos([_ | Resto], Subconjunto) :-
  subconjuntoDeAlMenosDos(Resto, Subconjunto).

% ============================================================
% Tests
% ============================================================

:- begin_tests(sueldos).

% --- Punto 2 ---
test(kyle_asalariado_gana_bien) :- ganaBien(kyle).
test(sherri_asalariada_no_gana_bien_porque_iguala_el_promedio, fail) :- ganaBien(sherri).
test(gus_asalariado_no_gana_bien, fail) :- ganaBien(gus).
test(ian_jefe_no_gana_bien, fail) :- ganaBien(ian).
test(trisha_jefa_gana_bien) :- ganaBien(trisha).
test(joshua_independiente_arquitecto_gana_bien, nondet) :- ganaBien(joshua).
test(independiente_no_arquitecto_gana_bien_si_gana_mas_de_70) :-
  ganaBienSegunPuesto(independiente(plomero), 71).
test(independiente_no_arquitecto_no_gana_bien_si_gana_70_o_menos, fail) :-
  ganaBienSegunPuesto(independiente(plomero), 70).
test(ventas_es_paganini, nondet) :- esPaganini(ventas).
test(logistica_no_es_paganini, fail) :- esPaganini(logistica).
test(paganini_es_inversible, set(Departamento == [ventas])) :-
  esPaganini(Departamento).

% --- Punto 3 ---
test(logistica_esta_en_problemas, nondet) :- estaEnProblemas(logistica).
test(ventas_no_esta_en_problemas, fail) :- estaEnProblemas(ventas).
test(esta_en_problemas_es_inversible, set(Departamento == [logistica])) :-
  estaEnProblemas(Departamento).

% --- Punto 4 ---
test(equipo_kyle_trisha_sobran_10, nondet) :- reorganizacion(150, [kyle, trisha], 10).
test(equipo_kyle_joshua_sobran_45, nondet) :- reorganizacion(150, [kyle, joshua], 45).
test(equipo_kyle_ian_joshua_sobran_5, nondet) :- reorganizacion(150, [kyle, ian, joshua], 5).
test(equipo_kyle_ian_sobran_60, nondet) :- reorganizacion(150, [kyle, ian], 60).
test(equipo_kyle_sherri_ian_no_sobra_nada, nondet) :- reorganizacion(150, [kyle, sherri, ian], 0).
test(no_se_puede_armar_equipo_que_supera_el_presupuesto, fail) :-
  reorganizacion(150, [trisha, sherri], _).
test(no_se_puede_armar_equipo_de_una_sola_persona, fail) :-
  reorganizacion(150, [kyle], _).
test(subconjunto_de_al_menos_dos_genera_solo_los_de_2_o_mas_elementos,
     set(Subconjunto == [[a, b], [a, b, c], [a, c], [b, c]])) :-
  subconjuntoDeAlMenosDos([a, b, c], Subconjunto).
test(subconjunto_de_al_menos_dos_no_repite_soluciones) :-
  findall(Subconjunto, subconjuntoDeAlMenosDos([a, b, c, d], Subconjunto), Subconjuntos),
  length(Subconjuntos, 11),
  sort(Subconjuntos, SinRepetidos),
  length(SinRepetidos, 11).
test(subconjunto_de_al_menos_dos_no_genera_nada_con_menos_de_2_elementos, fail) :-
  subconjuntoDeAlMenosDos([a], _).
test(con_presupuesto_100_las_opciones_son_las_esperadas,
     set(Equipo == [[kyle, ian], [sherri, ian], [gus, ian], [ian, joshua]])) :-
  reorganizacion(100, Equipo, _).

:- end_tests(sueldos).
