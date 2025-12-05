#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#define PASAJEROS 100
#define OFICINISTAS 5
#define CAMBIOS_POR_OFICINISTA 3

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t puede_leer;
    pthread_cond_t puede_escribir;
    int lectores_activos;
    int escritores_esperando;
    bool escritor_activo;
} bloqueo_cartel_t;

typedef struct {
    int id;
    bloqueo_cartel_t *bloqueo;
} datos_hilo_t;

static void bloqueo_cartel_inicializar(bloqueo_cartel_t *bloqueo) {
    pthread_mutex_init(&bloqueo->mutex, NULL);
    pthread_cond_init(&bloqueo->puede_leer, NULL);
    pthread_cond_init(&bloqueo->puede_escribir, NULL);
    bloqueo->lectores_activos = 0;
    bloqueo->escritores_esperando = 0;
    bloqueo->escritor_activo = false;
}

static void bloqueo_cartel_destruir(bloqueo_cartel_t *bloqueo) {
    pthread_mutex_destroy(&bloqueo->mutex);
    pthread_cond_destroy(&bloqueo->puede_leer);
    pthread_cond_destroy(&bloqueo->puede_escribir);
}

static void comenzar_lectura(bloqueo_cartel_t *bloqueo) {
    pthread_mutex_lock(&bloqueo->mutex);
    while (bloqueo->escritor_activo || bloqueo->escritores_esperando > 0) {
        pthread_cond_wait(&bloqueo->puede_leer, &bloqueo->mutex);
    }
    bloqueo->lectores_activos++;
    pthread_mutex_unlock(&bloqueo->mutex);
}

static void finalizar_lectura(bloqueo_cartel_t *bloqueo) {
    pthread_mutex_lock(&bloqueo->mutex);
    bloqueo->lectores_activos--;
    if (bloqueo->lectores_activos == 0) {
        pthread_cond_signal(&bloqueo->puede_escribir);
    }
    pthread_mutex_unlock(&bloqueo->mutex);
}

static void comenzar_escritura(bloqueo_cartel_t *bloqueo) {
    pthread_mutex_lock(&bloqueo->mutex);
    bloqueo->escritores_esperando++;
    while (bloqueo->escritor_activo || bloqueo->lectores_activos > 0) {
        pthread_cond_wait(&bloqueo->puede_escribir, &bloqueo->mutex);
    }
    bloqueo->escritores_esperando--;
    bloqueo->escritor_activo = true;
    pthread_mutex_unlock(&bloqueo->mutex);
}

static void finalizar_escritura(bloqueo_cartel_t *bloqueo) {
    pthread_mutex_lock(&bloqueo->mutex);
    bloqueo->escritor_activo = false;
    if (bloqueo->escritores_esperando > 0) {
        pthread_cond_signal(&bloqueo->puede_escribir);
    } else {
        pthread_cond_broadcast(&bloqueo->puede_leer);
    }
    pthread_mutex_unlock(&bloqueo->mutex);
}

static int demora_aleatoria(int max_segundos) {
    return (rand() % max_segundos) + 1;
}

static void *rutina_pasajero(void *arg) {
    datos_hilo_t *datos = (datos_hilo_t *)arg;
    comenzar_lectura(datos->bloqueo);
    printf("Pasajero %d esta mirando el cartel\n", datos->id);
    fflush(stdout);
    sleep(demora_aleatoria(3));
    finalizar_lectura(datos->bloqueo);
    return NULL;
}

static void *rutina_oficinista(void *arg) {
    datos_hilo_t *datos = (datos_hilo_t *)arg;
    for (int cambio = 0; cambio < CAMBIOS_POR_OFICINISTA; cambio++) {
        comenzar_escritura(datos->bloqueo);
        printf("Oficinista %d esta modificando el cartel (cambio %d)\n",
               datos->id, cambio + 1);
        fflush(stdout);
        sleep(demora_aleatoria(5));
        finalizar_escritura(datos->bloqueo);
        sleep(demora_aleatoria(5));
    }
    return NULL;
}

int main(void) {
    bloqueo_cartel_t bloqueo;
    bloqueo_cartel_inicializar(&bloqueo);
    srand((unsigned int)time(NULL));

    pthread_t hilos_pasajeros[PASAJEROS];
    pthread_t hilos_oficinistas[OFICINISTAS];
    datos_hilo_t datos_pasajeros[PASAJEROS];
    datos_hilo_t datos_oficinistas[OFICINISTAS];

    for (int i = 0; i < PASAJEROS; i++) {
        datos_pasajeros[i].id = i + 1;
        datos_pasajeros[i].bloqueo = &bloqueo;
        pthread_create(&hilos_pasajeros[i], NULL, rutina_pasajero,
                       &datos_pasajeros[i]);
    }

    for (int i = 0; i < OFICINISTAS; i++) {
        datos_oficinistas[i].id = i + 1;
        datos_oficinistas[i].bloqueo = &bloqueo;
        pthread_create(&hilos_oficinistas[i], NULL, rutina_oficinista,
                       &datos_oficinistas[i]);
    }

    for (int i = 0; i < PASAJEROS; i++) {
        pthread_join(hilos_pasajeros[i], NULL);
    }

    for (int i = 0; i < OFICINISTAS; i++) {
        pthread_join(hilos_oficinistas[i], NULL);
    }

    bloqueo_cartel_destruir(&bloqueo);
    return 0;
}
