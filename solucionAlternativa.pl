% ============================================================
% Parcial: Sueldos - solución alternativa
%
% Difiere de solucion.pl en dos decisiones:
%
% - Punto 1: el puesto y el sueldo van juntos en trabaja/3 en vez
%   de repartirse en puesto/2 y sueldo/2. Con eso no puede existir
%   una persona con puesto y sin sueldo (ni al revés), y trabaja/3
%   queda como el generador explícito de personas para el punto 4.
% - Punto 4: en vez de generar todos los subconjuntos y filtrar los
%   que se pasan del presupuesto, la recursión va restando el
%   presupuesto y corta la rama apenas queda negativo. Todo lo que
%   se genera es solución.
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

% trabaja(Persona, Puesto, Sueldo).
% El puesto es un functor por tipo:
%   asalariado(Horas)
%   jefe(ListaDeSubordinados)
%   independiente(Oficio)
trabaja(kyle,   asalariado(6),             50).
trabaja(sherri, asalariado(7),             60).
trabaja(gus,    asalariado(8),             60).
trabaja(ian,    jefe([kyle, rob, ginger]), 40).
trabaja(trisha, jefe([ian, gus]),          90).
trabaja(joshua, independiente(arquitecto), 55).

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
  trabaja(Persona, Puesto, Sueldo),
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
  findall(Persona, trabaja(Persona, _, _), Personas),
  equipoAcotado(Personas, Presupuesto, Equipo, Sobrante).


% equipoAcotado(Candidatos, Presupuesto, Equipo, Sobrante)
% Arma equipos de al menos 2 personas restando el presupuesto a
% medida que las incorpora. Si en algún paso el presupuesto queda
% negativo la rama se corta, así que nunca genera un equipo que
% después haya que descartar.
% Las tres cláusulas son disjuntas (no hay soluciones repetidas):
%   1) equipos de exactamente 2 personas que incluyen a la cabeza
%   2) equipos de 3 o más personas que incluyen a la cabeza
%   3) equipos que no incluyen a la cabeza

equipoAcotado([Primero | Resto], Presupuesto, [Primero, Segundo], Sobrante) :-
  presupuestoRestante(Primero, Presupuesto, Queda),
  member(Segundo, Resto),
  presupuestoRestante(Segundo, Queda, Sobrante).
  
equipoAcotado([Primero | Resto], Presupuesto, [Primero | Equipo], Sobrante) :-
  presupuestoRestante(Primero, Presupuesto, Queda),
  equipoAcotado(Resto, Queda, Equipo, Sobrante).
equipoAcotado([_ | Resto], Presupuesto, Equipo, Sobrante) :-
  equipoAcotado(Resto, Presupuesto, Equipo, Sobrante).

% presupuestoRestante(Persona, Presupuesto, Queda)
% Falla si el sueldo de la persona no entra en el presupuesto.
presupuestoRestante(Persona, Presupuesto, Queda) :-
  trabaja(Persona, _, Sueldo),
  Queda is Presupuesto - Sueldo,
  Queda >= 0.

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
test(equipo_acotado_genera_solo_equipos_de_2_o_mas_personas,
     set(Equipo == [[kyle, sherri], [kyle, sherri, gus], [kyle, gus], [sherri, gus]])) :-
  equipoAcotado([kyle, sherri, gus], 1000, Equipo, _).
test(equipo_acotado_no_repite_soluciones) :-
  findall(Equipo, equipoAcotado([kyle, sherri, gus, ian], 1000, Equipo, _), Equipos),
  length(Equipos, 11),
  sort(Equipos, SinRepetidos),
  length(SinRepetidos, 11).
test(equipo_acotado_no_genera_nada_con_menos_de_2_personas, fail) :-
  equipoAcotado([kyle], 1000, _, _).
test(equipo_acotado_corta_la_rama_apenas_se_pasa_del_presupuesto,
     set(Equipo-Sobrante == [[kyle, ian]-10, [sherri, ian]-0])) :-
  equipoAcotado([kyle, sherri, ian, trisha], 100, Equipo, Sobrante).
test(equipo_acotado_solo_genera_soluciones_validas) :-
  findall(Sobrante, equipoAcotado([kyle, sherri, gus, ian, trisha, joshua], 150, _, Sobrante), Sobrantes),
  length(Sobrantes, 18),
  forall(member(Sobrante, Sobrantes), Sobrante >= 0).
test(con_presupuesto_100_las_opciones_son_las_esperadas,
     set(Equipo == [[kyle, ian], [sherri, ian], [gus, ian], [ian, joshua]])) :-
  reorganizacion(100, Equipo, _).

:- end_tests(sueldos).
