#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>

#define CANT_PASAJEROS 100
#define CANT_OFICINISTAS 5
#define LECTURAS_POR_PASAJERO 4
#define CAMBIOS_POR_OFICINISTA 3

/* Variables globales para el control de lectores-escritores */
int lectores_actuales = 0;
int escritor_activo = 0;
int escritores_esperando = 0;

pthread_mutex_t mutex_control;
pthread_cond_t cond_sin_escritor;

/* Estructura para pasar el identificador numérico a cada hilo */
typedef struct {
    int id;
} hilo_info_t;

/* Simula una espera aleatoria en segundos dentro de un rango cerrado */
static void esperar_aleatorio(int maximo) {
    if (maximo <= 0) {
        return;
    }
    int segundos = rand() % (maximo + 1);
    sleep(segundos);
}

/* Protocolo de entrada para lectores con prioridad a escritores */
static void inicio_lectura(void) {
    pthread_mutex_lock(&mutex_control);
    while (escritor_activo || escritores_esperando > 0) {
        pthread_cond_wait(&cond_sin_escritor, &mutex_control);
    }
    lectores_actuales++;
    pthread_mutex_unlock(&mutex_control);
}

/* Finalización de una lectura */
static void fin_lectura(void) {
    pthread_mutex_lock(&mutex_control);
    lectores_actuales--;
    if (lectores_actuales == 0) {
        pthread_cond_broadcast(&cond_sin_escritor);
    }
    pthread_mutex_unlock(&mutex_control);
}

/* Protocolo de entrada para escritores */
static void inicio_escritura(void) {
    pthread_mutex_lock(&mutex_control);
    escritores_esperando++;
    while (escritor_activo || lectores_actuales > 0) {
        pthread_cond_wait(&cond_sin_escritor, &mutex_control);
    }
    escritores_esperando--;
    escritor_activo = 1;
    pthread_mutex_unlock(&mutex_control);
}

/* Finalización de una escritura */
static void fin_escritura(void) {
    pthread_mutex_lock(&mutex_control);
    escritor_activo = 0;
    pthread_cond_broadcast(&cond_sin_escritor);
    pthread_mutex_unlock(&mutex_control);
}

/* Función ejecutada por cada pasajero */
void *rutina_pasajero(void *arg) {
    hilo_info_t *info = (hilo_info_t *)arg;
    for (int i = 0; i < LECTURAS_POR_PASAJERO; i++) {
        esperar_aleatorio(3);
        inicio_lectura();
        printf("Pasajero %d está mirando el cartel\n", info->id);
        fflush(stdout);
        esperar_aleatorio(3);
        fin_lectura();
    }
    return NULL;
}

/* Función ejecutada por cada oficinista */
void *rutina_oficinista(void *arg) {
    hilo_info_t *info = (hilo_info_t *)arg;
    for (int i = 0; i < CAMBIOS_POR_OFICINISTA; i++) {
        esperar_aleatorio(5);
        inicio_escritura();
        printf("Oficinista %d está modificando el cartel\n", info->id);
        fflush(stdout);
        esperar_aleatorio(5);
        fin_escritura();
    }
    return NULL;
}

int main(void) {
    pthread_t pasajeros[CANT_PASAJEROS];
    pthread_t oficinistas[CANT_OFICINISTAS];
    hilo_info_t info_pasajeros[CANT_PASAJEROS];
    hilo_info_t info_oficinistas[CANT_OFICINISTAS];

    srand(time(NULL));
    pthread_mutex_init(&mutex_control, NULL);
    pthread_cond_init(&cond_sin_escritor, NULL);

    /* Creación de hilos de pasajeros con su número identificatorio */
    for (int i = 0; i < CANT_PASAJEROS; i++) {
        info_pasajeros[i].id = i + 1;
        pthread_create(&pasajeros[i], NULL, rutina_pasajero, &info_pasajeros[i]);
    }

    /* Creación de hilos de oficinistas con su número identificatorio */
    for (int i = 0; i < CANT_OFICINISTAS; i++) {
        info_oficinistas[i].id = i + 1;
        pthread_create(&oficinistas[i], NULL, rutina_oficinista, &info_oficinistas[i]);
    }

    for (int i = 0; i < CANT_PASAJEROS; i++) {
        pthread_join(pasajeros[i], NULL);
    }

    for (int i = 0; i < CANT_OFICINISTAS; i++) {
        pthread_join(oficinistas[i], NULL);
    }

    pthread_mutex_destroy(&mutex_control);
    pthread_cond_destroy(&cond_sin_escritor);

    return 0;
}
