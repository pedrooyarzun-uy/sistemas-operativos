Informe Técnico Programa Tambo
==============================

Diseño general
--------------
`tambo.adb` define una única `procedure Tambo`. Dentro del cuerpo se instancian todos los recursos protegidos, el `task type Vaca (Id : Positive)` y un arreglo de 100 accesos a tareas. Cada `Vaca` recibe un parámetro discreto `Id` que se usa en los mensajes y en el orden de creación. Las tareas se asignan con `new Vaca (I)`; este paso arranca inmediatamente cada thread y no requiere parámetros adicionales porque la lógica está encapsulada en el cuerpo del task.

Generación aleatoria
--------------------
El paquete `Random_Float` se instancia como `Randomes`, un objeto protegido porque el generador `Random_Float.Generator` no es seguro para concurrencia. La función `Aleatorio` expone un valor `Float` uniforme en [0,1). Estas muestras alimentan tres decisiones:
- `Primero_Ordene` compara `Aleatorio` con 0.5 para intercalar el orden ordeñe/vacunación sin coordinar con otras vacas.
- Los `delay Duration (Aleatorio * 3.0)` y `delay Duration (Aleatorio * 2.0)` materializan los tiempos de ordeñe y vacunación respetando los máximos pedidos.

Sala de ordeñe
--------------
`protected Sala_Ordene` modela el semáforo de capacidad 15. El contador `En_Sala` se incrementa al aceptar `Entrar_Ordene` y se decrementa en `Salir_Ordene`. La guarda `when En_Sala < 15` bloquea solicitudes excedentes. Ambos entry reciben el parámetro `Id` únicamente para imprimir las trazas; funcionalmente no se usa para la sincronización.

Área de vacunación
------------------
`protected Area_Vacunacion` agrupa el estado del pasillo y de las cinco mangas. La entrada `Entrar_Pasillo` expone dos efectos: primero controla el pasillo verificando `Pasillo_Libre`, luego reserva una manga incrementando `Dentro_Mangas`. El parámetro `Token` se devuelve por `out` con el entero `Siguiente_Token`, lo que identifica la posición FIFO de cada vaca dentro de las mangas.  
`Salir_Manga` toma `Token` por valor para garantizar que solamente la vaca con el turno correcto (`Token = Turno_Salida`) libere el pasillo. Este mecanismo evita que una vaca salga si otra está aún delante de ella y, junto con `Pasillo_Libre`, asegura que nunca haya un cruce simultáneo en el corredor.

Camiones
--------
`protected Camiones` administra los dos cupos de 50. El entry `Subir` se habilita mientras `Carga_1 + Carga_2 < 100`, por lo que las tareas se bloquean si los camiones están llenos. El parámetro de salida `Camion` informa cuál vehículo aceptó a la vaca; la lógica de selección simplemente llena el Camión 1 hasta que llegue a 50 y luego continúa con el Camión 2. No es necesario balancear porque los requerimientos solo exigen respetar la capacidad.

Task Vaca
---------
Cada cuerpo de `task Vaca` define dos subprogramas locales:
- `Ir_A_Ordene` llama secuencialmente a `Entrar_Ordene`, espera un delay aleatorio y luego invoca `Salir_Ordene`.
- `Ir_A_Vacunacion` obtiene un `Token` de `Entrar_Pasillo`, espera el delay de vacunación y libera el pasillo/manga mediante `Salir_Manga`.

La decisión `if Primero_Ordene then ...` alterna el orden de invocación de esas operaciones. Finalmente, la vaca llama a `Camiones.Subir`, que bloquea hasta tener espacio en algún camión. No se usa `select` porque los requerimientos no piden cancelaciones ni timeouts; la espera pasiva dentro del entry satisface la sincronización.

Ejecución recomendada
---------------------
Compilar con `gnatmake tambo.adb` genera el ejecutable `tambo`. Al ejecutarlo, se observarán mensajes generados dentro de cada entry, lo que permite seguir el flujo técnico de adquisición y liberación de recursos, así como la asignación final de camiones. No se realizaron pruebas durante la redacción de este informe.
