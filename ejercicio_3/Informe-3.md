Informe Técnico – Programa Main
================================

Contexto general
----------------
`main.adb` encapsula todo dentro de la `procedure Main`. Allí se declara un `task type Semaforo` que ofrece las operaciones clásicas `P` y `V` junto con un `entry Inicializar` para fijar la capacidad en tiempo de ejecución. Este patrón recrea exactamente el semáforo contado de Dijkstra: un `select` permite que varias tareas ejecuten `P` mientras `en_el_recurso < cap_maxima`, y `V` siempre está disponible para liberar el cupo. Instancias concretas (`sem_ordenie`, `sem_vacunacion`, `sem_pasillo`, `sem_camiones`) modelan cada recurso físico del tambo.

Generación y comportamiento de tareas
-------------------------------------
Se define `task type Vaca` con un único `entry Iniciar (Id)`. Dentro del cuerpo, cada vaca guarda su identificador, inicializa un generador pseudoaleatorio propio (semilla `Id`) y declara procedimientos locales:

- `Espera_Aleatoria (Max_Seg)` transforma un `Float` uniforme en un `delay` dentro de `[0, Max_Seg)`.
- `Ordeñar` realiza `P` sobre `sem_ordenie` (capacidad 15) antes de entrar, espera hasta 3 segundos y finalmente invoca `V`.
- `Vacunar` combina `sem_vacunacion` (capacidad 5) con el semáforo binario `sem_pasillo` para modelar el corredor único: primero reserva cupo en la manga, luego alterna `P/V` sobre el pasillo para entrar y salir sin cruces.
- `Subir_Camion` utiliza `sem_camiones` como mutex alrededor de los contadores `cant_camion1` y `cant_camion2`.

Tras aceptar `Iniciar`, cada tarea decide con probabilidad 0.5 si ordeña antes de vacunarse o al revés. Este intercambio recuerda al problema de los Filósofos Comensales: dos secciones críticas (ordeñe y vacunación) pueden tomarse en distinto orden, pero aquí no aparece bloqueo circular porque nunca se mantienen dos recursos “cruzados” esperando uno por el otro. Dentro de cada fase se toman los semáforos siempre en el mismo orden (`sem_vacunacion` antes que `sem_pasillo`) y se liberan al terminar, lo que rompe la condición de espera circular y mantiene el sistema libre de deadlocks a pesar del orden aleatorio entre ordeñe y vacunación.

Correspondencia con problemas conocidos
---------------------------------------
- **Semáforos contados (Dijkstra)**: el `task type Semaforo` es una implementación explícita del mecanismo `P/V`. La forma de uso en `Ordeñar` y `Vacunar` coincide con el patrón clásico en el que cada proceso debe esperar a que haya recursos disponibles para continuar.
- **Pasillo de sentido único / “puente de un solo carril”**: `sem_pasillo` impone que solo una vaca transite el corredor al mismo tiempo, análogo al ejemplo académico donde dos procesos deben coordinarse para no chocar. Cada vaca ejecuta `P` antes de entrar y `V` al salir, garantizando exclusión mutua.
- **Secciones críticas con cupo limitado**: `sem_ordenie` y `sem_vacunacion` restringen la cantidad simultánea de vacas pero *no* imponen un orden FIFO ni el flujo típico de productor-consumidor; simplemente bloquean cuando el cupo está lleno y liberan al ejecutar `V`. Es una aplicación directa de semáforos contados sin cola explícita.
- **Problema de asignación a camiones**: `sem_camiones` se usa como mutex alrededor de `cant_camion1` y `cant_camion2`. Las vacas se suben tomando una decisión aleatoria cuando ambos están por debajo de 50 y, si uno ya alcanzó 50, se cargan automáticamente en el otro.

Componentes específicos
-----------------------
- **Área de ordeñe**: `sem_ordenie.Inicializar (15)` limita el ingreso simultáneo a quince vacas. No se guarda ningún estado adicional; las trazas se imprimen antes y después del `delay`.
- **Vacunación y pasillo**: `sem_vacunacion.Inicializar (5)` garantiza que como máximo cinco vacas estén en las mangas. El pasillo (`capacidad = 1`) reproduce un candado binario independiente para evitar cruces al entrar o salir. En la operación de vacunación siempre se toma primero `sem_vacunacion` y luego `sem_pasillo`, y se liberan en orden inverso, de forma que todas las vacas respetan el mismo orden de adquisición de recursos y se evitan interbloqueos por espera circular.
- **Camiones**: `sem_camiones.Inicializar (1)` se usa únicamente como mutex. Las decisiones de asignación se basan en `probabilidad_camion` cuando ambos camiones tienen espacio; si solo queda lugar en uno se direcciona automáticamente.

Ejecución y pruebas
-------------------
La construcción se realiza con `gnatmake main.adb`, lo que genera el ejecutable `main`. Al correrlo, se crearán 100 tareas `vaca` y se observarán impresiones concurrentes de cada etapa. En todas las ejecuciones se verifica que:

- ninguna sala supera su capacidad (`15` en ordeñe, `5` en vacunación, `1` en el pasillo),
- cada vaca entra y sale tanto del área de ordeñe como del área de vacunación,
- y al finalizar, la suma `cant_camion1 + cant_camion2` es exactamente `100`, con un máximo de `50` vacas en cada camión, tal como exige el enunciado.
