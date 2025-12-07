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

Tras aceptar `Iniciar`, cada tarea decide con probabilidad 0.5 si ordeña antes de vacunarse o al revés. Este intercambio recuerda al problema de los Filósofos Comensales: dos secciones críticas (ordeñe y vacunación) pueden tomarse en distinto orden, pero aquí no hay bloqueo circular porque nunca se poseen ambos recursos a la vez; cada fase se completa y se libera el semáforo antes de avanzar, lo que mantiene el sistema libre de deadlocks a pesar del orden aleatorio.

Correspondencia con problemas conocidos
---------------------------------------
- **Semáforos contados (Dijkstra)**: el `task type Semaforo` es una implementación explícita del mecanismo `P/V`. La forma de uso en `Ordeñar` y `Vacunar` coincide con el patrón clásico de los Filósofos, donde cada proceso debe esperar a que haya cubiertos (recursos) disponibles para continuar.
- **Pasillo de sentido único / Alice & Bob**: `sem_pasillo` impone que solo una vaca transite el corredor al mismo tiempo, análogo al ejemplo académico del “puente de un solo carril” donde Alice y Bob deben coordinarse para no chocar. Aquí cada vaca ejecuta `P` antes de entrar y `V` al salir, garantizando exclusión mutua.
- **Secciones críticas con cupo limitado**: `sem_ordenie` y `sem_vacunacion` restringen la cantidad simultánea de vacas pero *no* imponen un orden FIFO ni el flujo típico de productor-consumidor; simplemente bloquean cuando el cupo está lleno y liberan al ejecutar `V`. Es una aplicación directa de semáforos contados sin cola explícita.
- **Problema de asignación a camiones**: `sem_camiones` se usa como mutex alrededor de `cant_camion1` y `cant_camion2`. Las vacas se suben tomando una decisión aleatoria cuando ambos están por debajo de 50 y, si uno ya alcanzó 50, se cargan automáticamente en el otro.

Componentes específicos
-----------------------
- **Área de ordeñe**: `sem_ordenie.Inicializar (15)` limita el ingreso simultáneo a quince vacas. No se guarda ningún estado adicional; las trazas se imprimen antes y después del `delay`.
- **Vacunación y pasillo**: `sem_vacunacion.Inicializar (5)` garantiza que como máximo cinco vacas estén en las mangas. El pasillo (`capacidad = 1`) reproduce un candado binario independiente para evitar cruces al entrar o salir.
- **Camiones**: `sem_camiones.Inicializar (1)` se usa únicamente como mutex. Las decisiones de asignación se basan en `probabilidad_camion` cuando ambos camiones tienen espacio; si solo queda lugar en uno se direcciona automáticamente.

Ejecución y pruebas
-------------------
La construcción se realiza con `gnatmake main.adb`, lo que genera el ejecutable `main`. Al correrlo, se crearán 100 tareas `vaca` y se observarán impresiones concurrentes de cada etapa.
