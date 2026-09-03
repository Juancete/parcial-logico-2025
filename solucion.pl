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

% reorganizacion(+Presupuesto, -Equipo)
% Equipo es un subconjunto de al menos 2 personas cuyos sueldos
% no superan el presupuesto.

reorganizacion(Presupuesto, Equipo) :-
  findall(Persona, sueldo(Persona, _), Personas),
  equipoAcotado(Personas, Presupuesto, Equipo).

% equipoAcotado(Candidatos, Presupuesto, Equipo)
% Arma equipos de al menos 2 personas descontando el sueldo de cada
% una del presupuesto a medida que la incorpora. Si en algún paso el
% presupuesto queda negativo la rama se corta, así que nunca genera
% un equipo que después haya que descartar.
% Las tres cláusulas separan los equipos según su construcción:
%   1) equipos de exactamente 2 personas que incluyen a la cabeza
%   2) equipos de 3 o más personas que incluyen a la cabeza
%   3) equipos que no incluyen a la cabeza

equipoAcotado([Primero | Resto], Presupuesto, [Primero, Segundo]) :-
  descontarSueldo(Primero, Presupuesto, Queda),
  member(Segundo, Resto),
  descontarSueldo(Segundo, Queda, _).
  
equipoAcotado([Primero | Resto], Presupuesto, [Primero | Equipo]) :-
  descontarSueldo(Primero, Presupuesto, Queda),
  equipoAcotado(Resto, Queda, Equipo).

equipoAcotado([_ | Resto], Presupuesto, Equipo) :-
  equipoAcotado(Resto, Presupuesto, Equipo).

% descontarSueldo(Persona, Presupuesto, Queda)
% Falla si el sueldo de la persona no entra en el presupuesto.
descontarSueldo(Persona, Presupuesto, Queda) :-
  sueldo(Persona, Sueldo),
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
test(equipo_kyle_trisha_entra_en_150, nondet) :- reorganizacion(150, [kyle, trisha]).
test(equipo_kyle_joshua_entra_en_150, nondet) :- reorganizacion(150, [kyle, joshua]).
test(equipo_kyle_ian_joshua_entra_en_150, nondet) :- reorganizacion(150, [kyle, ian, joshua]).
test(equipo_kyle_ian_entra_en_150, nondet) :- reorganizacion(150, [kyle, ian]).
test(equipo_kyle_sherri_ian_entra_justo_en_150, nondet) :- reorganizacion(150, [kyle, sherri, ian]).
test(no_se_puede_armar_equipo_que_supera_el_presupuesto, fail) :-
  reorganizacion(150, [trisha, sherri]).
test(no_se_puede_armar_equipo_de_una_sola_persona, fail) :-
  reorganizacion(150, [kyle]).
test(equipo_acotado_genera_solo_equipos_de_2_o_mas_personas,
     set(Equipo == [[kyle, sherri], [kyle, sherri, gus], [kyle, gus], [sherri, gus]])) :-
  equipoAcotado([kyle, sherri, gus], 1000, Equipo).
test(equipo_acotado_no_genera_nada_con_menos_de_2_personas, fail) :-
  equipoAcotado([kyle], 1000, _).
test(equipo_acotado_corta_la_rama_apenas_se_pasa_del_presupuesto,
     set(Equipo == [[kyle, ian], [sherri, ian]])) :-
  equipoAcotado([kyle, sherri, ian, trisha], 100, Equipo).
test(con_presupuesto_100_las_opciones_son_las_esperadas,
     set(Equipo == [[kyle, ian], [sherri, ian], [gus, ian], [ian, joshua]])) :-
  reorganizacion(100, Equipo).

:- end_tests(sueldos).
