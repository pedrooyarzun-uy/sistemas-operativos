#!/bin/bash

usuarios="usuarios.txt"
usuario_logueado=""
esta_corriendo=true

if [ ! -f "$usuarios" ]; then
    echo "admin:admin" > "$usuarios"
fi

crear_usuario() {
    echo "-- Crear usuario --"
    read -p "Ingrese nombre de usuario: " nuevo_usuario
    if [ -z "$nuevo_usuario" ]; then
        echo "El nombre de usuario no puede estar vacío."
        return
    fi
    if [[ "$nuevo_usuario" == *:* ]]; then
        echo "El nombre de usuario no puede contener ':'"
        return
    fi
    if grep -q "^${nuevo_usuario}:" "$usuarios"; then
        echo "El usuario '$nuevo_usuario' ya existe."
        return
    fi
    read -s -p "Ingrese contraseña: " nueva_pass
    echo
    if [ -z "$nueva_pass" ]; then
        echo "La contraseña no puede estar vacía."
        return
    fi
    echo "${nuevo_usuario}:${nueva_pass}" >> "$usuarios"
    echo "Usuario '$nuevo_usuario' creado correctamente."
}

cambiar_contrasena() {
    echo "-- Cambiar contraseña --"
    read -s -p "Ingrese nueva contraseña: " nueva_pass
    echo
    if [ -z "$nueva_pass" ]; then
        echo "La contraseña no puede estar vacía."
        return
    fi
    sed -i "s/^${usuario_logueado}:.*/${usuario_logueado}:${nueva_pass}/" "$usuarios"
    echo "Contraseña actualizada correctamente para '$usuario_logueado'."
}

login() {
    echo "-- Login --"
    read -p "Ingrese nombre de usuario: " usuario
    if ! grep -q "^${usuario}:" "$usuarios"; then
        echo "El usuario '$usuario' no existe."
        return
    fi
    pass_guardada=$(grep "^${usuario}:" "$usuarios" | cut -d':' -f2)
    read -s -p "Ingrese contraseña: " pass_ingresada
    echo
    if [ "$pass_guardada" = "$pass_ingresada" ]; then
        usuario_logueado="$usuario"
        echo "Bienvenido, $usuario_logueado."
    else
        echo "Contraseña incorrecta."
    fi
}

logout() {
    usuario="$usuario_logueado"
    usuario_logueado=""
    echo "Sesión cerrada de '$usuario'."
}

mostrarMenu() {
    echo "====================================="
    echo "   SISTEMA DE CONTROL DE INVENTARIO"
    echo "   Usuario: $usuario_logueado"
    echo "====================================="
    echo "1) Crear usuario"
    echo "2) Cambiar contraseña"
    echo "3) Logout"
    echo "4) Ingresar producto"
    echo "5) Vender producto"
    echo "6) Filtrar productos"
    echo "7) Crear reporte de pinturas"
    echo "8) Salir"
    echo "====================================="
}

while $esta_corriendo; do
    while [ -z "$usuario_logueado" ]; do
        login
    done

    while $esta_corriendo; do
        mostrarMenu
        read -p "Seleccione una opción: " opcion

        case "$opcion" in
            1) crear_usuario ;;
            2) cambiar_contrasena ;;
            3) logout 
                break
                ;;
            8) echo "Saliendo..."; esta_corriendo=false ;;
            *) echo "Opción no válida." ;;
        esac
        echo ""
    done
done
