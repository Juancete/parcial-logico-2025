# **Sueldos** 

Una amiga nos pidió que modelemos la lógica de las personas que trabajan en su empresa, en base a la siguiente información que nos pasó.

## **Punto 1: Por la plata baila el mono**

Sabemos las personas que trabajan en un departamento. Por ejemplo en Ventas trabajan Kyle, Trisha y Joshua, mientras que Ian y Sherri trabajan en Logística.

También tenemos registrado cuánto gana cada persona:

* si la persona es asalariada, sabemos cuántas horas trabaja  
* si la persona tiene gente a cargo, sabemos quiénes son las personas subordinadas, ordenadas por importancia  
* si la persona es independiente, sabemos cuál es el oficio que tiene

Por ejemplo:

* Kyle es asalariado, trabaja 6 horas y gana 50  
* Sherri es asalariada, trabaja 7 horas y gana 60  
* Gus es asalariado, trabaja 8 horas y gana 60  
* Ian es jefe, tiene a su cargo a Kyle, Rob y Ginger, y gana 40  
* Trisha es jefa, tiene a su cargo a Ian y Gus y gana 90  
* Joshua es independiente, trabaja de arquitecto y gana 55

## **Punto 2: Paganini**

Queremos saber si un departamento es paganini, eso ocurre si todas las personas que trabajan en él ganan bien.

* un asalariado gana bien si gana más que el promedio en base a las horas trabajadas. Por ejemplo: el sueldo promedio de 6 horas es 45, el de 7 horas es 60 y el de 8 80\.  
* un jefe gana bien si gana más de 20 \* la cantidad de personas a cargo  
* y un independiente gana bien si es arquitecto o gana más de 70\.

Ventas es un departamento paganini.  
El predicado debe ser inversible.

## **Punto 3: Houston...**

Sabemos en qué departamento le gusta trabajar a una persona.

* A Kyle le gusta trabajar en Ventas o en Logística.  
* A Trisha y a Joshua le gusta trabajar en Ventas.  
* A Sherri le gusta trabajar en Contabilidad, pero también en Facturación y Cobranzas.

Queremos saber si un departamento está en problemas, esto ocurre si ninguna persona que trabaja en ese departamento quiere trabajar ahí. Logística es un departamento que está en problemas. El predicado debe ser inversible.

## **Punto 4: El juego de las sillas**

Siempre es momento de reorganizaciones, queremos saber qué posiblilidades tenemos de rearmar un departamento en base a un presupuesto dado, donde queremos que por lo menos haya 2 personas. BONUS: que diga cuánta plata nos sobraría de ese presupuesto.

Por ejemplo, si hay que reorganizar con 150 $, podemos armar

* un equipo con Kyle y Trisha, y nos queda 10  
* un equipo con Kyle y Joshua, y nos queda 45  
* un equipo con Kyle, Joshua e Ian, y nos queda 5  
* un equipo con Kyle e Ian, y nos queda 60  
* un equipo con Kyle, Ian y Sherri y no nos queda plata

etc.

